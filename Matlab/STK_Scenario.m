%% 重置 Command window 與 Workspace
clear;
clc;

%% 與STK連線
disp("連接STK");
con = actxGetRunningServer('STK12.application');
root = con.Personality2;
con.Visible = 1;
disp("---------------------- done");

%% 初始化 衛星資訊
addpath(fullfile(pwd, 'Matlab'));
global Iridium Plane Iridium_OMNet beam_config;
disp("初始化");
Satellite_Name();
file_path = "C:\Users\user\Desktop\Paper_Code\";
if ~exist(file_path + 'STK','dir')
    mkdir(file_path);
end
if ~exist(file_path + 'Matlab_data','dir')
    mkdir(file_path);
end
disp("---------------------- done");

%% STK 新建立一個場景
disp("新建立一個場景");
root.Children.New('eScenario', 'Iridium');
disp("---------------------- done");

%% STL 關閉後用載入的方式開啟
disp("載入舊場景");
root.LoadScenario('C:\Users\user\Desktop\Paper_Code\STK\Scenario20240217\Scenario.sc');
disp("---------------------- done");


%% STK 設定單位與場景時間 (M)
disp("設定單位與場景時間");
sc = root.CurrentScenario;
root.UnitPreferences.Item('DateFormat').SetCurrentUnit('UTCG');
sc.SetTimePeriod('20 Mar 2024 00:00:00.000', '21 Mar 2024 00:00:00.000'); % modify
root.ExecuteCommand('Animate * Reset');
root.UnitPreferences.SetCurrentUnit('Distance', 'km'); % modify
root.UnitPreferences.SetCurrentUnit('Latitude', 'deg'); % modify
root.UnitPreferences.SetCurrentUnit('Longitude', 'deg'); % modify
disp("---------------------- done");

%% STK 場景另存新檔 (M)
disp("Save as");
sub_file_path = file_path + "STK\Scenario20240217\"; % modify
if ~exist(sub_file_path,'dir')
    mkdir(sub_file_path);
end
root.SaveAs(file_path + 'STK\Scenario20240217\Scenario'); % modify
disp("---------------------- done");

%% Read TLE Content 
disp("read TLEs");
file = fopen(file_path + 'iridium_tle/TLE_2025_03_31_18_celestrak.txt','r'); % 讀取本地端檔案   % modify
if file == -1
    error('❌ 無法開啟 TLE 檔案，請確認路徑是否正確');
end
data = [];
n1 = 0;
miu = 3.9686e5;
sat_number = n1/3;

count = 1;
while ~feof(file)
    tline = fgetl(file);
    tmp = split(tline);

    if mod(count, 3) == 1
        % data = [data, tmp(1)];%     satellite name
        data = [data, tmp(2)+"_"+tmp(3)];%     satellite name
        disp(tmp(2)+"_"+tmp(3));
    elseif mod(count, 3) == 0
        data = [data, tmp(3)];%     Inclination
        data = [data, tmp(4)];%     Right_Ascension_of_the_Ascending_node
        data = [data, tmp(5)];%     Eccentricity
        data = [data, tmp(6)];%     Argument_of_Perigee
        data = [data, tmp(7)];%     Mean_Anomaly
        data = [data, tmp(8)];%     Mean_Motion

    elseif mod(count, 3) == 2
        data = [data, tmp(4)];%     Time Epoch
        epoch = tmp(4);
        a = str2double(epoch);
        y = fix(a/1000);
        [yy, mm, dd, HH, MM, SS] = datevec(datenum(y,0,a - y*1000)); % corrected
        if yy <= 56
            fprintf('20%02d/%02d/%02d %02d:%02d:%06.4f\n',yy,mm,dd,HH,MM,SS);
        else
            fprintf('19%02d/%02d/%02d %02d:%02d:%06.4f\n',yy,mm,dd,HH,MM,SS);
        end
    end
    count = count + 1;
