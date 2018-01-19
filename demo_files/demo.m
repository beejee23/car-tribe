%% cartrib demo

% create tribology data class
a = trib;

%% Import data
filename = '87.1 full envelope fresh (sweep 2 w passive activity).xlsx';
a.import(filename)

%% Plot deformation and friction data
tribplotyy(a,'d','fc')

%% Detect speed changes & plot
b = tribdetect(a);

tribplotyy(b,'d','fc')
%% Add thickness and plot strain

b.th = 1630.85 % microns
b.calcparams
tribplotyy(b,'st','fc')

%% Add radius and plot 

b.r = 25 % mm
b.calcparams
tribplotyy(b,'a','sh')

%% Segment the experiment

c = tribseg(b);

tribplotyy(c{7},'d','fc');

%% Get metadata

[metadata,d] = tribmeta(c);

%% Combine segments

dcomb = tribsegcombine(d,6,35);

tribplotyy(dcomb,'d','fc');



