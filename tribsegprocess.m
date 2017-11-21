function [metadata,cclean] = tribsegprocess(c,numfitpoints)
%% Caculates metadata and filters raw segments to yield cleaner data to plot

nsegcheck = numel(c);

for i = 1:nsegcheck
        blankcheck(i) = ~isempty(diff(c{i}.t));
end

c = c(blankcheck);
nseg = numel(c);

for i = 1:nseg
    %% Crop beginning of segment
    % This section eliminated points with a different sample rate located at
    % the beginning of a segment
    endindex = numel(c{i}.t);
    if i > 1
        sampratediff = (diff(c{i}.t));
        m = mean(sampratediff,'omitnan');
        ms = m+std(sampratediff,'omitnan');
        sampratecheck = sampratediff > ms;
        timecheck = c{i}.t(2:end).*[sampratecheck];
        % use time check to see which sample rate was used for more time
        if sampratecheck(1) == 1
            bwcc = bwconncomp(sampratecheck);
            startindex = bwcc.PixelIdxList{1}(end)+1;
        else
            startindex = 1;
        end
        cclipped{i} = tribclip(c{i},startindex,endindex);
    else
        cclipped{i} = tribclip(c{i},1,endindex);
    end
    
    %% Crop end of segment
    
    
    drate = abs(diff(cclipped{i}.d)./diff(cclipped{i}.t));
    m = mean(drate,'omitnan');
    s = std(drate,'omitnan');
    v = var(drate,'omitnan');
    
    TF = isoutlier(drate);
    TFcheck = bwconncomp(TF);
    
    if TFcheck.NumObjects > 0
        if isempty(find(TFcheck.PixelIdxList{end} == numel(TF))) == 0;
            endcut = TFcheck.PixelIdxList{end}(1) - 1;
            cclipped2{i} = tribclip(cclipped{i},1,endcut);
        else
            cclipped2{i} = cclipped{i};
        end
    else
        cclipped2{i} = cclipped{i};
    end
    
    drplot = plot(cclipped2{i}.t,cclipped2{i}.d,'-o');
    
    
    
    %% Calculate filter size
    % Time interval between data points
    tinterval = nanmean(cclipped2{i}.t(2:end) - cclipped2{i}.t(1:end-1));
    dataptspermin = 60/tinterval;
    dataptsperminodd = 2*floor(dataptspermin/2)+1;
    if numel(cclipped2{i}.d) < dataptsperminodd
        idx = 2*floor(numel(cclipped2{i}.d)/2)+1;
        if idx <= dataptsperminodd
            deffiltsize = idx-2;
        else
            deffiltsize = idx;
        end
    else
        deffiltsize = dataptsperminodd;
    end
    if deffiltsize < 2;
        df = cclipped2{i}.d;
        fcf = cclipped2{i}.fc;
    else
        df = sgolayfilt(cclipped2{i}.d,2,deffiltsize);
        fcf = sgolayfilt(cclipped2{i}.fc,2,deffiltsize);
    end
    %% Get points for calculating deformation slopes with linear regression
    
    
    if numel(df) > numfitpoints
        
        if cclipped2{i}.speedseg == 0
            y = -1*df(end-numfitpoints-1:end);
            x = cclipped2{i}.t(end-numfitpoints-1:end);
        elseif cclipped2{i}.speedseg > 0
            y = -1*df(1:numfitpoints);
            x = cclipped2{i}.t(1:numfitpoints);
        else
            y = NaN;
            x = NaN;
        end
        
        % Linear regression
        p = polyfit(x,y,1);
        yfit = polyval(p,x);
        yfit =  p(1) * x + p(2);
        yresid = y - yfit;
        SSresid = sum(yresid.^2);
        SStotal = (length(y)-1) * var(y);
        Rsq(i,1) = 1 - SSresid/SStotal;
        slope(i,1) = -1*p(1);
    elseif cclipped2{i}.speedseg > 0
        y = -1*df;
        x = cclipped2{i}.t;
        p = polyfit(x,y,1);
        yfit = polyval(p,x);
        yfit =  p(1) * x + p(2);
        yresid = y - yfit;
        SSresid = sum(yresid.^2);
        SStotal = (length(y)-1) * var(y);
        Rsq(i,1) = 1 - SSresid/SStotal;
        
        slope(i,1) = -1*p(1);
    else
        slope(i,1) = NaN;
        Rsq(i,1) = NaN;
    end
    close all
    
    %% Get metadata from newly filtered data
    
    % get metadata
    segnum(i,1) = i;
    exptime(i,1) = ((cclipped2{i}.t(end))./60);
    speed(i,1) = cclipped2{i}.speedseg;
    force(i,1) = round(cclipped2{i}.loadseg,1);
    
    %     ds(i,1) = cclipped2{i}.d(1);
    %     de(i,1) = cclipped2{i}.d(end);
    %     fcs(i,1) = cclipped2{i}.fc(1);
    %     fce(i,1) = cclipped2{i}.fc(end);
    
    ds(i,1) = df(1);
    de(i,1) = df(end);
    fcs(i,1) = fcf(1);
    fce(i,1) = fcf(end);
    
    intdef(i,1) = trapz(-1*df);
    cclipped2{i}.d = df;
    cclipped2{i}.fc = fcf;
    
end

if nseg > 1
    for i = 2:nseg
        segtime(i,1) = exptime(i,1)-exptime(i-1,1);
        if (speed(i,1) > 0 & speed(i-1,1) == 0)
            rehydrate(i,1) = slope(i,1) - slope(i-1,1);
        else
            rehydrate(i,1) = 0;
        end
    end
else
    rehydrate(1,1) = 0;
end
metadata = table(segnum,exptime,segtime,speed,force,ds,de,fcs,fce,intdef,slope,Rsq,rehydrate);

% Get cleaned seg structure
[cclean] = tribsegcombine(cclipped2,1,numel(c));
    
end
