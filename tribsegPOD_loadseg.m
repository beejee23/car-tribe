function [startendpts] = tribsegPOD_loadseg(staticsegment)
    % Evaluates static phase, using normal force to differentiate between
    % unloaded and loaded experiment segments
    
    % check nf for loading and unloading periods
    loaded = staticsegment.nf > 0.5;
    unloaded = staticsegment.nf < 0.5;
    
    % assume one minute at least for a period to count as something signif
    if numel(staticsegment.t) < 2
        loadedstartpts = [];
        loadedendpts = [];
        unloadedstartpts = [];
        unloadedendpts = [];
    else
        
        timeperpoint = staticsegment.t(2)/60;
        pointspermin = 1/timeperpoint;
        minnumidx = round(pointspermin);
        
        % make sure there's no small region that doesn't mean anything. 1 min min
        loadedfilt = bwareaopen(loaded,minnumidx);
        unloadedfilt = bwareaopen(unloaded,minnumidx);
        
        % Get pixel bounds of larger regions
        loadedregions = regionprops(loadedfilt,'PixelList');
        unloadedregions = regionprops(unloadedfilt,'PixelList');
        
        if isempty(loadedregions) == 1
            loadedstartpts = [];
            loadedendpts = [];
        else
            for i = 1:numel(loadedregions)
                loadedstartpts(i) = loadedregions(i).PixelList(1,2);
                loadedendpts(i) = loadedregions(i).PixelList(end,2);
            end
        end
        
        if isempty(unloadedregions) == 1
            unloadedstartpts = [];
            unloadedendpts = [];
        else
            for i = 1:numel(unloadedregions)
                unloadedstartpts(i) = unloadedregions(i).PixelList(1,2);
                unloadedendpts(i) = unloadedregions(i).PixelList(end,2);
            end
        end
    end
    startendpts = sortrows([loadedstartpts',loadedendpts';unloadedstartpts',unloadedendpts']);
    
end