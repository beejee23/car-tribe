function [segments] = tribseg(objin,objraw)
% Segment a portion of a tribology data file by giveing the start and end
% index of the input data tribology file

n = numel(objin.speedseg);

% Quick check for if the test was deformation only
if n < 2
    segments{1} = tribclip(objraw,1,numel(objin.t));
    segments{1}.speedseg = 0;
else
    %% First seg
    % Find first sliding segment and check the deformation before that.
    % Use the deformation being less than zero as indicator of when the
    % experiment started.  Last time deformation was below zero should be
    % start of the experiment
    for i = 1
        % only analyze data prior index of first time sliding
        firstslide = objin.sstart(1);
        
        % find indexs when deformation was greater than zero
        idx = find(diff(objin.d(1:firstslide) <= 0));
        
        % the last time def is greater than zero is beginning of experiment
        beginfirstdefseg = idx(end)+1;
        
        % end just before beginning of first sliding period
        endfirstdefseg = objin.sstart(1)-1;
        
        % use these start/end points to clip the data
        segments{1} = tribclip(objraw,beginfirstdefseg,endfirstdefseg);
        
        % set speed to 0
        segments{1}.speedseg = 0;
        
        % Get the first speed segment
        segments{2} = tribclip(objraw,objin.sstart(1),objin.send(1));
        segments{2}.speedseg = objin.speedseg(1);
        
    end
    
    %% Middle segs
    scount = 3;
    % check between all middle sliding segments for any rest periods
    for i = 2:n
        
        % Get spacing between the start and finish of neighbooring segments
        speedsedspacing  = objin.sstart(i) - objin.send(i-1);
        
        % If they are spaced out by more than 3 indices there is probably
        % something going on. This may need to be edited if the sampling rate
        % drastically changes for slow speed sliding
        if speedsedspacing > 3
            startdefseg = objin.send(i-1)+1; % start is end of previous + 1
            enddefseg = objin.sstart(i)-1; % end is start of current - 1
            % clip data using start/end points
            segments{scount} = tribclip(objraw,startdefseg,enddefseg);
            % set speed to 0
            segments{scount}.speedseg = 0;
            scount = scount + 1;
        end
        
        % put next segment in proper order
        segments{scount} = tribclip(objraw,objin.sstart(i),objin.send(i));
        segments{scount}.speedseg = objin.speedseg(i);
        scount = scount + 1;
    end
    
    %% Last Seg
    
    for i = n
        % only analyze data after last point of sliding
        lastslide = objin.send(i)+1;
        
        % find indices when deformation was greater than zero
        endofexp = tribclip(objin,lastslide,numel(objin.d));
        
        %check how long compression last after last sliding period
        timeincompression = endofexp.t(endofexp.d < 0);
        
        % If it last more than 4 minutes, this is a deformation segment
        if max(timeincompression) > 240
            % advance counter
            scount = scount + 1;
            
            % get end of compression epriod index
            lastcompindex = find(endofexp.t == timeincompression(end))+objin.send(i)+1;
            
            % fill out last block
            segments{scount} = tribclip(objraw,objin.send(i)+1,lastcompindex-1);
            segments{scount}.speedseg = 0;
            
            
        end
        
        
    end
    
end





end