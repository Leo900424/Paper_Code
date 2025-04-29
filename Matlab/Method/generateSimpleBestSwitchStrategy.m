function strategy = generateSimpleBestSwitchStrategy(UE_beam_access_map, T)
    % UE_beam_access_map: 存所有 UE beam access 的 Map
    % T: 存 UE 名單 (有 UEName)
    
    beam_sequence_list = []; % 用來累積所有 beam 的倒序路徑

    for i = 1:height(T)
        ueName = T.UEName{i};
        ueAccess = UE_beam_access_map(ueName);

        % 按 StartTime 排序
        ueAccess = sortrows(ueAccess, 'StartTime');

        % 把 beam 依照時間順序列出來，然後倒過來
        beam_path = flipud(ueAccess.Beam);

        % 累積到總表
        beam_sequence_list = [beam_sequence_list; beam_path];
    end

    % 統計每個 beam 出現的次數
    [unique_beams, ~, idx] = unique(beam_sequence_list);
    counts = accumarray(idx, 1);

    % 按出現次數排序（次數多的 beam 排前面）
    [~, sortIdx] = sort(counts, 'descend');
    sorted_beams = unique_beams(sortIdx);

    % 取出出現過的 beam 數字
    strategy = zeros(length(sorted_beams), 1);
    for i = 1:length(sorted_beams)
        name = sorted_beams(i);
        beam_num = sscanf(name, 'Sensor%d');
        strategy(i) = beam_num;
    end

    % === 補齊沒出現過的 beam ===
    all_beams = 1:48;
    missing_beams = setdiff(all_beams, strategy);
    strategy = [strategy; missing_beams'];
end