end
fclose(file);
disp("---------------------- done");

%% Add satellite in STK through TLE file
disp("add satellites");
root.UnitPreferences.Item('DateFormat').SetCurrentUnit('UTCG');
for i = 1:8:length(data)
    % 提取衛星資料
    sat_name = string(data(i));
    if ~ismember(1, strcmp(sat_name,Iridium)) % 只新增需要的衛星 (有在 Satellite_Name 名單內)
       disp(sat_name + " not used");
       continue; 
    else
        disp(fix(i/8)+1 + "");
    end
    epoch = string(data(i+1));
    Inclination = str2double(cell2mat(data(i+2)));
    Right_Ascension_of_the_Ascending_node = str2double(cell2mat(data(i+3)));
    Eccentricity = str2double(cell2mat(data(i+4)))*10^-6;
    Argument_of_Perigee = str2double(cell2mat(data(i+5)));
    Mean_Anomaly = str2double(cell2mat(data(i+6)));
    Mean_Motion = str2double(cell2mat(data(i+7)));
    % epoch to datetime string
    e1 = str2double(regexp(epoch, '(\d{2})(\d{3})(\.\d+)', 'tokens', 'once'));
    en = datenum(e1(1) + 2000, 0, e1(2), 24 * e1(3), 0, 0);
    et = datetime(en, 'ConvertFrom', 'datenum');
    es = datestr(et);
    
    % 新增衛星物件
    disp(Iridium_OMNet(find(Iridium == sat_name ))); % 將衛星名稱依順序轉換成特定編號
    sat = sc.Children.New('eSatellite',  string(Iridium_OMNet(find(Iridium == sat_name ))) );
    
    % HPOP 設定方式
    sat.SetPropagatorType('ePropagatorHPOP');
    sat.Propagator.InitialState.OrbitEpoch.SetExplicitTime(es);
    kepler = sat.Propagator.InitialState.Representation.ConvertTo('eOrbitStateClassical');
    kepler.SizeShapeType = 'eSizeShapeMeanMotion';
    kepler.LocationType = 'eLocationMeanAnomaly';
    kepler.Orientation.AscNodeType = 'eAscNodeRAAN';

    kepler.SizeShape.MeanMotion = Mean_Motion * 0.0041666648666668;
    kepler.SizeShape.Eccentricity = Eccentricity;
    kepler.Orientation.Inclination = Inclination;
    kepler.Orientation.ArgOfPerigee = Argument_of_Perigee;
    kepler.Orientation.AscNode.Value = Right_Ascension_of_the_Ascending_node;
    kepler.Location.value = Mean_Anomaly;

    sat.Propagator.InitialState.Representation.Assign(kepler);
    sat.Propagator.Propagate;
end
disp("---------------------- done");

%% 建立地面站：Svalbard 與 Izhevsk
disp("建立地面站 GGS_Svalbard 與 GGS_Izhevsk");

% 1. Svalbard
ggs1 = sc.Children.New('eFacility', 'GS_Svalbard');
ggs1.Position.AssignGeodetic(78.2298, 15.4078, 0);  % 緯度, 經度, 高度 (km)
ggs1.Graphics.LabelVisible = true;

% 設定最小仰角 10 度
elevation1 = ggs1.AccessConstraints.AddConstraint('eCstrElevationAngle');
elevation1.EnableMin = 1;
elevation1.Min = 10;

% 2. Izhevsk
ggs2 = sc.Children.New('eFacility', 'GS_Izhevsk');
ggs2.Position.AssignGeodetic(56.8498, 53.2045, 0);
ggs2.Graphics.LabelVisible = true;

% 設定最小仰角 10 度
elevation2 = ggs2.AccessConstraints.AddConstraint('eCstrElevationAngle');
elevation2.EnableMin = 1;
elevation2.Min = 10;

disp("✅ 地面站與仰角限制設定完成");

%% Construct UE

