function strategy = generateTopoSortedStrategy(UE_beam_access_map, T)
    % 生成基於拓撲排序 + 出現次數補齊的完整 beam switch 策略

    beam_sequence_list = [];

    % 1. 收集所有UE的beam path（反過來）
    for i = 1:height(T)
        ueName = T.UEName{i};
        ueAccess = UE_beam_access_map(ueName);
        ueAccess = sortrows(ueAccess, 'StartTime');
        beam_path = flipud(ueAccess.Beam);
        beam_sequence_list = [beam_sequence_list; beam_path];
    end

    % 2. 建 precedence graph
    adj = containers.Map('KeyType', 'char', 'ValueType', 'any');
    indegree = containers.Map('KeyType', 'char', 'ValueType', 'double');

    for i = 1:length(beam_sequence_list)-1
        from_beam = beam_sequence_list{i};
        to_beam = beam_sequence_list{i+1};
        if ~isKey(adj, from_beam)
            adj(from_beam) = {};
        end
        if ~isKey(indegree, to_beam)
            indegree(to_beam) = 0;
        end
        if ~isKey(indegree, from_beam)
            indegree(from_beam) = 0;
        end
        if ~any(strcmp(adj(from_beam), to_beam))
            adj(from_beam) = [adj(from_beam), {to_beam}];
            indegree(to_beam) = indegree(to_beam) + 1;
        end
    end

    % 3. Topological Sort
    sorted_beams = [];
    all_beams_involved = keys(indegree);

    while ~isempty(all_beams_involved)
        zero_indegree = all_beams_involved(cellfun(@(b) indegree(b) == 0, all_beams_involved));
        if isempty(zero_indegree)
            warning("⚠️ 發現循環依賴 (cycle)，剩餘 beam 將以出現次數排序");
            break;
        end
        % 選出一個zero indegree的（可以加出現次數排序，但簡版隨便選）
        b = zero_indegree{1};
        sorted_beams = [sorted_beams; b];
        all_beams_involved(strcmp(all_beams_involved, b)) = [];

        if isKey(adj, b)
            children = adj(b);
            for k = 1:length(children)
                child = children{k};
                indegree(child) = indegree(child) - 1;
            end
        end
    end

    % 4. 如果有 cycle，用出現次數排序補齊
    if ~isempty(all_beams_involved)
        [unique_beams, ~, idx] = unique(beam_sequence_list);
        counts = accumarray(idx, 1);
        [~, order] = sort(counts, 'descend');
        remaining = unique_beams(order);
        for i = 1:length(remaining)
            if ~ismember(string(remaining(i)), string(sorted_beams))
                sorted_beams = [sorted_beams; remaining(i)];
            end
        end
    end

    % 5. 把沒出現過的 beams 通通補到後面
    all_possible_beams = "Sensor" + string(1:48);
    for i = 1:length(all_possible_beams)
        if ~ismember(all_possible_beams(i), string(sorted_beams))
            sorted_beams = [sorted_beams; all_possible_beams(i)];
        end
    end

    % 6. 最後轉成純數字
    strategy = zeros(length(sorted_beams),1);
    for i = 1:length(sorted_beams)
        strategy(i) = sscanf(sorted_beams(i), 'Sensor%d');
    end
end
