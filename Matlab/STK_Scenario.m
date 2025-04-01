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
global Iridium Plane Iridium145_TimeLine Iridium_OMNet beam_config;
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

for i = 1:1
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

        sensor.Graphics.FillVisible = true;

        % 使用 STK Connect 指令設定透明度
        cmd = sprintf('Graphics */Satellite/%s/Sensor/%s FillTranslucency %d', ...
                      sat_name, beam_name, beam_alpha(j));
        root.ExecuteCommand(cmd);
        disp(sat_name + ' ' + beam_name + ' complete');
    end
end

disp("✨ Sensor 建立完成");


%% Save STK scenario
disp("save");
root.Save;
disp("---------------------- done");
