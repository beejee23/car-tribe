function [datasegs,wholeregimen,segmentprofiles] = tribmatch(metadatain,tribsegcellarray,tstatic,tsliding,cycles,tpassive,speed,f_load,f_passive)
%% Takes the subset of the metadata for a specificed activity regimen
% Build activity profile from segment time and speed estimates
% datasegs provides the metadata for each segment in a regimen
% wholeregimen is the metadata over an entire regimen, specifically 
% integrated measurements of def,strain, fric

% All times should be in minutes
%
% Example: regimen name 30x1 = 30 cycles of 1 minute sliding each
% for 30 minutes sliding of 90 minute loaded period, 60 min passive rest
%
% tstatic = 2;
% tsliding = 1;
% tpassive = 60;
% cycles = 30;
% speed = 100;
% f_load = 5;
% f_passive = 0.1;

%%
% Get rid of erroneosly detected very short segments
% These could be due to a delay or such in the changing of the tribometer
% loading that is non-instantaneous and thus picked up by the code
% They will mess up the pattern detection

infilter = metadatain.segtime > .5;
metadata = metadatain(infilter,:);
d = tribsegcellarray([infilter > .5]);

% Creat experiment speed profile used to detect the activity regimen
speedprofile = [0;repmat([0;speed],[cycles,1,1]);0;0];

% Label each cycle of the activity regimen.  zero cycles are passive
cyclelabels = [1:cycles;1:cycles];
cyclenum = [cyclelabels(:);0]; % this could be edited to incorporate the extraneous segments back in

% check for matches with the speed profile
potentialindices = strfind(metadata.speed',speedprofile');

% logic to handle more than 1 match (usually the 1x30 is done 2-3 times)
if numel(potentialindices) > 1
    [~,ind2] = max(metadata.force(potentialindices+2));
    ind = potentialindices(ind2);
else
    ind = potentialindices;
end

% Determine start and end indices
numsegs = numel(speedprofile-3);
startind = ind+1;
endin = ind+numsegs-2;


% Get table of the metadata for each segment in the regimen
datasegs = metadata(startind:endin,:);
datasegs.cyclenum = cyclenum;
datasegs.cumsegtime = cumsum(datasegs.segtime);
datasegs = [datasegs(:,1:5),datasegs(:,end-1:end),datasegs(:,6:end-2)];

% Get the trib class object containing whole activity regimen
% Currently this exludes the short erronesouly segments mentioend earlier,
% but this could be adjusted in the future
segmentprofiles = tribsegcombine(d,[startind],[endin]);

% Calculate integrated and time averaged parameters but first check to make
% sure they exist
thcheck = ~isempty(segmentprofiles.th);
rcheck = ~isempty(segmentprofiles.r);
nfeqcheck = ~isempty(segmentprofiles.nfeq);
deqcheck = ~isempty(segmentprofiles.deq);
    
intdef = trapz(segmentprofiles.t,-1*segmentprofiles.d);
intfric = trapz(segmentprofiles.t,segmentprofiles.fc);
if thcheck == 1
    intst = trapz(segmentprofiles.t,-1*segmentprofiles.st);
else
    intst = nan;
end
if rcheck == 1
    intsh = trapz(segmentprofiles.t,segmentprofiles.sh);
    intcp = trapz(segmentprofiles.t,segmentprofiles.cp);
else
    intsh = nan;
    intcp = nan;
end

if (thcheck & rcheck & nfeqcheck & deqcheck) == 1
    intip = trapz(segmentprofiles.t,segmentprofiles.ip);
else
    intip = nan;
end

intdeftavg = intdef/(segmentprofiles.t(end)-segmentprofiles.t(1));
intfrictavg = intfric/(segmentprofiles.t(end)-segmentprofiles.t(1));
intsttavg = intst/(segmentprofiles.t(end)-segmentprofiles.t(1));
intshtavg = intsh/(segmentprofiles.t(end)-segmentprofiles.t(1));
intcptavg = intcp/(segmentprofiles.t(end)-segmentprofiles.t(1));
intiptavg = intip/(segmentprofiles.t(end)-segmentprofiles.t(1));

% Create table of these values
wholeregimen = table(intdef,intst,intfric,intdeftavg,intsttavg,intfrictavg);
end