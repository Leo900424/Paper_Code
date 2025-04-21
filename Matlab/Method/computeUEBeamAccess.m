function UE_beam_access_sorted = computeUEBeamAccess(root, sc, Iridium_OMNet, ueName, beamCount)

    disp("🔍 分析 UE 的 Access");

    UE_beam_access = table();

    ueObj = root.GetObjectFromPath("/Facility/" + ueName);

    for satIdx = 1:1 % length(Iridium_OMNet)
        satName = Iridium_OMNet(satIdx);
        satObj = root.GetObjectFromPath("/Satellite/" + satName);

        for beamIdx = 1:beamCount
            beamName = "Sensor" + num2str(beamIdx);
            try
                sensor = satObj.Children.Item(beamName);

                % 建立與 UE 的 Access 
                access = sensor.GetAccessToObject(ueObj);
                access.ComputeAccess;

                % 擷取 Access 資訊
                dp = access.DataProviders.Item('Access Data').Exec(sc.StartTime, sc.StopTime);
                if dp.DataSets.Count > 0
                    starts = string(dp.DataSets.GetDataSetByName('Start Time').GetValues);
                    stops  = string(dp.DataSets.GetDataSetByName('Stop Time').GetValues);

                    for j = 1:length(starts)
                        UE_beam_access = [UE_beam_access; 
                            table(string(satName), string(beamName), string(ueName), starts(j), stops(j), ...
                            'VariableNames', {'Satellite', 'Beam', 'UE', 'StartTime', 'StopTime'})];
                    end
                end
            catch ME
                warning("⚠️ 讀取 %s 的 %s 時發生錯誤：%s", satName, beamName, ME.message);
            end
        end
    end

    disp("✅ 所有衛星的 UE Access 分析完成");

    % 轉換時間格式並排序
    UE_beam_access.StartTime = datetime(UE_beam_access.StartTime, 'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS', 'Locale', 'en_US');
    UE_beam_access.StopTime  = datetime(UE_beam_access.StopTime,  'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS', 'Locale', 'en_US');
    UE_beam_access_sorted = sortrows(UE_beam_access, 'StartTime');
end
