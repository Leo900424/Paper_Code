function saveUESwitchSummary(UE_switch_stats, FL_switch_summary, strategy_name, output_folder)

    % 建立表格 header
    headers = {'UEName', 'BeamPath', 'SwitchedBeams', 'SwitchCount'};

    % 準備要寫入的 cell array
    data = cell(height(UE_switch_stats) + 2 + height(FL_switch_summary), length(headers));

    % 填入每個 UE 的資料
    for i = 1:height(UE_switch_stats)
        data{i+1, 1} = UE_switch_stats.UE{i};
        data{i+1, 2} = UE_switch_stats.BeamPath{i};
        data{i+1, 3} = UE_switch_stats.SwitchedBeams{i};
        data{i+1, 4} = UE_switch_stats.SwitchCount(i);
    end

    % 填入 header
    data(1,:) = headers;

    % 在底下插入統計總表
    offset = height(UE_switch_stats) + 3;
    data{offset-1, 1} = 'SwitchCount';
    data{offset-1, 2} = 'NumUEs';
    for i = 1:height(FL_switch_summary)
        data{offset+i-1, 1} = FL_switch_summary.SwitchCount(i);
        data{offset+i-1, 2} = FL_switch_summary.NumUEs(i);
    end

    % 組成檔案名稱
    filename = fullfile(output_folder, "ue_switch_summary_" + strategy_name + ".xlsx");

    % 寫入 Excel
    writecell(data, filename);
    
    disp("✅ 已儲存結果到：" + filename);
end
