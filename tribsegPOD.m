function [segments] = tribsegPOD(objin,objraw)
% Segment a portion of a tribology data file by giveing the start and end
% index of the input data tribology file

n = numel(objin.speedseg);

% Quick check for if the test was deformation only
if n < 1
    segments{1} = tribclip(objin,1,numel(objin.t));
    segments{1}.speedseg = 0;
    segments{1}.sstart = [];
    segments{1}.send = [];
else
    %% First seg
    % Find first sliding segment and check the deformation before that.
    % Use the defomration being less than zero as indicator of when the
    % experiment started.  Last time deformation was below zero should be
    % start of the experiment
    i = 1
    % only analyze data prior index of first time sliding
    firstslide = objin.sstart(1);
    
    % find indices when deformation was greater than zero
    %idx = find(diff(objin.d(1:firstslide) <= 0));
    idx = find(objin.d(1:firstslide) >= 0);
    
    if isempty(idx) == 1
        idx = 0;
    end
    % the last time def is greater than zero is beginning of experiment
    beginfirstdefseg = idx(end)+1;
    
    % end just before beginning of first sliding period
    endfirstdefseg = objin.sstart(1)-1;
    
    
    % check to see if there is an "unloaded" and "loaded" state using nf
    % assume 1 mins is the minimum time for a load or unload period if they
    % are combined into a longer stationary period
    [~,idx5minmin] = min(abs((objin.t-objin.t(1))/60 - 1));
    first0segnf = objin.nf(beginfirstdefseg:endfirstdefseg);
    countloaded = sum(first0segnf > 1);
    countunloaded = sum(first0segnf < 0.5);
    
    % start counter
    scount = 1;
    %if both periods are 5 mins long, split up
    if (countloaded > idx5minmin) & (countunloaded > idx5minmin)
        %find where load changes. load is clean so this is easy
        [~,midx] = max(diff(first0segnf));
        % First half
        segments{scount} = tribclip(objin,beginfirstdefseg,midx);
        segments{scount}.speedseg = 0;
        segments{scount}.sstart = [];
        segments{scount}.send = [];
        scount = scount + 1;
        
        % Second half
        segments{scount} = tribclip(objin,[midx+1],endfirstdefseg);
        segments{scount}.speedseg = 0;
        segments{scount}.sstart = [];
        segments{scount}.send = [];
        scount = scount + 1;
        
    else
        % use these start/end points to clip the data
        segments{scount} = tribclip(objin,beginfirstdefseg,endfirstdefseg);
        % set speed to 0
        segments{scount}.speedseg = 0;
        segments{scount}.sstart = [];
        segments{scount}.send = [];
        scount = scount + 1;
        
    end
    % Get the first speed segment
    segments{scount} = tribclip(objin,objin.sstart(1),objin.send(1));
    segments{scount}.speedseg = objin.speedseg(1);
    segments{scount}.sstart = segments{scount}.sstart(1);
    segments{scount}.send = segments{scount}.send(1);
    scount = scount + 1;
    
    
    
    %% Middle segs
    % check between all middle sliding segments for any rest periods
    if n >= 2
        for i = 2:n
            % Get spacing between the start and finish of neighbooring segments
            speedsedspacing  = objin.sstart(i) - objin.send(i-1);
            
            % If they are spaced out by more than 3 indices there is probably
            % something going on. This may need to be edited if the sampling rate
            % drastically changes for slow speed sliding
            if speedsedspacing > 3
                startdefseg = objin.send(i-1)+1; % start is end of previous + 1
                enddefseg = objin.sstart(i)-1; % end is start of current - 1
                
                
                
                %% Alternative
                expseg = tribclip(objin,startdefseg,enddefseg);
                [startendpts] = tribsegPOD_loadseg(expseg);
                
                for j = 1:size(startendpts,1)
                    segments{scount} = tribclip(expseg,startendpts(j,1),startendpts(j,2));
                    segments{scount}.speedseg = 0;
                    segments{scount}.sstart = [];
                    segments{scount}.send = [];
                    scount = scount + 1;
                    
                end
                %         %% check to see if there is an "unloaded" and "loaded" state using nf
                %         % assume 1 mins is the minimum time for a load or unload period if they
                %         % are combined into a longer stationary period
                %         [~,idx5minmin] = min(abs(objin.t/60 - 1));
                %         first0segnf = objin.nf(startdefseg:enddefseg);
                %         countloaded = sum(first0segnf > 1);
                %         countunloaded = sum(first0segnf < 0.5);
                %         %if both periods are 5 mins long, split up
                %         if (countloaded > idx5minmin) & (countunloaded > idx5minmin)
                %             %find where load changes. load is clean so this is easy
                %             [~,midx] = max(diff(first0segnf));
                %             midxadj = startdefseg + midx - 1;
                %             % First half
                %             segments{scount} = tribclip(objin,startdefseg,midxadj);
                %             segments{scount}.speedseg = 0;
                %             % Second half
                %             scount = scount + 1;
                %             segments{scount} = tribclip(objin,[midxadj+1],enddefseg);
                %             segments{scount}.speedseg = 0;
                %             scount = scount + 1;
                %
                %         else
                %             % use these start/end points to clip the data
                %             segments{scount} = tribclip(objin,startdefseg,enddefseg);
                %             % set speed to 0
                %             segments{scount}.speedseg = 0;
                %             % clip data using start/end points
                %             segments{scount} = tribclip(objin,startdefseg,enddefseg);
                %             % set speed to 0
                %             segments{scount}.speedseg = 0;
                %             scount = scount + 1;
                %         end
            end
            % put next segment in proper order
            segments{scount} = tribclip(objin,objin.sstart(i),objin.send(i));
            segments{scount}.speedseg = objin.speedseg(i);
            segments{scount}.sstart = segments{scount}.sstart(i);
            segments{scount}.send = segments{scount}.send(i);
            scount = scount + 1;
            
        end
        
    end
    %% Last Seg
    
    for i = n
        % only analyze data after last point of sliding
        lastslide = objin.send(i)+1;
        
        % segment out unloaded portion
        endofexp = tribclip(objin,lastslide,numel(objin.d));
        %
        %     % check nf for loading and unloading periods
        %     loaded = endofexp.nf > 0.5;
        %     unloaded = endofexp.nf < 0.5;
        %
        %     % assume one minute at least for a period to count as something signif
        %     timeperpoint = endofexp.t(2)/60;
        %     pointspermin = 1/timeperpoint;
        %     minnumidx = round(pointspermin);
        %
        %     % make sure there's no small region that doesn't mean anything. 1 min min
        %     loadedfilt = bwareaopen(loaded,minnumidx);
        %     unloadedfilt = bwareaopen(unloaded,minnumidx);
        %
        %     % Get pixel bounds of larger regions
        %     loadedregions = regionprops(loadedfilt,'PixelList');
        %     unloadedregions = regionprops(unloadedfilt,'PixelList');
        %
        %     if isempty(loadedregions) == 1
        %         loadedstartpts = [];
        %         loadedendpts = [];
        %     else
        %         for i = 1:numel(loadedregions)
        %             loadedstartpts(i) = loadedregions(i).PixelList(1,2);
        %             loadedendpts(i) = loadedregions(i).PixelList(end,2);
        %         end
        %     end
        %
        %     if isempty(unloadedregions) == 1
        %         unloadedstartpts = [];
        %         unloadedendpts = [];
        %     else
        %         for i = 1:numel(unloadedregions)
        %             unloadedstartpts(i) = unloadedregions(i).PixelList(1,2);
        %             unloadedendpts(i) = unloadedregions(i).PixelList(end,2);
        %         end
        %     end
        %     septs = sortrows([loadedstartpts',loadedendpts';unloadedstartpts',unloadedendpts']);
        
        if isempty(endofexp.t) == 0
            [septs] = tribsegPOD_loadseg(endofexp);
            
            for j = 1:size(septs,1)
                segments{scount} = tribclip(endofexp,septs(j,1),septs(j,2));
                segments{scount}.speedseg = 0;
                segments{scount}.sstart = [];
                segments{scount}.send = [];
                scount = scount + 1;
                
            end
        end
    end
end

%% Average Load in each segment

for i = 1:numel(segments)
    segments{i}.loadseg = mean(segments{i}.nf);

end




end