function [metadata] = tribsegprocess(c,numfitpoints)

nseg = numel(c);

for i = 1:nseg
    % get metadata
    segnum(i,1) = i;
    time(i,1) = ((c{i}.t(end))./60);
    speed(i,1) = c{i}.speedseg;
    force(i,1) = round(c{i}.loadseg,1);
    ds(i,1) = c{i}.d(1);
    de(i,1) = c{i}.d(end);
    fcs(i,1) = c{i}.fc(1);
    fce(i,1) = c{i}.fc(end);
    intdef(i,1) = trapz(-1*c{i}.d);
    
%% Calculate filter size
    
    % Time interval
    tinterval = nanmean(c{i}.t(2:end) - c{i}.t(1:end-1));
    dataptspermin = 60/tinterval;
    dataptsperminodd = 2*floor(dataptspermin/2)+1;
    if numel(c{i}.d) < dataptsperminodd
        idx = 2*floor(numel(c{i}.d)/2)+1;
        if idx < dataptsperminodd
            deffiltsize = idx-2;
        else
            deffiltsize = idx;
        end
    else
        deffiltsize = dataptsperminodd;
    end
    if deffiltsize < 2;
        df = c{i}.d;
    else
        df = sgolayfilt(c{i}.d,2,deffiltsize);
    end
    %% Get points for calcultaing deformation slopes with linear regression 
    % make sure segments are long enough to have 5 data points
    if numel(df) > numfitpoints
    
        if c{i}.speedseg == 0
            y = -1*df(end-numfitpoints-1:end);
            x = c{i}.t(end-numfitpoints-1:end);
        elseif c{i}.speedseg > 0
            y = -1*df(1:numfitpoints);
            x = c{i}.t(1:numfitpoints);
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
    elseif c{i}.speedseg > 0
        y = -1*df;
        x = c{i}.t;
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
    
end
if nseg > 1
    for i = 2:nseg
        if (speed(i,1) > 0 & speed(i-1,1) == 0)
            rehydrate(i,1) = slope(i,1) - slope(i-1,1);
        else
            rehydrate(i,1) = 0;    
        end
    end
else
    rehydrate(1,1) = 0;
end
metadata = table(segnum,time,speed,force,ds,de,fcs,fce,intdef,slope,Rsq,rehydrate);

end
