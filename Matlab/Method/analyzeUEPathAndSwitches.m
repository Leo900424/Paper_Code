function [switch_count, beam_path, switch_beams, ...
          beam_count, norm_flsi, consec_flsi_count, ...
          transition_count, consec_flsi_ratio] = analyzeUEPathAndSwitches(UE_time_table)

    switch_count = 0;
    beam_path = string([]);
    switch_beams = string([]);

    prev_beam = "";
    prev_gateway = "";

    transition_count = 0;
    consec_flsi_count = 0;

    beam_flsi_map = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    last_beam_flsi = false;

    for i = 1:height(UE_time_table)
        current_beam = UE_time_table.Beam(i);
        current_gateway = UE_time_table.Gateway(i);

        % 建 beam_path
        if isempty(beam_path) || current_beam ~= beam_path(end)
            beam_path = [beam_path; current_beam];
        end

        % 是否 FLSI
        is_flsi = false;
        if i > 1 && current_beam == prev_beam && current_gateway ~= prev_gateway
            is_flsi = true;
            switch_count = switch_count + 1;
            beam_flsi_map(char(current_beam)) = true;

            if ~any(switch_beams == current_beam)
                switch_beams = [switch_beams; current_beam];
            end
        end

        % transition 計數
        if i > 1 && current_beam ~= prev_beam
            transition_count = transition_count + 1;

            % 結束迴圈後再計算 consec_flsi_count
            consec_flsi_count = 0;
            for i = 2:length(beam_path)
                if any(switch_beams == beam_path(i - 1)) && any(switch_beams == beam_path(i))
                    consec_flsi_count = consec_flsi_count + 1;
                end
            end
        end

        % 更新
        prev_beam = current_beam;
        prev_gateway = current_gateway;
    end

    valid_beams = beam_path(beam_path ~= "None");
    beam_count = length(unique(valid_beams));
    norm_flsi = switch_count / beam_count;

    if switch_count > 0
        consec_flsi_ratio = consec_flsi_count / beam_count;
    else
        consec_flsi_ratio = 0;
    end
end
