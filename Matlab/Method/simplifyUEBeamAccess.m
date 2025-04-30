function UE_beam_access_clean = simplifyUEBeamAccess(UE_beam_access_raw, sc, ueName)
    UE_beam_access_clean = table();
    currentTime = datetime(sc.StartTime, 'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS');
    maxTime     = datetime(sc.StopTime,  'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS');

    while currentTime < maxTime
        % 找出可連接的 beam，且 StartTime <= currentTime，StopTime > currentTime
        candidateRows = UE_beam_access_raw( ...
            UE_beam_access_raw.StartTime <= currentTime & UE_beam_access_raw.StopTime > currentTime, :);

        if isempty(candidateRows)
            % 沒有 beam，填入 None 段直到下一段 beam 開始
            nextStarts = UE_beam_access_raw.StartTime(UE_beam_access_raw.StartTime > currentTime);
            nextCandidateStart = min([nextStarts; maxTime]);

            UE_beam_access_clean = [UE_beam_access_clean; ...
                table("None", "None", string(ueName), currentTime, nextCandidateStart, ...
                'VariableNames', {'Satellite', 'Beam', 'UE', 'StartTime', 'StopTime'})];

            currentTime = nextCandidateStart;
        else
            % 選擇 StopTime 最早，且 StartTime <= currentTime 的 beam
            [~, idx] = min(candidateRows.StopTime);
            selected = candidateRows(idx, :);

            % 修正 StartTime 為 currentTime，避免重疊
            selected.StartTime = currentTime;

            UE_beam_access_clean = [UE_beam_access_clean; selected];
            currentTime = selected.StopTime;
        end
    end

    disp("✅ 已完成簡化 beam path for " + ueName);
end
