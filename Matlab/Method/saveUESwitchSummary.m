function saveUESwitchSummary(UE_switch_stats, FL_switch_summary, strategy_name, output_folder, strategy_order, overlap_start)
    % 建立表格 header
    headers = {'UEName', 'BeamPath', 'SwitchedBeams', 'SwitchCount', ...
               'BeamCount', 'NormalizedFLSI', 'ConsecFLSICount', ...
               'TransitionCount', 'ConsecutiveFLSIRatio'};

    % 準備要寫入的 cell array
    data = cell(height(UE_switch_stats) + 2 + height(FL_switch_summary) + 2, length(headers));  % 再多2行，放策略資訊

    % === 填入策略資訊 ===
    data{1,1} = 'Strategy Order';
    data{1,2} = mat2str(strategy_order);  % 把 strategy array 轉成字串

    data{2,1} = 'Switch Start Time';
    data{2,2} = string(overlap_start);    % 將 datetime 轉成字串

    % === 填入統計總表 ===
    offset = 3;  
    data{offset, 1} = 'SwitchCount';
    data{offset, 2} = 'NumUEs';

    for i = 1:height(FL_switch_summary)
        data{offset+i, 1} = FL_switch_summary.SwitchCount(i);
        data{offset+i, 2} = FL_switch_summary.NumUEs(i);
    end
    offset = offset + height(FL_switch_summary) + 1;

    % === 填入 header ===
    data(offset,:) = headers;

    % === 填入每個 UE 的資料 ===
    for i = 1:height(UE_switch_stats)
        data{i+offset, 1} = UE_switch_stats.UEName{i};
        data{i+offset, 2} = UE_switch_stats.BeamPath{i};
        data{i+offset, 3} = UE_switch_stats.SwitchedBeams{i};
        data{i+offset, 4} = UE_switch_stats.SwitchCount(i);
        data{i+offset, 5} = UE_switch_stats.BeamCount(i);
        data{i+offset, 6} = UE_switch_stats.NormalizedFLSI(i);
        data{i+offset, 7} = UE_switch_stats.ConsecFLSICount(i);
        data{i+offset, 8} = UE_switch_stats.TransitionCount(i);
        data{i+offset, 9} = UE_switch_stats.ConsecutiveFLSIRatio(i);
    end



    % 組成檔案名稱
    filename = fullfile(output_folder, "ue_switch_summary_" + strategy_name + ".xlsx");

    % 寫入 Excel
    writecell(data, filename);
    
    disp("✅ 已儲存結果到：" + filename);
end
