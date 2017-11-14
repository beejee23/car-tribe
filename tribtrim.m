function [objout] = tribtrim(objin)
% Trims data assuming you properly zeroed everything prior to starting the
% experiment


% Experiment is running hwere deformation is less than zero and force is at
% least greater than 2.  This could be changed for low low experiments but
% we don't typically go that low.
exp_log = ((objin.d<0) & (objin.nf>0));

% If experiment files include multiple unloading periods, we can edit this
% section here to pull out different experiment segments
largestportion = bwareafilt(exp_log,1);

% Find where largestportion is not zero
idx = find(largestportion);

% First and last indices are the start and end points
sidx = idx(1);
eidx = idx(end);

% Adjust end point to get rid of data after sample is unloaded
% search the second half of test for unloading by searchign teh derivatives
% or force and displacement for peaks
startsearchwindow = round(eidx/2);
ddiff = abs(diff(objin.d(startsearchwindow:eidx)));
fdiff = abs(diff(objin.nf(startsearchwindow:eidx)));
dstd = std(ddiff);
fstd = std(fdiff);

[dpks, dlocs] = findpeaks(ddiff,'MinPeakHeight',3*dstd);
[fpks,flocs] = findpeaks(fdiff,'MinPeakHeight',3*fstd);

ploc = min([dlocs;flocs]);
%Adjust for using half the data and add a couple point buffer
new_eidx = ploc + startsearchwindow - 10;

objout = tribseg(objin,sidx,new_eidx);


end