function [defadj,fc] = cleanTRIBdata(filename,defjumpcutoff,forcejumpcutoff,timemins,deformationum,normalforceN,frictioncoefficient)
% Clean tribology data based on several keuy assumptions and inputs.  Gets
% rid of teh elastic deformation of the cantilever leavign only flow
% deformation
%

% Sliding never occurs when there is no loading in most experiments.  In
% this case, the normal force should be high when sliding is occuring so we
% set all friction valeus to 0 when the normal force is less than 1 N
forcelogical = normalforceN > 1;
fc = forcelogical.*frictioncoefficient;

% Get regions for shading
% Criteria is friction greater than 0 for long periods of sliding and less
% than 1 in case there are some erroneous calculations
frictionlogical = fc > 0 & fc <1;

% Check for big deformation jumps
defdiff = diff(deformationum)./diff(timemins);
forcediff = diff(normalforceN)./diff(timemins);

jumps = ((abs(defdiff) > defjumpcutoff) | (abs(forcediff) > forcejumpcutoff)) > 0;
defadj = deformationum;
adjpts = find(jumps==1);

for i = 1:numel(adjpts)
    diffposneg(i) = defadj(adjpts(i)+1) - defadj(adjpts(i));
    defadj((adjpts(i)+1):end) = defadj((adjpts(i)+1):end) - diffposneg(i);
end
defadj = defadj-defadj(1);
%% plot deformation and force rates
% figure
% timemins = timemins - timemins(1);
% yyaxis left
% ptd = plot(timemins(2:end),-1*defdiff,'.')
% ylabel('Deformation (\mum) per min')
% xlabel('Time (minutes)')
% yyaxis right
% plot(timemins,fc,'.')
% ylabel('Friction Coefficient')
% ylim([0 .5])
% ti = title(filename,'Interpreter','none')
% 
% figure
% timemins = timemins - timemins(1);
% yyaxis left
% ptd = plot(timemins(2:end),-1*defdiff,'.')
% ylabel('Deformation (\mum) per min')
% xlabel('Time (minutes)')
% yyaxis right
% plot(timemins(2:end),forcediff,'.')
% ylabel('Normal Force (N) per min')
% ti = title(filename,'Interpreter','none')

end