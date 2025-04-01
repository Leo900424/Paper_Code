function [] = Satellite_Name()

global Iridium Plane Iridium145_TimeLine Iridium_OMNet beam_config;

Plane = [
    "Plane_1"
    "Plane_2"
    "Plane_3"
    "Plane_4"
    "Plane_5"
    "Plane_6"
];

Iridium_OMNet = [
    % Plane 1
    "sat1_1" % "IRIDIUM_145" % 1
    "sat1_2" % "IRIDIUM_143" % 2
    "sat1_3" % "IRIDIUM_140" % 3
    "sat1_4" % "IRIDIUM_148" % 4
    "sat1_5" % "IRIDIUM_150" % 5
    "sat1_6" % "IRIDIUM_153" % 6
    "sat1_7" % "IRIDIUM_144" % 7
    "sat1_8" % "IRIDIUM_149" % 8
    "sat1_9" % "IRIDIUM_146" % 9
    "sat1_10" % "IRIDIUM_142" % 10
    "sat1_11" % "IRIDIUM_157" % 11
    % Plane 2
    "sat2_1" % "IRIDIUM_134" % 12
    "sat2_2" % "IRIDIUM_141" % 13
    "sat2_3" % "IRIDIUM_137" % 14
    "sat2_4" % "IRIDIUM_116" % 15
    "sat2_5" % "IRIDIUM_135" % 16
    "sat2_6" % "IRIDIUM_151" % 17
    "sat2_7" % "IRIDIUM_120" % 18
    "sat2_8" % "IRIDIUM_113" % 19
    "sat2_9" % "IRIDIUM_138" % 20
    "sat2_10" % "IRIDIUM_130" % 21
    "sat2_11" % "IRIDIUM_131" % 22
    % Plane 3
    "sat3_1" % "IRIDIUM_117" % 23
    "sat3_2" % "IRIDIUM_168" % 24
    "sat3_3" % "IRIDIUM_180" % 25
    "sat3_4" % "IRIDIUM_123" % 26
    "sat3_5" % "IRIDIUM_126" % 27
    "sat3_6" % "IRIDIUM_167" % 28
    "sat3_7" % "IRIDIUM_171" % 29
    "sat3_8" % "IRIDIUM_121" % 30
    "sat3_9" % "IRIDIUM_118" % 31
    "sat3_10" % "IRIDIUM_172" % 32
    "sat3_11" % "IRIDIUM_173" % 33    
    % Plane 4
    "sat4_1" % "IRIDIUM_119" % 34
    "sat4_2" % "IRIDIUM_122" % 35
    "sat4_3" % "IRIDIUM_128" % 36
    "sat4_4" % "IRIDIUM_107" % 37
    "sat4_5" % "IRIDIUM_132" % 38
    "sat4_6" % "IRIDIUM_129" % 39
    "sat4_7" % "IRIDIUM_100" % 40 (or IRIDIUM_127)
    "sat4_8" % "IRIDIUM_133" % 41
    "sat4_9" % "IRIDIUM_125" % 42
    "sat4_10" % "IRIDIUM_136" % 43
    "sat4_11" % "IRIDIUM_139" % 44
    % Plane 5
    "sat5_1" % "IRIDIUM_158" % 45
    "sat5_2" % "IRIDIUM_160" % 46
    "sat5_3" % "IRIDIUM_159" % 47
    "sat5_4" % "IRIDIUM_163" % 48
    "sat5_5" % "IRIDIUM_165" % 49
    "sat5_6" % "IRIDIUM_166" % 50
    "sat5_7" % "IRIDIUM_154" % 51
    "sat5_8" % "IRIDIUM_164" % 52 (IRIDIUM_105 is dead)
    "sat5_9" % "IRIDIUM_108" % 53
    "sat5_10" % "IRIDIUM_155" % 54
    "sat5_11" % "IRIDIUM_156" % 55
    % Plane 6
    "sat6_1" % "IRIDIUM_102" % 56
    "sat6_2" % "IRIDIUM_112" % 57
    "sat6_3" % "IRIDIUM_104" % 58
    "sat6_4" % "IRIDIUM_114" % 59
    "sat6_5" % "IRIDIUM_103" % 60
    "sat6_6" % "IRIDIUM_109" % 61
    "sat6_7" % "IRIDIUM_106" % 62
    "sat6_8" % "IRIDIUM_152" % 63
    "sat6_9" % "IRIDIUM_147" % 64
    "sat6_10" % "IRIDIUM_110" % 65
    "sat6_11" % "IRIDIUM_111" % 66
];

