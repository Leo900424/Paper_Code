function clearOldSensors(root, Iridium_OMNet, beamCount)
    % clearOldSensors 清除所有衛星上的舊有 Sensor
    % 
    % 輸入：
    % - root: STK 連線物件
    % - Iridium_OMNet: 衛星名稱列表
    % - beamCount: 每顆衛星有多少個 Sensor (通常是48)

    disp("🧹 清除舊的 Sensor");

    for i = 1:length(Iridium_OMNet)
        sat = root.GetObjectFromPath("/Satellite/" + Iridium_OMNet(i));
        for beamIdx = 1:beamCount
            beamName = "Sensor" + num2str(beamIdx);
            try
                sensor = sat.Children.Item(beamName);
                sensor.Unload();
                disp(Iridium_OMNet(i) + " " + beamName + " is unloaded.");
            catch ME
                warning("⚠️ %s %s 無法清除：%s", Iridium_OMNet(i), beamName, ME.message);
            end
        end
    end

    disp("✅ 清除完成");
end
