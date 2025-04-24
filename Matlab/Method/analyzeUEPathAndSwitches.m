function [switch_count, beam_path, switch_beams] = analyzeUEPathAndSwitches(UE_time_table)
    % 初始化
    switch_count = 0;
    beam_path = string([]);
    switch_beams = string([]);

    prev_beam = "";
    prev_gateway = "";

    for i = 1:height(UE_time_table)
        current_beam = UE_time_table.Beam(i);
        current_gateway = UE_time_table.Gateway(i);

        % 只記錄 beam 路徑中第一次出現的 beam
        if isempty(beam_path) || current_beam ~= beam_path(end)
            beam_path = [beam_path; current_beam];
        end

        % 檢查是否為 FL switch interruption
        if i > 1 && current_beam == prev_beam && current_gateway ~= prev_gateway
            switch_count = switch_count + 1;

            % 紀錄這個 beam 是發生過 FL switch 的
            if ~any(switch_beams == current_beam)
                switch_beams = [switch_beams; current_beam];
            end
        end

        prev_beam = current_beam;
        prev_gateway = current_gateway;
    end
end
