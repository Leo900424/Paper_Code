function UE_beam_access_clean = simplifyUEBeamAccess(UE_beam_access_raw, sc, ueName)
    UE_beam_access_clean = table();
    currentTime = datetime(sc.StartTime, 'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS');
    maxTime     = datetime(sc.StopTime,  'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS');

    while currentTime < maxTime
        % 找出在 currentTime 能 access 的所有 Beam
        candidateRows = UE_beam_access_raw( ...
            UE_beam_access_raw.StartTime <= currentTime & UE_beam_access_raw.StopTime > currentTime, :);

        if isempty(candidateRows)
            % 找下一個可以連線的時間點，直接跳過無連線段
            nextStarts = UE_beam_access_raw.StartTime(UE_beam_access_raw.StartTime > currentTime);
            if isempty(nextStarts)
                break;  % 沒有後續可連接的 beam，結束
            else
                currentTime = min(nextStarts);
            end
        else
            % 選擇 StopTime 最早的 beam，並修正起始時間
            [~, idx] = min(candidateRows.StopTime);
            bestRow = candidateRows(idx, :);
            bestRow.StartTime = currentTime;

            UE_beam_access_clean = [UE_beam_access_clean; bestRow];
            currentTime = bestRow.StopTime;
        end
    end

    disp("✅ 已完成簡化 beam path for " + ueName);
end
