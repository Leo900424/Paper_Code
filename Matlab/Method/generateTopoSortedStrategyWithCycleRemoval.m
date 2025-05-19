function strategy = generateTopoSortedStrategyWithCycleRemoval(UE_beam_access_map, T)
    % 收集所有UE的beam path（反過來）
    beam_sequence_list = [];
    beam_edges = containers.Map('KeyType', 'char', 'ValueType', 'any');

    for i = 1:height(T)
        ueName = T.UEName{i};
        ueAccess = UE_beam_access_map(ueName);
        ueAccess = sortrows(ueAccess, 'StartTime');
        beam_path = flipud(ueAccess.Beam);

        for j = 1:length(beam_path)-1
            from_beam = beam_path{j};
            to_beam = beam_path{j+1};
            key = strcat(from_beam, '->', to_beam);
            if isKey(beam_edges, key)
                beam_edges(key) = beam_edges(key) + 1;
            else
                beam_edges(key) = 1;
            end
            beam_sequence_list = [beam_sequence_list; {from_beam}; {to_beam}];
        end
    end

    % 構建 adjacency list 和 indegree
    adj = containers.Map('KeyType', 'char', 'ValueType', 'any');
    indegree = containers.Map('KeyType', 'char', 'ValueType', 'double');
    keys_list = keys(beam_edges);
    for i = 1:length(keys_list)
        edge = keys_list{i};
        tokens = split(edge, '->');
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

    % --- Cycle detection and removal ---
    [adj, indegree] = removeCyclesDFS(adj, indegree, beam_edges);

    % --- Topological Sort ---
    sorted_beams = [];
    all_beams_involved = keys(indegree);
    while ~isempty(all_beams_involved)
        zero_indegree = all_beams_involved(cellfun(@(b) indegree(b) == 0, all_beams_involved));
        if isempty(zero_indegree)
            warning("⚠️ 拓撲排序失敗：圖中仍存在環");
            break;
        end
        b = zero_indegree{1};
        sorted_beams = [sorted_beams; {b}];
        all_beams_involved(strcmp(all_beams_involved, b)) = [];
        if isKey(adj, b)
            children = adj(b);
            for k = 1:length(children)
                child = children{k};
                indegree(child) = indegree(child) - 1;
            end
        end
    end

    % --- 出現次數補齊 ---
    [unique_beams, ~, idx] = unique(beam_sequence_list);
    counts = accumarray(idx, 1);
    [~, order] = sort(counts, 'descend');
    remaining = unique_beams(order);
    for i = 1:length(remaining)
        if ~ismember(string(remaining(i)), string(sorted_beams))
            sorted_beams = [sorted_beams; remaining(i)];
        end
    end

    % --- 補上所有 beams ---
    all_possible_beams = "Sensor" + string(1:48);
    for i = 1:length(all_possible_beams)
        if ~ismember(all_possible_beams(i), string(sorted_beams))
            sorted_beams = [sorted_beams; all_possible_beams(i)];
        end
    end

    % --- 轉成數字 ---
    strategy = zeros(length(sorted_beams),1);
    for i = 1:length(sorted_beams)
        strategy(i) = sscanf(sorted_beams(i), 'Sensor%d');
    end
end

function [adj, indegree] = removeCyclesDFS(adj, indegree, beam_edges)
    % 用DFS找cycle並刪掉最弱邊
    beams = keys(adj);
    all_beams = beams;

    % 收集所有子節點
    for i = 1:length(beams)
        children = adj(beams{i});
        all_beams = [all_beams, children];
    end

    all_beams = unique(all_beams);

    % 初始化 visited 和 recStack
    visited = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    recStack = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    for i = 1:length(all_beams)
        visited(all_beams{i}) = false;
        recStack(all_beams{i}) = false;
    end

    for i = 1:length(beams)
        visited(beams{i}) = false;
        recStack(beams{i}) = false;
    end

    for i = 1:length(beams)
        beam = beams{i};
        [adj, indegree] = dfsVisit(beam, adj, indegree, visited, recStack, beam_edges);
    end
end

function [adj, indegree, hasCycle] = dfsVisit(u, adj, indegree, visited, recStack, beam_edges)
    visited(u) = true;
    recStack(u) = true;
    hasCycle = false;

    if isKey(adj, u)
        children = adj(u);
        for i = 1:length(children)
            v = children{i};
            if ~visited(v)
                [adj, indegree, foundCycle] = dfsVisit(v, adj, indegree, visited, recStack, beam_edges);
                hasCycle = hasCycle || foundCycle;
            elseif recStack(v)
                % cycle detected → remove weakest edge
                edge1 = strcat(u, '->', v);
                if isKey(beam_edges, edge1)
                    childrenList = adj(u);
                    childrenList(strcmp(childrenList, v)) = [];
                    adj(u) = childrenList;
                    indegree(v) = indegree(v) - 1;
                    fprintf("⚠️ 刪掉邊 %s (breaking cycle)\n", edge1);
                end
                hasCycle = true;
            end
        end
    end
    recStack(u) = false;
end
