function switch_count = countFLSwitchInterruptions(UE_time_table)
    % 假設你的表格叫 UE_connection_table，欄位為：
    % Time, UE, Satellite, Beam, Gateway

    switch_count = 0;

    for i = 2:height(UE_time_table)
        sameUE   = UE_time_table.UE(i) == UE_time_table.UE(i-1);
        sameBeam = UE_time_table.Beam(i) == UE_time_table.Beam(i-1);
        diffGW   = UE_time_table.Gateway(i) ~= UE_time_table.Gateway(i-1);

        if sameUE && sameBeam && diffGW
            switch_count = switch_count + 1;
        end
    end
end