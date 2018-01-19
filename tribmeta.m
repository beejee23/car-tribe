function [metadata,validsegments] = tribmeta(segments,varargin)
%% Calculates metadata and filters raw segments to yield cleaner data to plot
% Optional Name-Pair arguements
% 
% 'time' followed by number of seconds of data that you want to fit to get
% the slopes for the rehydration rate calculation
%
% 'points' followed by the number of data that you want to fit to get
% the slopes for the rehydration rate calculation. 
%
% Examples: tribsegprocess(c,'time',50) Take 50 seconds before and after
% starting sliding
%
% Examples: tribsegprocess(c,'points',10) Take 10 data points before and after
% starting sliding
%
% I ran a convergence study because I noticed that the rehydration rate
% varied greatly depending on the number of points used to calculate the
% slopes.  I found that after 25 seconds worth of points or more, the
% value for rehydration rate converged.  Thus, the default for this
% funciton is to fit 25 seconds of data before and after starting sliding
%
%
if nargin == 3  
    switch varargin{1} 
        case 'time'
            fittime = varargin{2};
            fitpoints = 0;
        case 'points'
            fittime = 0;
            fitpoints = varargin{2};
    end    
else
    fittime = 25; % seconds.  Rehydration rate calc converges here based on intermittent solute paper tribology data.
    fitpoints = 0;
end

nsegcheck = numel(segments);

for i = 1:nsegcheck
        blankcheck(i) = ~isempty(diff(segments{i}.t));
end

segments = segments(blankcheck);
nseg = numel(segments);

