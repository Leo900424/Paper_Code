function UE_time_table = constructUETimeTable(time_slots, ueName, UE_beam_table, beam_gateway_table)

    UE_time_table = table();

    for t = time_slots
        % 找出 UE 在這個時間 t 連到的 beam
        access_row = UE_beam_table(UE_beam_table.StartTime <= t & UE_beam_table.StopTime >= t, :);

        if ~isempty(access_row)
            beam_id = access_row.Beam(1);
            sat_id  = access_row.Satellite(1);
        else
            beam_id = "None";
            sat_id  = "None";
        end

        % 找出該 beam 在此時間連到哪個 gateway
        gw_row = beam_gateway_table(beam_gateway_table.Satellite == sat_id & ...
                                    beam_gateway_table.Beam == beam_id & ...
                                    beam_gateway_table.Time == t, :);

        if ~isempty(gw_row)
            gateway = gw_row.Gateway(1);
        else
            gateway = "None";
        end

        UE_time_table = [UE_time_table;
            table(t, ueName, sat_id, beam_id, gateway, ...
                'VariableNames', {'Time', 'UE', 'Satellite', 'Beam', 'Gateway'})];
    end
end
