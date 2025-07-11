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
addpath(fullfile(pwd, 'Matlab', 'Method'));
addpath(fullfile(pwd, 'Matlab'));
addpath(fullfile(pwd, 'ITRI_data'));

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
sc.SetTimePeriod('20 Mar 2024 14:38:00', '20 Mar 2024 14:50:00'); % modify
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

% 開啟檔案
file_path = "C:\Users\user\Desktop\Paper_Code\";
filename = file_path + "iridium_tle/TLE_2025_03_31_18_celestrak.txt";
fid = fopen(filename, 'r');
if fid == -1
    error('❌ 無法開啟 TLE 檔案，請確認路徑是否正確');
end

% 讀取所有行
tle_lines = textscan(fid, '%s', 'Delimiter', '\n');
fclose(fid);
tle_lines = tle_lines{1};

% 呼叫 function 處理 TLE
tle_data = parseTLE(tle_lines);
disp("---------------------- done");

%% Add satellite in STK through TLE file

addSatellitesFromTLE(root, sc, data, Iridium, Iridium_OMNet);

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

T = readtable('UE_location_5000.txt', 'FileType', 'text', 'Delimiter', '\t');

for i = 1:height(T)
    create_ue(sc, T.UEName{i}, T.Latitude(i), T.Longitude(i));
    disp(T.UEName{i} + " is ConStructed.");
end

%% Add 48 beams (Sensors) to each satellite

addAllBeamsToSatellites(root, Iridium_OMNet, beam_config);

disp("✨ Sensor 建立完成");

%% clear all sensor on satellite

clearOldSensors(root, Iridium_OMNet, 48);


%% construct access between satellite and ground station

[overlapTable, overlapStart] = computeSatGSaccess(root, sc, Iridium_OMNet);

disp(overlapTable);


%% Compute access between each beam and UE for all satellites

UE_Beam_access_map = containers.Map();  % key: ue name, value: table

beamCount = 48;

for i = 4539:height(T)
    disp(T.UEName{i})
    UE_Beam_access = computeUEBeamAccess(root, sc, Iridium_OMNet, T.UEName{i}, beamCount);

    UE_Beam_access_map(T.UEName{i}) = UE_Beam_access;

    disp(UE_Beam_access);
    disp(T.UEName{i} + " is ConStructed.");
end

% Save UE_Beam_access_map in order not to run it again.
save('UE_Beam_access_map.mat', 'UE_Beam_access_map');

load('UE_Beam_access_map.mat', 'UE_Beam_access_map');

%% Choose the beam path for each UE

UE_beam_path_map = containers.Map();  % key: ue name, value: simplified beam path table

for i = 1:height(T)
    ueName = T.UEName{i};
   
    rawAccessTable = UE_Beam_access_map(ueName);

    % 呼叫簡化函式，取得不重疊的 beam path
    simplifiedTable = simplifyUEBeamAccess(rawAccessTable, sc, ueName);

    % 儲存回 map
    UE_beam_path_map(ueName) = simplifiedTable;

    disp("✅ Beam path 已選定：" + ueName);
end

disp(UE_beam_path_map(T.UEName{1}));

%% Construct time slot and interval

time_slot_value = 1;

t_start = datetime(sc.StartTime, 'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS');
t_stop = datetime(sc.StopTime, 'InputFormat', 'dd MMM yyyy HH:mm:ss.SSS');

time_slots = t_start:seconds(time_slot_value):t_stop; % the value of time interval

%% Compute the number of UE in each beam and each time slot

% 初始化 beamTimeUECount
beamTimeUECount = containers.Map('KeyType', 'char', 'ValueType', 'double');

% 針對每個 UE
for i = 1:height(T)
    ueName = T.UEName{i};
    ueAccess = UE_beam_path_map(ueName);
    ueAccess = sortrows(ueAccess, 'StartTime');
    
    % 對每個 access 區段
    for j = 1:height(ueAccess)
        beam = ueAccess.Beam{j};
        startTime = floor(seconds(ueAccess.StartTime(j) - overlapStart(1)));
        endTime = ceil(seconds(ueAccess.StopTime(j) - overlapStart(1)));
        
        % 每秒累計一次
        timeSlots = startTime:endTime;
        for t = timeSlots
            key = strcat(beam, '_', num2str(t));
            if isKey(beamTimeUECount, key)
                beamTimeUECount(key) = beamTimeUECount(key) + 1;
            else
                beamTimeUECount(key) = 1;
            end
        end
    end
end

% 過濾 beamTimeUECount，只保留 0~240 秒的資料
allKeys = keys(beamTimeUECount);
filteredMap = containers.Map('KeyType', 'char', 'ValueType', 'double');

for i = 1:length(allKeys)
    key = allKeys{i};
    parts = split(key, '_');
    t = str2double(parts{2});
    
    if t >= 0 && t <= 240
        filteredMap(key) = beamTimeUECount(key);
    end
end

