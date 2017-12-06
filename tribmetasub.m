function [datasegs,wholeregimen,segmentprofiles] = tribmetasub(metadatain,tribsegcellarray,tstatic,tsliding,cycles,tpassive,speed,f_load,f_passive)
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
datasegs = [datasegs(:,1:5),datasegs(:,28:29),datasegs(:,6:27)];

% Get the trib class object containing whole activity regimen
% Currently this exludes the short erronesouly segments mentioend earlier,
% but this could be adjusted in the future
segmentprofiles = tribsegcombine(d,[startind],[endin]);

% Calculate integrated and time averaged deformation, strain, friction
intdef = trapz(segmentprofiles.t,-1*segmentprofiles.d);
intst = trapz(segmentprofiles.t,-1*segmentprofiles.st);
intfric = trapz(segmentprofiles.t,segmentprofiles.fc);
intdeftavg = intdef/(segmentprofiles.t(end)-segmentprofiles.t(1));
intsttavg = intst/(segmentprofiles.t(end)-segmentprofiles.t(1));
intfrictavg = intfric/(segmentprofiles.t(end)-segmentprofiles.t(1));

% Create table of these values
wholeregimen = table(intdef,intst,intfric,intdeftavg,intsttavg,intfrictavg);
end