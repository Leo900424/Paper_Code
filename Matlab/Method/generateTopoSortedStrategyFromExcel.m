function strategy = generateTopoSortedStrategyFromExcel(folderPath)
    % 取得資料夾中所有 .xlsx 檔案
    files = dir(fullfile(folderPath, '*.xlsx'));

    % 初始化 beam sequence 集合
    combined_data = table;

    for i = 1:length(files)
        filepath = fullfile(folderPath, files(i).name);
        data = readtable(filepath, 'TextType', 'string');

        % 篩選長度 ≥ 5 的 beam path
        min_beam_len = 5;
        valid_idx = cellfun(@(x) length(str2num(x)), data.UniqueBeamSequence);
        data = data(valid_idx >= min_beam_len, :);

        % 合併進總表
        combined_data = [combined_data; data];
    end

    % 初始化
    beam_edges = containers.Map('KeyType', 'char', 'ValueType', 'double');
    beam_sequence_list = {};

    % 每筆 access 對應一個 Unique Beam Sequence
    for i = 1:height(combined_data)
        beam_seq_str = combined_data.UniqueBeamSequence(i);
        beam_seq = str2num(beam_seq_str); %#ok<ST2NM>

        for j = 1:length(beam_seq)-1
            from_beam = beam_seq(j);
            to_beam = beam_seq(j+1);
            edge_key = sprintf('Sensor%d->Sensor%d', from_beam, to_beam);

            if isKey(beam_edges, edge_key)
                beam_edges(edge_key) = beam_edges(edge_key) + 1;
            else
                beam_edges(edge_key) = 1;
            end

            beam_sequence_list = [beam_sequence_list;
                {sprintf('Sensor%d', from_beam)};
                {sprintf('Sensor%d', to_beam)}];
        end
    end

    % 構建 adjacency list 和 indegree
    adj = containers.Map('KeyType', 'char', 'ValueType', 'any');
    indegree = containers.Map('KeyType', 'char', 'ValueType', 'double');
    keys_list = keys(beam_edges);
    for i = 1:length(keys_list)
        tokens = split(keys_list{i}, '->');
        from_beam = tokens{1};
        to_beam = tokens{2};

        if ~isKey(adj, from_beam)
            adj(from_beam) = {};
        end
        if ~any(strcmp(adj(from_beam), to_beam))
            adj(from_beam) = [adj(from_beam), {to_beam}];
        end
        if ~isKey(indegree, to_beam)
            indegree(to_beam) = 0;
        end
        if ~isKey(indegree, from_beam)
            indegree(from_beam) = 0;
        end
        indegree(to_beam) = indegree(to_beam) + 1;
    end

    % 移除 cycle
    [adj, indegree] = removeCyclesDFS(adj, indegree, beam_edges);

    % 拓撲排序
    sorted_beams = [];
    all_beams = keys(indegree);
    while ~isempty(all_beams)
        zero_in = all_beams(cellfun(@(x) indegree(x)==0, all_beams));
        if isempty(zero_in)
            warning('仍有 cycle 存在，排序失敗');
            break;
        end
        b = zero_in{1};
        sorted_beams = [sorted_beams; {b}];
        all_beams(strcmp(all_beams, b)) = [];
        if isKey(adj, b)
            children = adj(b);
            for k = 1:length(children)
                indegree(children{k}) = indegree(children{k}) - 1;
            end
        end
    end

    % 補上所有未出現的 beam
    all_possible = "Sensor" + string(1:48);
    for i = 1:length(all_possible)
        if ~ismember(all_possible(i), string(sorted_beams))
            sorted_beams = [sorted_beams; {all_possible(i)}];
        end
    end

    % 轉換為數值 vector
    strategy = zeros(length(sorted_beams), 1);
    for i = 1:length(sorted_beams)
        strategy(i) = sscanf(sorted_beams{i}, 'Sensor%d');
    end
end

function [adj, indegree] = removeCyclesDFS(adj, indegree, beam_edges)
    beams = keys(adj);
    visited = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    recStack = containers.Map('KeyType', 'char', 'ValueType', 'logical');

    adj_values = values(adj, keys(adj));
    all_beams = unique([beams, horzcat(adj_values{:})]);

    for i = 1:length(all_beams)
        visited(all_beams{i}) = false;
        recStack(all_beams{i}) = false;
    end

    for i = 1:length(beams)
        b = beams{i};
        if ~visited(b)
            [adj, indegree, ~] = dfsVisit(b, adj, indegree, visited, recStack, beam_edges, {});
        end
    end
end

function [adj, indegree, hasCycle] = dfsVisit(u, adj, indegree, visited, recStack, beam_edges, path)
    visited(u) = true;
    recStack(u) = true;
    hasCycle = false;
    path{end+1} = u;

    if isKey(adj, u)
        children = adj(u);
        i = 1;
        while i <= length(children)
            v = children{i};
            if ~visited(v)
                [adj, indegree, f] = dfsVisit(v, adj, indegree, visited, recStack, beam_edges, path);
                hasCycle = hasCycle || f;
            elseif recStack(v)
                idx = find(strcmp(path, v));
                cycle_path = path(idx:end);
                fprintf("🔁 Detected cycle: ");
                fprintf("%s -> ", cycle_path{1:end-1});
                fprintf("%s\n", cycle_path{end});

                edge = strcat(u, '->', v);
                if isKey(beam_edges, edge)
                    children(strcmp(children, v)) = [];
                    adj(u) = children;
                    indegree(v) = indegree(v) - 1;
                    fprintf("⚠️ Removed edge %s\n", edge);
                    continue; % 注意 children 長度已變動，不遞增 i
                end
                hasCycle = true;
            end
            i = i + 1;
        end
    end

    recStack(u) = false;
end