for i = 1:nseg
    %% Crop beginning of segment
    % This section eliminated points with a different sample rate located at
    % the beginning of a segment
    endindex = numel(segments{i}.t);
    if i > 1
        sampratediff = (diff(segments{i}.t));
        m = mean(sampratediff,'omitnan');
        ms = m+std(sampratediff,'omitnan');
        sampratecheck = sampratediff > ms;
        timecheck = segments{i}.t(2:end).*[sampratecheck];
        % use time check to see which sample rate was used for more time
        if sampratecheck(1) == 1
            bwcc = bwconncomp(sampratecheck);
            startindex = bwcc.PixelIdxList{1}(end)+1;
        else
            startindex = 1;
        end
        cclipped{i} = tribclip(segments{i},startindex,endindex);
    else
        cclipped{i} = tribclip(segments{i},1,endindex);
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
            validsegments{i} = tribclip(cclipped{i},1,endcut);
        else
            validsegments{i} = cclipped{i};
        end
    else
        validsegments{i} = cclipped{i};
    end
    
    %drplot = plot(cclipped2{i}.t,cclipped2{i}.d,'-o');
    
    
    
    %% Calculate filter size
    % Time interval between data points
    tinterval = nanmean(validsegments{i}.t(2:end) - validsegments{i}.t(1:end-1));
    dataptspermin = 60/tinterval;
    dataptsperminodd = 2*floor(dataptspermin/2)+1;
    if numel(validsegments{i}.d) < dataptsperminodd
        idx = 2*floor(numel(validsegments{i}.d)/2)+1;
        if idx <= dataptsperminodd
            deffiltsize = idx-2;
        else
            deffiltsize = idx;
        end
    else
        deffiltsize = dataptsperminodd;
    end
    if deffiltsize < 2;
        df = validsegments{i}.d;
    else
        df = sgolayfilt(validsegments{i}.d,2,deffiltsize);
    end
    
    %% Get points for calculating deformation slopes with linear regression
    
    if fitpoints == 0
        numfitpoints = ceil(fittime/tinterval);
    elseif fittime == 0
        numfitpoints = fitpoints;
    end
    
    if numel(df) > numfitpoints
        
        if validsegments{i}.speedseg == 0
            y = -1*df(end-numfitpoints-1:end);
            x = validsegments{i}.t(end-numfitpoints-1:end);
        elseif validsegments{i}.speedseg > 0
            y = -1*df(1:numfitpoints);
            x = validsegments{i}.t(1:numfitpoints);
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
        nanch = isnan(slope(i,1));
        %i
    elseif validsegments{i}.speedseg > 0
        y = -1*df;
        x = validsegments{i}.t;
        p = polyfit(x,y,1);
        yfit = polyval(p,x);
        yfit =  p(1) * x + p(2);
        yresid = y - yfit;
        SSresid = sum(yresid.^2);
        SStotal = (length(y)-1) * var(y);
        Rsq(i,1) = 1 - SSresid/SStotal;
        slope(i,1) = -1*p(1);
        nanch = isnan(slope(i,1));
        %i
    else
        slope(i,1) = NaN;
        Rsq(i,1) = NaN;
        nanch = isnan(slope(i,1));
        %i
    end
    close all
    
    %% Get metadata from newly filtered data
    
    % get metadata
    segnum(i,1) = i;
    exptime(i,1) = ((validsegments{i}.t(end))./60);
    speed(i,1) = validsegments{i}.speedseg;
    force(i,1) = round(validsegments{i}.loadseg,1);
    
    %     ds(i,1) = cclipped2{i}.d(1);
    %     de(i,1) = cclipped2{i}.d(end);
    %     fcs(i,1) = cclipped2{i}.fc(1);
    %     fce(i,1) = cclipped2{i}.fc(end);
    
    ds(i,1) = df(1);
    de(i,1) = df(end);
    dmin(i,1) = min(df);
    dmax(i,1) = max(df);
    % Friction response is not handled well by this filter
    fcs(i,1) = validsegments{i}.fc(1);
    fce(i,1) = validsegments{i}.fc(end);
    fcmin(i,1) = min(validsegments{i}.fc);
    fcmax(i,1) = max(validsegments{i}.fc);
    
    %check for calculated parameters
    thcheck = ~isempty(validsegments{i}.th);
    rcheck = ~isempty(validsegments{i}.r);
    nfeqcheck = ~isempty(validsegments{i}.nfeq);
    deqcheck = ~isempty(validsegments{i}.deq);
    
    % thickness-based parameters
    if thcheck == 1
        sts(i,1) = ds(i,1)/segments{i}.th;
        ste(i,1) = de(i,1)/segments{i}.th;
        stmin(i,1) = dmin(i,1)/segments{i}.th;
        stmax(i,1) = dmax(i,1)/segments{i}.th;
    else
        sts(i,1) = ds(i,1)/nan;
        ste(i,1) = de(i,1)/nan;
        stmin(i,1) = dmin(i,1)/nan;
        stmax(i,1) = dmax(i,1)/nan;
    end
    
    % radius-based parameters
    if rcheck == 1
        as(i,1) = sqrt(2.*validsegments{i}.r.*-1.*(df(1)./1000)); 
        ae(i,1) = sqrt(2.*validsegments{i}.r.*-1.*(df(end)./1000));
        cas(i,1) = 3.141593.*as(i,1).^2;
        cae(i,1) = 3.141593.*ae(i,1).^2;
        shs(i,1) = validsegments{i}.ff(1)./cas(i,1);
        she(i,1) = validsegments{i}.ff(end)./cae(i,1);
        cps(i,1) = validsegments{i}.nf(1)./cas(i,1);
        cpe(i,1) = validsegments{i}.nf(end)./cae(i,1);
        
    else
        as(i,1) = nan;
        ae(i,1) = nan;
        cas(i,1) = nan;
        cae(i,1) = nan;
        shs(i,1) = nan;
        she(i,1) = nan;
        cps(i,1) = nan;
        cpe(i,1) = nan;
    end
    
    % equilibrium modulus based parameters
    if (thcheck & rcheck & nfeqcheck & deqcheck) == 1
        eefs(i,1) = (validsegments{i}.nf(1).*segments{i}.th)./...
            (2.*3.141593.*validsegments{i}.r.*((-1.*df(1))./1000).^2);
        eefe(i,1) = (validsegments{i}.nf(end).*segments{i}.th)./...
            (2.*3.141593.*validsegments{i}.r.*((-1.*df(end))./1000).^2);
        ips(i,1) = (validsegments{i}.eef(1)-segments{i}.eeq).*((-1.*df(1))./segments{i}.th)./1000;
        ipe(i,1) = (validsegments{i}.eef(end)-segments{i}.eeq).*((-1.*df(end))./segments{i}.th)./1000;
        fls(i,1) = (eefs(i,1)-segments{i}.eeq)./eefs(i,1);
        fle(i,1) = (eefe(i,1)-segments{i}.eeq)./eefe(i,1);        
    else 
        eefs(i,1) = nan;
        eefe(i,1) = nan;
        ips(i,1) = nan;
        ipe(i,1) = nan;
        fls(i,1) = nan;
        fle(i,1) = nan;
    end
    
    
    % integrated parameters
    intdef(i,1) = trapz(validsegments{i}.t,-1*df);
    intfric(i,1) = trapz(validsegments{i}.t,validsegments{i}.fc);
    validsegments{i}.d = df; % add smoothed version back into code
    
    % thickness-based integrated parameters 
    if thcheck == 1
        intst(i,1) = trapz(validsegments{i}.t,-1*df)/segments{i}.th;
        validsegments{i}.st = (validsegments{i}.d)./segments{i}.th;
    else
        intst(i,1) = trapz(validsegments{i}.t,-1*df)/nan;
        validsegments{i}.st = (validsegments{i}.d)./nan;
    end
    
    % radius based integrated parameters
    if rcheck == 1
        intsh(i,1) = trapz(validsegments{i}.t,validsegments{i}.sh);
        intcp(i,1) = trapz(validsegments{i}.t,validsegments{i}.cp);
    else
        intsh(i,1) = nan;
        intcp(i,1) = nan;
    end
    
    % equilibrium modulus-based integrated parameters
    if (thcheck & rcheck & nfeqcheck & deqcheck) == 1
        intip(i,1) = trapz(validsegments{i}.t,validsegments{i}.ip);
    else
        intip(i,1) = nan;
    end
end

if nseg > 1
    for i = 2:nseg
        fname{i,1} = segments{i}.filename;
        segtime(i,1) = exptime(i,1)-exptime(i-1,1);
        if (speed(i,1) > 0 & speed(i-1,1) == 0)
            rehydrate(i,1) = slope(i,1) - slope(i-1,1);
        else
            rehydrate(i,1) = 0;
        end
    end
else
    rehydrate(1,1) = 0;
    fname{1,1} = segments{i}.filename;
    segtime = exptime;
end

    

intdeftavg = intdef./segtime;
intsttavg = intst./segtime;
intfrictavg = intfric./segtime;
intshavg = intsh./segtime;
intcptavg = intcp./segtime;
intiptavg = intip./segtime;

metadata = table(fname,segnum,exptime,segtime,speed,force,ds,de,dmin,dmax,...
    sts,ste,stmin,stmax,fcs,fce,fcmin,fcmax,...
    as,ae,cas,cae,shs,she,cps,cpe,eefs,eefe,ips,ipe,fls,fle,...
    intdef,intst,intfric,intsh,intcp,intip,...
    intdeftavg,intsttavg,intfrictavg,intshavg,intcptavg,intiptavg,...
    slope,Rsq,rehydrate);

end