ue1 = sc.Children.New('eFacility', 'UE1');
ue1.Position.AssignGeodetic(67.54, 34.31, 0);;  % 北緯 70, 東經 40

ue1.Graphics.LabelVisible = true;

% 設定最小仰角 10 度
elevation = ue1.AccessConstraints.AddConstraint('eCstrElevationAngle');
elevation.EnableMin = 1;
elevation.Min = 10;

%% construct access between satellite and ground station
disp("🔍 分析衛星與地面站之間的 Access 時間 + 重疊時間");

ggs1 = root.GetObjectFromPath("/Facility/GS_Svalbard");
ggs2 = root.GetObjectFromPath("/Facility/GS_Izhevsk");

for i = 1:length(Iridium_OMNet)
    satName = Iridium_OMNet(i);
    satObj = root.GetObjectFromPath("/Satellite/" + satName);

    % === Access to GGS_Svalbard ===
    access1 = satObj.GetAccessToObject(ggs1);
    access1.ComputeAccess;
    dp1 = access1.DataProviders.Item('Access Data').Exec(sc.StartTime, sc.StopTime);
    startTimes1 = string(dp1.DataSets.GetDataSetByName('Start Time').GetValues);
    stopTimes1  = string(dp1.DataSets.GetDataSetByName('Stop Time').GetValues);
    dtStart1 = datetime(startTimes1, 'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS', 'Locale', 'en_US');
    dtStop1  = datetime(stopTimes1,  'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS', 'Locale', 'en_US');

    % === Access to GGS_Izhevsk ===
    access2 = satObj.GetAccessToObject(ggs2);
    access2.ComputeAccess;
    dp2 = access2.DataProviders.Item('Access Data').Exec(sc.StartTime, sc.StopTime);
    startTimes2 = string(dp2.DataSets.GetDataSetByName('Start Time').GetValues);
    stopTimes2  = string(dp2.DataSets.GetDataSetByName('Stop Time').GetValues);
    dtStart2 = datetime(startTimes2, 'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS', 'Locale', 'en_US');
    dtStop2  = datetime(stopTimes2,  'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS', 'Locale', 'en_US');

    % % === 顯示 Access 時間 ===
    % disp("🛰️ " + satName + " ➜ GGS_Svalbard Access 時間：");
    % disp(table(datestr(dtStart1, 'yyyy/mm/dd HH:MM:SS'), ...
    %            datestr(dtStop1, 'yyyy/mm/dd HH:MM:SS'), ...
    %            'VariableNames', {'Start', 'Stop'}));

    % disp("🛰️ " + satName + " ➜ GGS_Izhevsk Access 時間：");
    % disp(table(datestr(dtStart2, 'yyyy/mm/dd HH:MM:SS'), ...
    %            datestr(dtStop2, 'yyyy/mm/dd HH:MM:SS'), ...
    %            'VariableNames', {'Start', 'Stop'}));

    % === 找出交集時間段 ===
    overlapStart = [];
    overlapEnd   = [];

    for m = 1:length(dtStart1)
        for n = 1:length(dtStart2)
            s = max(dtStart1(m), dtStart2(n));
            e = min(dtStop1(m), dtStop2(n));
            if s < e
                overlapStart = [overlapStart; s];
                overlapEnd   = [overlapEnd; e];
            end
        end
    end

    disp("🔗 " + satName + " ➜ Svalbard & Izhevsk 同時可見區段：");
    if isempty(overlapStart)
        disp("⚠️ 無重疊區段");
    else
        disp(table(datestr(overlapStart, 'yyyy/mm/dd HH:MM:SS'), ...
                   datestr(overlapEnd,   'yyyy/mm/dd HH:MM:SS'), ...
                   'VariableNames', {'Start', 'Stop'}));
    end

    disp("--------------------------------------------------");
end

disp("✅ Access + 重疊時間 分析完成");

%% Add 48 beams (Sensors) to each satellite
disp("建立 48 個 Sensor");

