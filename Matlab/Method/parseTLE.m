function tle_data = parseTLE(tle_lines)
    tle_data = [];
    count = 1;

    for i = 1:length(tle_lines)
        tline = tle_lines{i};
        tmp = split(string(tline));

        if mod(count, 3) == 1
            tle_data = [tle_data, tmp(2) + "_" + tmp(3)];
            disp(tmp(2) + "_" + tmp(3));
        elseif mod(count, 3) == 0
            tle_data = [tle_data, tmp(3)];
            tle_data = [tle_data, tmp(4)];
            tle_data = [tle_data, tmp(5)];
            tle_data = [tle_data, tmp(6)];
            tle_data = [tle_data, tmp(7)];
            tle_data = [tle_data, tmp(8)];
        elseif mod(count, 3) == 2
            tle_data = [tle_data, tmp(4)];
            epoch = tmp(4);
            a = str2double(epoch);
            y = fix(a/1000);
            [yy, mm, dd, HH, MM, SS] = datevec(datenum(y, 0, a - y*1000));
            if yy <= 56
                fprintf('20%02d/%02d/%02d %02d:%02d:%06.4f\n', yy, mm, dd, HH, MM, SS);
            else
                fprintf('19%02d/%02d/%02d %02d:%02d:%06.4f\n', yy, mm, dd, HH, MM, SS);
            end
        end
        count = count + 1;
    end
end
