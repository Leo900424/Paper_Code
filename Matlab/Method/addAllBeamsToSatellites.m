function addAllBeamsToSatellites(root, Iridium_OMNet, beam_config)
    % 為每顆衛星建立 48 個 beam 並設定透明度與指向方式
    
        disp("建立 48 個 Sensor");
    
        beam_count = 48;
        cone_half_angle = 14; % 錐角角度（度）
    
        % 設定 4 group 對應透明度
        beam_alpha = zeros(48, 1);
        beam_alpha(1:3) = 0;        % Group 1：最不透明（紅）
        beam_alpha(4:12) = 30;      % Group 2：微透明（綠）
        beam_alpha(13:27) = 60;     % Group 3：半透明（藍）
        beam_alpha(28:48) = 90;     % Group 4：幾乎透明（橘）
    
        for i = 1:length(Iridium_OMNet)
            sat_name = Iridium_OMNet(i);
            sat = root.GetObjectFromPath("/Satellite/" + sat_name);
            
            for j = 1:beam_count
                beam_name = "Sensor" + num2str(j);
                sensor = sat.Children.New('eSensor', beam_name);
    
                % 設定 Pattern 為 Simple Conic
                sensor.SetPatternType('eSnSimpleConic');
                sensor.CommonTasks.SetPatternSimpleConic(double(cone_half_angle), double(1));
    
                % 指向設定：固定 Az/El 方位角
                sensor.SetPointingType('eSnPtFixed');
                sensor.CommonTasks.SetPointingFixedAzEl(beam_config(j, 2), beam_config(j, 1), 'eAzElAboutBoresightRotate')
    
                % 開啟填充區域顯示
                sensor.Graphics.FillVisible = true;
    
                % 使用 STK Connect 指令設定透明度
                cmd = sprintf('Graphics */Satellite/%s/Sensor/%s FillTranslucency %d', ...
                              sat_name, beam_name, beam_alpha(j));
                root.ExecuteCommand(cmd);
    
                disp(sat_name + ' ' + beam_name + ' complete');
            end
        end
    
        disp("✨ Sensor 建立完成");
    end
    