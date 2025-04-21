function beam_gateway_table = constructBeamGatewayTable(time_slots, Iridium_OMNet, overlapStart, strategy, switch_gap)

    beam_gateway_table = table();

    fl_switch_start_time = overlapStart(1);  % 初始切換時刻

    for satIdx = 1:1  % 你也可以改為 length(Iridium_OMNet)
        satName = Iridium_OMNet(satIdx);

        for i = 1:48
            beamIdx = strategy(i);
            beamName = "Sensor" + num2str(beamIdx);

            % 每個 beam 有各自的切換時間
            beam_switch_time = fl_switch_start_time + (i - 1) * switch_gap;

            for t = time_slots
                if t < beam_switch_time
                    gw = "Svalbard";
                else
                    gw = "Izhevsk";
                end

                beam_gateway_table = [beam_gateway_table;
                    table(satName, beamName, t, gw, ...
                          'VariableNames', {'Satellite', 'Beam', 'Time', 'Gateway'})];
            end
        end
    end
end