beam_count = 48;
cone_half_angle = 14; % 錐角角度（度）

% 設定 4 group 對應透明度
beam_alpha = zeros(48, 1);
beam_alpha(1:3) = 0;        % Group 1：最不透明（紅）
beam_alpha(4:12) = 30;      % Group 2：微透明（綠）
beam_alpha(13:27) = 60;     % Group 3：半透明（藍）
beam_alpha(28:48) = 90;     % Group 4：幾乎透明（橘）

for i = 1:length(Iridium_OMNet)
    sat_name = Iridium_OMNet(i);
    sat = root.GetObjectFromPath("/Satellite/" + sat_name);
    
    for j = 1:beam_count
        beam_name = "Sensor" + num2str(j);
        sensor = sat.Children.New('eSensor', beam_name);

        % 設定 Pattern 為 Simple Conic
        sensor.SetPatternType('eSnSimpleConic');
        sensor.CommonTasks.SetPatternSimpleConic(double(cone_half_angle), double(1));  % 使用 double 以避免錯誤

        % 指向設定：固定 Az/El 方位角
        sensor.SetPointingType('eSnPtFixed');
        sensor.CommonTasks.SetPointingFixedAzEl(beam_config(j, 2), beam_config(j, 1), 'eAzElAboutBoresightRotate')

        % 使用 Graphics 屬性設定beam coverage的可見度
        sensor.Graphics.FillVisible = true;

        % 使用 STK Connect 指令設定透明度
        cmd = sprintf('Graphics */Satellite/%s/Sensor/%s FillTranslucency %d', ...
                      sat_name, beam_name, beam_alpha(j));
        root.ExecuteCommand(cmd);
        disp(sat_name + ' ' + beam_name + ' complete');
    end
end

disp("✨ Sensor 建立完成");

%% Construct access between each beam and UE for all satellites
disp("🔍 對所有衛星分析 UE 的 Access");

ueName = "ue1";         % 可改成你實際建立的 UE 名稱
beamCount = 48;
UE_beam_access = table();

ueObj = root.GetObjectFromPath("/Facility/" + ueName);

for satIdx = 1:length(Iridium_OMNet)
    satName = Iridium_OMNet(satIdx);
    satObj = root.GetObjectFromPath("/Satellite/" + satName);

    for beamIdx = 1:beamCount
        beamName = "Sensor" + num2str(beamIdx);
        try
            sensor = satObj.Children.Item(beamName);

            % 建立與 UE 的 Access
            access = sensor.GetAccessToObject(ueObj);
            access.ComputeAccess;

            % 擷取 Access 資訊
            dp = access.DataProviders.Item('Access Data').Exec(sc.StartTime, sc.StopTime);
            if dp.DataSets.Count > 0
                starts = string(dp.DataSets.GetDataSetByName('Start Time').GetValues);
                stops  = string(dp.DataSets.GetDataSetByName('Stop Time').GetValues);

                for j = 1:length(starts)
                    UE_beam_access = [UE_beam_access; 
                        table(string(satName), string(beamName), starts(j), stops(j), ...
                        'VariableNames', {'Satellite', 'Beam', 'StartTime', 'StopTime'})];
                end
            end
        catch ME
            warning("⚠️ 讀取 %s 的 %s 時發生錯誤：%s", satName, beamName, ME.message);
        end
    end
end

disp("✅ 所有衛星的 UE Access 分析完成");

% 轉換時間格式並排序
UE_beam_access.StartTime = datetime(UE_beam_access.StartTime, 'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS', 'Locale', 'en_US');
UE_beam_access.StopTime  = datetime(UE_beam_access.StopTime,  'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS', 'Locale', 'en_US');
UE_beam_access_sorted = sortrows(UE_beam_access, 'StartTime');

