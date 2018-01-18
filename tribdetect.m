function [objout]= tribdetect(objin)
%% Identify speed changes and clean speed data to make plotting smoother
% This function employs two methods to detect speed changes both of a
% stop-start nature, and speed changes between two steady non-zero speeds.
% The results from the two methods are compared and yield a list of points
% that can be used to break up an experiment into segments based on speed.

% Transfer data to new class instance
objout = tribclip(objin,1,numel(objin.t));

% clear data that will be replaced
objout.s = [];

% Pre-allocate speed array;
objout.s = zeros(size(objin.s));

%% Indentify periods of sliding

%filter speed
sfilt = smoothdata(objin.s,'movmedian',51);

% Use 0.5 mm/s speed threshold to determine when sliding occurs
slidinginitial = (objin.s > 0.5);

% Remove any blips, "sliding periods" lasting fewer than 3 data points"
slidingnoblips = bwareaopen(slidinginitial,3);

% Fill tiny gaps, sections in the middle of sliding where data collection
% dropped for some reason
sliding = imclose(slidingnoblips,strel([1 1 1 1 1]'));

% Segment periods of sliding into distinct groups
speriods = regionprops(sliding,'PixelList');

%% Check for speed changes using derivative and threshold
% speriods only contains periods that go from rest to sliding to rest
% If there is a speed increase or decrease from non-zero to non-zero values
% then it will be missed.  Thus we use the change in speed over change in
% time --- delta(speed)/delta(time)
speedtimediff = abs(diff(sfilt.*sliding)./diff(objin.t));

% Theshold for speedtimediff to count as a n-z to n-z speed change
speedtimediffthresh = 0.01;

% Indices of potential speed changes detected usign threshold methods
potentialspeedchanges = find(speedtimediff > speedtimediffthresh);

% Exception for if potentialspeedchanges is empty.  This would mean a
% deformation test was performed on the tribometer without any sliding
if isempty(potentialspeedchanges) == 1
    objout.speedseg = 0;
    objout.s(1:numel(objin.s)) = 0;
    objout.sstart = [];
    objout.send = [];

% This section deals with the speed change detection. A given speed change
% may result in a series of data points where speedtimediff is greater than
% the threshold, so we need to determine which of these is the best choice
% for where the speed change occured
else
    % k is our counter for valid speed changes. When a new speed changes is
    % confirmed by meeting the necessary criteria, the speed change is
    % added to the list at index 'k' and k increases by 1.
    
    % Initialize k and load the first potentialspeedchanges to the
    % speedchangecheck array
    m = 1;
    nzspeedchange = potentialspeedchanges(1);

    % Check to make sure there aren't too potential speed changes close
    % toegther by comparing the timestamp for the indices of each
    % consecutive pairing of potential speed changes.
    % Loop through the consectuive pairings
    for i = 1:numel(potentialspeedchanges)-1
        consecpairtimediff = abs(objin.t(nzspeedchange(m)) - objin.t(potentialspeedchanges(i+1)));
        consecpairtimediffthresh = 30; % 30 seconds difference
        % Compare with threshold
        if consecpairtimediff > consecpairtimediffthresh
            % Increase counter and load next value to check
            m = m + 1;
            nzspeedchange(m) = potentialspeedchanges(i+1);
        end
    end
    
    %% Compare n-z to n-z (nz) speed changes with zero to n-z (z) changes
    % The speedtimediff-based method should also pick up the z to n-z
    % changes.  This may seem redudant but depending on sample rates and
    % speeds, there could be some mismatches for n-z to zero changes. They
    % might also be off by an index or two.  The the speed changes from the
    % two methods are compared to remedy any redundancy and get a complete
    % listing of speed changes
    
    % First we need to get the list of nz to zero speed change indices.
    % These are the start and end indices of the sliding periods
    numsp = numel(speriods);
    
    % initialize the counter j for creating the list of z2z type changes
    j = 0;
    for i = 1:numsp
        j = j+1;
        zchangestart(j) = speriods(i).PixelList(1,2);
        zchangeend(j) = speriods(i).PixelList(end,2);
    end
    
    % initialize the counter m for the final speed change list created by
    % comparing z and nz speedchanges
    m = 0;
    for i = 1:numel(zchangestart)
        m = m + 1;
        % nz speed changes also include some z changes, but they might
        % differ by a couple indices due to the difference detection
        % methods, depending on the sampling rate and speeds.  Thus we add
        % a buffer that will make sure nz changes really close to z changes
        % are considered already found by the z cahnge method.  Any thing
        % far enough away from the z change points will be considered an nz
        % speed change
        timebuffer = 10; %10 seconds
        lessthan2zend = objin.t(nzspeedchange) < (objin.t(zchangeend(i)) - timebuffer);
        greatthann2zstart = objin.t(nzspeedchange) > (objin.t(zchangestart(i)) + timebuffer);
        
        % index of the points between z changes (nz change present)
        pointsbetween = find((lessthan2zend) & (greatthann2zstart));
        if isempty(pointsbetween) == 0
            % add start point for z change
            objout.sstart(m) = zchangestart(i);
            % add end point at nz change
            objout.send(m) = nzspeedchange(pointsbetween);
            %counter to move to next point
            m = m + 1;
            % add start point at nz change
            objout.sstart(m) = nzspeedchange(pointsbetween)+1;
            % add end point for z change
            objout.send(m) = zchangeend(i);
        else
            % add start and end points z change start and end points
            objout.sstart(m) = zchangestart(i);
            objout.send(m) = zchangeend(i);
        end
        
    end
    
    %% Get speed for each sliding segment and export smooth speed curve
    for i = 1:numel(objout.sstart)
        % average sliding speed for each start and end point pair
        objout.speedseg(i) = mean(sfilt(objout.sstart(i)+1:objout.send(i)-1));
        % set speed to constant values during sliding to make plots nice
        objout.s(objout.sstart(i):objout.send(i)) = objout.speedseg(i);
    end
end

end