Iridium = [
    % Plane 1
    "IRIDIUM_145" % 1
    "IRIDIUM_143" % 2
    "IRIDIUM_140" % 3
    "IRIDIUM_148" % 4
    "IRIDIUM_150" % 5
    "IRIDIUM_153" % 6
    "IRIDIUM_144" % 7
    "IRIDIUM_149" % 8
    "IRIDIUM_146" % 9
    "IRIDIUM_142" % 10
    "IRIDIUM_157" % 11
    % Plane 2
    "IRIDIUM_134" % 12
    "IRIDIUM_141" % 13
    "IRIDIUM_137" % 14
    "IRIDIUM_116" % 15
    "IRIDIUM_135" % 16
    "IRIDIUM_151" % 17
    "IRIDIUM_120" % 18
    "IRIDIUM_113" % 19
    "IRIDIUM_138" % 20
    "IRIDIUM_130" % 21
    "IRIDIUM_131" % 22
    % Plane 3
    "IRIDIUM_117" % 23
    "IRIDIUM_168" % 24
    "IRIDIUM_180" % 25
    "IRIDIUM_123" % 26
    "IRIDIUM_126" % 27
    "IRIDIUM_167" % 28
    "IRIDIUM_171" % 29
    "IRIDIUM_121" % 30
    "IRIDIUM_118" % 31
    "IRIDIUM_172" % 32
    "IRIDIUM_173" % 33    
    % Plane 4
    "IRIDIUM_119" % 34
    "IRIDIUM_122" % 35
    "IRIDIUM_128" % 36
    "IRIDIUM_107" % 37
    "IRIDIUM_132" % 38
    "IRIDIUM_129" % 39
    "IRIDIUM_100" % 40 (or IRIDIUM_127)
    "IRIDIUM_133" % 41
    "IRIDIUM_125" % 42
    "IRIDIUM_136" % 43
    "IRIDIUM_139" % 44
    % Plane 5
    "IRIDIUM_158" % 45
    "IRIDIUM_160" % 46
    "IRIDIUM_159" % 47
    "IRIDIUM_163" % 48
    "IRIDIUM_165" % 49
    "IRIDIUM_166" % 50
    "IRIDIUM_154" % 51
    "IRIDIUM_164" % 52 (IRIDIUM_105 is dead)
    "IRIDIUM_108" % 53
    "IRIDIUM_155" % 54
    "IRIDIUM_156" % 55
    % Plane 6
    "IRIDIUM_102" % 56
    
    "IRIDIUM_112" % 57
    "IRIDIUM_104" % 58
    "IRIDIUM_114" % 59
    "IRIDIUM_103" % 60
    "IRIDIUM_109" % 61
    "IRIDIUM_106" % 62
    "IRIDIUM_152" % 63
    "IRIDIUM_147" % 64
    "IRIDIUM_110" % 65
    "IRIDIUM_111" % 66
];

% 建立 beam 設定參數表，每一列為一個 beam，包含 Elevation 和 Azimuth
beam_config = [
    % Elev    Azimuth
     80,      0;
     80,    120;
     80,    240;

     65,      0;
     65,     40;
     65,     80;
     65,    120;
     65,    160;
     65,    200;
     65,    240;
     65,    280;
     65,    320;

     50,      0;
     50,     24;
     50,     48;
     50,     72;
     50,     96;
     50,    120;
     50,    144;
     50,    168;
     50,    192;
     50,    216;
     50,    240;
     50,    264;
     50,    288;
     50,    312;
     50,    336;

     30,      0;
     30,    17.143;
     30,    34.286;
     30,    51.429;
     30,    68.571;
     30,    85.714;
     30,   102.857;
     30,   120;
     30,   137.143;
     30,   154.286;
     30,   171.429;
     30,   188.571;
     30,   205.714;
     30,   222.857;
     30,   240;
     30,   257.143;
     30,   274.286;
     30,   291.429;
     30,   308.571;
     30,   325.714;
     30,   342.857
];


end