disp(UE_beam_access_sorted);
%% obtain LLR from STK
% 參考資料： https://blog.csdn.net/u011575168/article/details/80671283
disp("get LLR");
root.UnitPreferences.Item('DateFormat').SetCurrentUnit('EpSec');
sat_nums = 66;
LLRCell = cell(sat_nums,1);
for i = 1:sat_nums
    disp("/Satellite/"+Iridium_OMNet(i));
    satellite = root.GetObjectFromPath("/Satellite/"+Iridium_OMNet(i));
    
    satPosDP = satellite.DataProviders.Item('LLR State').Group.Item('Fixed').Exec(sc.StartTime,sc.StopTime,5);
    Time = cell2mat(satPosDP.DataSets.GetDataSetByName('Time').GetValues);
    Lat = cell2mat(satPosDP.DataSets.GetDataSetByName('Lat').GetValues);
    Lon = cell2mat(satPosDP.DataSets.GetDataSetByName('Lon').GetValues);
    Rad = cell2mat(satPosDP.DataSets.GetDataSetByName('Rad').GetValues);
    LLR = table(Time, Lat, Lon, Rad);
    LLRCell{i,1} = LLR;
    sub_file_path = "Matlab_data\LLRv20240217\";   % modify
    if ~exist(file_path+sub_file_path,'dir')
        mkdir(file_path+sub_file_path);
    end
    writetable(LLR, file_path+sub_file_path+Iridium_OMNet(i)+"_LLR_OMNet.xlsx");
end
path = file_path + "/Matlab/LLRv20240217_00_OMNet.mat";   % modify
save(path,"LLRCell");
disp("LLRCell---------------------- done");

%% obatain J2000 coordinate from STK
% 參考資料： https://blog.csdn.net/u011575168/article/details/80671283
disp("get J2000 XYZ");
sc = root.CurrentScenario;
root.UnitPreferences.Item('DateFormat').SetCurrentUnit('EpSec');
% sat_nums = 66;
[rows, cols] = size(Iridium_OMNet);
sat_nums = rows;
XYZCell = cell(sat_nums,1);
for i = 1:sat_nums
    % disp("/Satellite/"+Iridium(i));
    % satellite = root.GetObjectFromPath("/Satellite/"+Iridium(i));

    disp("/Satellite/"+Iridium_OMNet(i)); % 只分析不同時間點的 Iridium145 
    satellite = root.GetObjectFromPath("/Satellite/"+Iridium_OMNet(i)); % 只分析不同時間點的 Iridium145 
    
    satPosDP = satellite.DataProviders.Item('Cartesian Position').Group.Item('Fixed').Exec(sc.StartTime,sc.StopTime,5);
    Time = cell2mat(satPosDP.DataSets.GetDataSetByName('Time').GetValues);
    x = cell2mat(satPosDP.DataSets.GetDataSetByName('x').GetValues);
    y = cell2mat(satPosDP.DataSets.GetDataSetByName('y').GetValues);
    z = cell2mat(satPosDP.DataSets.GetDataSetByName('z').GetValues);
    XYZ = table(Time, x, y, z);
    XYZCell{i,1} = XYZ;
    sub_file_path = "Matlab_data\XYZv20240217\"; % modify
    if ~exist(file_path+sub_file_path,'dir')
        mkdir(file_path+sub_file_path);
    end
    
    writetable(XYZ, file_path + sub_file_path + Iridium_OMNet(i)+"_XYZ_OMNet.xlsx");
    % writetable(XYZ, file_path + sub_file_path + Iridium145_TimeLine(i)+"_XYZ.xlsx"); % 只分析不同時間點的 Iridium145 
end
path = file_path + "Matlab/XYZ20240217_00_OMNet.mat"; % modify
% path = file_path + "Log\XYZCellv20240301to31.mat"; % 只分析不同時間點的 Iridium145 
save(path,"XYZCell");
disp("XYZCell---------------------- done");


%% Save STK scenario
disp("save");
root.Save;
disp("---------------------- done");
