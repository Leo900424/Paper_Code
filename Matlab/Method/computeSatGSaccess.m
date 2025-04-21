function [overlapTable, overlapStart] = computeSatGSaccess(root, sc, Iridium_OMNet)
    % 分析每顆衛星與 GGS_Svalbard 和 GGS_Izhevsk 的 access 與交集時間段
    % 輸出：包含每顆衛星的重疊時間表格（可擴充成 struct list）
    
        ggs1 = root.GetObjectFromPath("/Facility/GS_Svalbard");
        ggs2 = root.GetObjectFromPath("/Facility/GS_Izhevsk");
    
        overlapTable = table();
    
        for i = 1:1 % 可改為 length(Iridium_OMNet)
            satName = Iridium_OMNet(i);
            satObj = root.GetObjectFromPath("/Satellite/" + satName);
    
            % Access to GGS_Svalbard
            access1 = satObj.GetAccessToObject(ggs1); access1.ComputeAccess;
            dp1 = access1.DataProviders.Item('Access Data').Exec(sc.StartTime, sc.StopTime);
            dtStart1 = datetime(string(dp1.DataSets.GetDataSetByName('Start Time').GetValues), 'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS', 'Locale', 'en_US');
            dtStop1  = datetime(string(dp1.DataSets.GetDataSetByName('Stop Time').GetValues),  'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS', 'Locale', 'en_US');
    
            % Access to GGS_Izhevsk
            access2 = satObj.GetAccessToObject(ggs2); access2.ComputeAccess;
            dp2 = access2.DataProviders.Item('Access Data').Exec(sc.StartTime, sc.StopTime);
            dtStart2 = datetime(string(dp2.DataSets.GetDataSetByName('Start Time').GetValues), 'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS', 'Locale', 'en_US');
            dtStop2  = datetime(string(dp2.DataSets.GetDataSetByName('Stop Time').GetValues),  'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS', 'Locale', 'en_US');
    
            % 找出交集
            overlapStart = [];
            overlapEnd   = [];
    
            for m = 1:length(dtStart1)
                for n = 1:length(dtStart2)
                    s = max(dtStart1(m), dtStart2(n));
                    e = min(dtStop1(m), dtStop2(n));
                    if s < e
                        overlapStart = [overlapStart; s];
                        overlapEnd   = [overlapEnd; e];
                    end
                end
            end
    
            if ~isempty(overlapStart)
                satCol = repmat(satName, length(overlapStart), 1);
                tempTable = table(satCol, overlapStart, overlapEnd, ...
                                'VariableNames', {'Satellite', 'Start', 'Stop'});
                overlapTable = [overlapTable; tempTable];
            end
        end
    
        disp("✅ Access + 重疊時間 分析完成");
    end
    