function [regimenmetadata] = tribmetasub(metadata,tstatic,tsliding,cycles,tpassive,speed)
%% Take subset of the metadata for a specificed activity regimen

% Build activity profile from segment time and speed estimates
% All times should be in minutes
%tstatic = 2;
%tsliding = 1;
%tpassive = 60;
%cycles = 30;
%speed = 100;

tdelay = 0.1; % small delay of static time just after last sliding cycle but prior to passive unloading period

% create time and speed sequence of the speficied activity regimen
segtimeprofile = [repmat([tstatic;tsliding],[cycles,1,1]);tdelay;tpassive];
speedprofile = [repmat([0;speed],[cycles,1,1]);0;0];
fulltestprofile = [segtimeprofile,speedprofile];
cyclelabels = [1:cycles;1:cycles];
cyclenum = [cyclelabels(:);0;0];
% subset of metadata to compare against
testdata = [metadata.segtime,metadata.speed];

% use cross correlation to find where the activity cycle matches
corrmat = normxcorr2(fulltestprofile,testdata)./3.0375e+05;
[value,indmax] = max(corrmat(:,2));
numsegs = size(fulltestprofile,1);
corr_offset = indmax - numsegs;

regimenmetadata = metadata(corr_offset+1:corr_offset+numsegs,:);
regimenmetadata.cyclenum = cyclenum;
regimenmetadata.cumsegtime = cumsum(regimenmetadata.segtime);
regimenmetadata = [regimenmetadata(:,1:5),regimenmetadata(:,23:24),regimenmetadata(:,6:22)];
end