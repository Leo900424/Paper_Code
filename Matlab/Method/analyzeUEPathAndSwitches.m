function [switch_count, beam_path, switch_beams, ...
          beam_count, norm_flsi, consec_flsi_count, ...
          transition_count, consec_flsi_ratio] = analyzeUEPathAndSwitches(UE_time_table)

    % 初始化
    switch_count = 0;
    beam_path = string([]);
    switch_beams = string([]);

    prev_beam = "";
    prev_gateway = "";

    consec_flsi_count = 0;
    transition_count = 0;
    last_was_flsi = false;

    for i = 1:height(UE_time_table)
        current_beam = UE_time_table.Beam(i);
        current_gateway = UE_time_table.Gateway(i);

        % 建 beam_path
        if isempty(beam_path) || current_beam ~= beam_path(end)
            beam_path = [beam_path; current_beam];
        end

        % 檢查是否發生 FL switch（同一 beam，gateway 改變）
        is_flsi = false;
        if i > 1 && current_beam == prev_beam && current_gateway ~= prev_gateway
            is_flsi = true;
            switch_count = switch_count + 1;

            if ~any(switch_beams == current_beam)
                switch_beams = [switch_beams; current_beam];
            end
        end

        % 檢查是否為 consecutive FLSI
        if is_flsi && last_was_flsi
            consec_flsi_count = consec_flsi_count + 1;
        end

        % transition 計數（beam 切換）
        if i > 1 && current_beam ~= prev_beam
            transition_count = transition_count + 1;
        end

        % 更新狀態
        last_was_flsi = is_flsi;
        prev_beam = current_beam;
        prev_gateway = current_gateway;
    end

    valid_beams = beam_path(beam_path ~= "None");
    beam_count = length(unique(valid_beams));
    norm_flsi = switch_count / beam_count;

    if switch_count > 0
        consec_flsi_ratio = consec_flsi_count / switch_count;
    else
        consec_flsi_ratio = 0;
    end
end
