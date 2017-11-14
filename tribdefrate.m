function [rate,rsq,speed] = tribdefrate(segcells)
% input cell array of trib classes representing each segment of the
% experiment

n = numel(segcells);


% for i = 1:n
%     figure
%     yyaxis left
%     plot(segcells{i}.t,segcells{i}.d);
%     yyaxis right
%     hold on
%     defdiff = abs(diff(segcells{i}.d));
%     plot(segcells{i}.t(2:end),defdiff);
%     yyaxis right
%     defdiffstd = 3*std(defdiff);
%     plot(segcells{i}.t(2:end),ones(size(defdiff)).*defdiffstd);
%     close all
% end

for i = 1:n
    % if sliding, analyze beginning of seg
    if (segcells{i}.speedseg > 0) == 1
        
        % First determine the sampling frequency
        fs = 1/(segcells{i}.t(2)-segcells{i}.t(1));
        
        % Use difference between signal and mean signal to accentuate
        % deviations from the signal
        deviation = segcells{i}.d - mean(segcells{i}.d);
        
        % Autocorrelate signal
        [autocor,lags] = xcorr(deviation,round(100*fs),'coeff');
        
        % Find average "short" correlation peaks
        [pksh,lcsh] = findpeaks(autocor);
        
        if numel(pksh) < 2
            deffilt = segcells{i}.d;
            
        else
            short = mean(diff(lcsh))/fs;
            
            % Find average "long" correlation peaks
            [pklg,lclg] = findpeaks(autocor, ...
                'MinPeakDistance',ceil(short)*fs,'MinPeakheight',0.3,...
                'MinPeakProminence',.05);
            long = mean(diff(lclg))/fs;
            
            % Get frequency of oscillation from peak
            if isnan(long) == 1
                ftrib = 1/short;
                
            else
                ftrib = 1/long;
            end
        end
        % select filter size
        mfiltsize = round(((fs/ftrib)-1)/2)*2+1;
        %filter signal
        deffilt =  sgolayfilt(-1*segcells{i}.d,1,mfiltsize*5);
        
        
        % check if there are large devations in signal do to bad segmentign
        % or jumps due to sliding
        defdeviation = abs(-1*segcells{i}.d - deffilt);
        stdthresh = 3*std(defdeviation);
        devcheck = find(defdeviation > stdthresh);
        % jumps usually take place in the first couple transition points so
        % cut the first five points off and refilter
        if isempty(devcheck) == 0
            deffilt =  sgolayfilt(-1*segcells{i}.d(6:end),1,mfiltsize*5);
        end
        
%         figure
%         hold on
%         plot(-1*segcells{i}.d)
%         plot(deffilt,'LineWidth',3)
%         %xlim([0,200])
%         title(num2str(segcells{i}.speedseg));
%         hold off
%         legend('raw','sgolay')
%         %close all      


        time = segcells{i}.t(1:50);
        def = deffilt(1:50);
        lm = fitlm(time,def,'linear');
        rate(i) = lm.Coefficients.Estimate(2);
        rsq(i) = lm.Rsquared.Ordinary;
        speed(i) = segcells{i}.speedseg;    
        %plot(lm)
        %hold on
        %plot(-1*segcells{i}.d(1:200))
        %title(num2str(speed(i)));
        close all
        
    % if static, analyze end of seg
    else
        % Check deformation derivation for large change due to initiating
        % sliding 
        defdiff = abs(diff(segcells{i}.d));
        % 3 times the std of the derivative is the threshold
        defdiffstdthresh = 3*std(defdiff);
        % check last 60 seconds for a jump, first find the index of the
        % point 60 seconds away from segment end
        [val,idx] = min(abs(segcells{i}.t - (segcells{i}.t(end)-60)));
        % Check for jump in the last 60 seconds
        jumpcheck = find(defdiff(idx:end) >= defdiffstdthresh);
        if isempty(jumpcheck) == 0
            % first jump in last 60 is new end point for fitting
            fitendpoint = idx+jumpcheck(1) - 1;
        else
            % otherwise normal last point remains the same
            fitendpoint = numel(segcells{i}.d);
        end
        
        %length of fit subset
        fitsubsetlength = 50;
        fitstartpoint = fitendpoint - fitsubsetlength + 1;
        time = segcells{i}.t(fitstartpoint:fitendpoint);
        def = segcells{i}.d(fitstartpoint:fitendpoint);
        lm = fitlm(time,-1*def,'linear');
        rate(i) = lm.Coefficients.Estimate(2);
        rsq(i) = lm.Rsquared.Ordinary;
        speed(i) = segcells{i}.speedseg;
        %plot(lm)
        %pause(1)
    end
    
end

end