% 用 filteredMap 取代原本的 map
beamTimeUECount = filteredMap;

%% Develop different strategy of ordering the beam

beam_id_list = [16, 32, 48, 13:15, 29:31, 45:47, 8:12, 24:28, 40:44, 1:7, 17:23, 33:39];

strategy_random = [27, 3, 23, 16, 31, 25, 40, 44, 39, 19, 5, 9, 37, 17, 33, 11, 38, 7, 4, 47, ...
32, 35, 24, 15, 2, 48, 8, 21, 43, 1, 42, 10, 46, 12, 13, 14, 28, 6, 34, 29, 20, 45, 30, 41, 36, 18, 26, 22];
strategy_random = beam_id_list(strategy_random);

strategy_outer_to_inner = [28:48, 13:27, 4:12, 1:3];
strategy_outer_to_inner = beam_id_list(strategy_outer_to_inner);

strategy_inner_to_outer = [1:3, 4:12, 13:27, 28:48];  % 這是你可能關注的策略
strategy_inner_to_outer = beam_id_list(strategy_inner_to_outer);

strategy_mobility = [35:38, 34:-1:31, 39:43, 17:20, 16:-1:13, 21:24, 6:8, 9:11, 1:3, 5, 4, 12, 25:27, 30:-1:28, 44:48];
strategy_mobility = beam_id_list(strategy_mobility);

strategy_best = generateSimpleBestSwitchStrategy(UE_beam_path_map, T);

strategy_topo = generateTopoSortedStrategyWithCycleRemoval(UE_beam_path_map, T);

strategy_topo_ITRI = generateTopoSortedStrategyFromExcel('ITRI_data');

disp(length(strategy_topo1));


disp(strategy_topo_ITRI);
disp(length(strategy_topo_ITRI));

%% Construct beam-to-gateway mapping with sequential switch starting when satellite can access two gs simultaneously

strategy = strategy_topo_ITRI;
strategy_name = "strategy_topo_ITRI";
switch_gap = seconds(5);
beam_gateway_table = constructBeamGatewayTable(time_slots, Iridium_OMNet, overlapStart, strategy, switch_gap);

% 觀察指定 beam 的狀態（以 sat1_1 的 Sensor25 為例）
rows = beam_gateway_table.Satellite == "sat1_1" & beam_gateway_table.Beam == "Sensor25";
disp(beam_gateway_table(rows, :));

%% Construct the table including UE beams and satellite in each time slot

UE_time_table_map = containers.Map();  % key: ue name, value: table

for i = 1:height(T)  % T 是你存 UE 經緯度的表格
    ueName = T.UEName{i};
    beam_access = UE_beam_path_map(ueName);
    UE_time_table = constructUETimeTable(time_slots, ueName, beam_access, beam_gateway_table);
    UE_time_table_map(ueName) = UE_time_table;
    disp(UE_time_table);
    disp(T.UEName{i} + " is ConStructed.");
end


%% Analyze the result of current strategy

% 儲存每個 UE 的中斷次數
UE_switch_stats = table();

% 用來統計每種中斷次數出現的頻率
switch_freq_map = containers.Map('KeyType', 'double', 'ValueType', 'double');

for i = 1:height(T)  % T 是你存 UE 經緯度的表格
    ueName = T.UEName{i};
    disp(ueName);
    disp(UE_time_table_map(ueName));
    [sw_count, beam_seq, switched_beams] = analyzeUEPathAndSwitches(UE_time_table_map(ueName));

    % 儲存個別統計
    UE_switch_stats = [UE_switch_stats;
    table(string(ueName), ...
          strjoin(beam_seq, ' -> '), ...   % BeamPath 用 '->' 連起來
          strjoin(switched_beams, ', '), ...% Switch的beam用逗號隔開
          sw_count, ...
          'VariableNames', {'UE', 'BeamPath', 'SwitchedBeams', 'SwitchCount'})];
    % 累加次數統計
    if isKey(switch_freq_map, sw_count)
        switch_freq_map(sw_count) = switch_freq_map(sw_count) + 1;
    else
        switch_freq_map(sw_count) = 1;
    end

    disp(T.UEName{i} + " is done.")
end

% 將 switch_freq_map 轉成 table 方便看
switch_counts = cell2mat(keys(switch_freq_map));
frequencies = cell2mat(values(switch_freq_map));
FL_switch_summary = table(switch_counts', frequencies', ...
    'VariableNames', {'SwitchCount', 'NumUEs'});

disp("📊 不同中斷次數的統計分佈：");
disp(FL_switch_summary);

%% Save the analysis as excel file

% 自動設 Result 資料夾路徑
result_dir = fullfile(pwd, 'Matlab_data', 'Result');

% 如果資料夾不存在，自動建立
if ~exist(result_dir, 'dir')
    mkdir(result_dir);
end

% 儲存
saveUESwitchSummary(UE_switch_stats, FL_switch_summary, strategy_name, result_dir, strategy, overlapStart);


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
