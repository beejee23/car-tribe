function [objout]= tribcleanINSITUolder(objin)
% Clean tribology data channels using filters

%% Data transfer
% Transfer over trib class parameters that aren't cleaned
objout = trib;
objout.filename = objin.filename;
objout.th = objin.th;
objout.t = objin.t;

%% Identify periods of sliding

% Pre-allocate array;
objout.s = zeros(size(objin.s));

%filter speed
sfilt = smoothdata(objin.s,'movmedian',51);

% determine when sliding occurs
sliding = (sfilt > 0.5);

% get sliding periods
sregions = regionprops(sliding,'PixelList');

% Check for speed changes using derivative and threshold
speedchanges = find(abs(diff(sfilt.*sliding)) > 1);
speedchangecheck = speedchanges(1);
k = 1;

%check to make sure there aren't too many close together and everything is
%spaced out nice
for i = 1:numel(speedchanges)-1
    if abs(speedchangecheck(k) - speedchanges(i+1)) > 30
                k = k + 1;
                speedchangecheck(k) = speedchanges(i+1);
    end
end

% Get start and end points for periods of sliding
n = numel(sregions);
j = 0;
for i = 1:n
    j = j+1;
    changepoints(j) = sregions(i).PixelList(1,2);
    j = j+1;
    changepoints(j) = sregions(i).PixelList(end,2);
end

% turn into start and end points
for i = 1:numel(changepoints)/2
    cpstart(i) = changepoints((i*2)-1);
    cpend(i) = changepoints((i*2));
end

% Determine if differential based speed changes are between sliding logical
k = 0;
for i = 1:numel(cpstart)
    k = k + 1;
    idx = find((speedchangecheck < cpend(i)-50) & (speedchangecheck > cpstart(i)+50));
    if isempty(idx) == 0
        objout.sstart(k) = cpstart(i);
        objout.send(k) = speedchangecheck(idx);
        k = k + 1;
        objout.sstart(k) = speedchangecheck(idx)+1;
        objout.send(k) = cpend(i);
    else
        objout.sstart(k) = cpstart(i);
        objout.send(k) = cpend(i);
    end
    
end

% Get speed for each sliding segment and get smooth speed curve
for i = 1:numel(objout.sstart)
    objout.speedseg(i) = mean(sfilt(objout.sstart(i)+1:objout.send(i)-1));
    objout.s(objout.sstart(i):objout.send(i)) = objout.speedseg(i);
end

%% Data Filtering 
% Filter normal force, friciton force,friction coefficient
objout.nf = smoothdata(objin.nf,'sgolay',31,'Degree',1);
objout.ff = smoothdata(objin.ff,'sgolay',31,'Degree',1);
objout.fc = smoothdata(objin.fc,'movmedian',7);

% Filter deformation and also strain if it has been calculated already
objout.d = sgolayfilt(objin.d,1,31);
if isempty(objin.st) == 0
        objout.st = sgolayfilt(objin.st,1,31);
end

end