function [] = tribplotyy(obj,yleft,yright)
%% Standardized plotting of 2 tribology data
% Plots double y axis graphs showing two tribology variabels over time

switch yleft
    
    case 'nf'
        y1 = obj.nf;
        y1label = 'Normal Force (N)';
        y1plotmax = nanmedian(y1)*2;
    case 'ff'
        y1 = obj.ff;
        y1label = 'Friction Force (N)';
        y1plotmax = nanmedian(y1)*2;
    case 'fc'
        y1 = obj.fc;
        y1label = 'Friction Coefficient (\mu)';
        y1plotmax = 0.5;
    case 's'
        y1 = obj.s;
        y1label = 'Speed (mm/s)';
        y1plotmax = 101;
        
    case 'd'
        y1 = -1.*obj.d;
        y1label = 'Deformation (\mum)';
        y1plotmax = nanmedian(y1)*2;
    case 'st'
        y1 = -1.*obj.st;
        y1label = 'Strain (\epsilon)';
        y1plotmax = nanmedian(y1)*2;
end

switch yright
    
    case 'nf'
        y2 = obj.nf;
        y2label = 'Normal Force (N)';
        y2plotmax = nanmedian(y2)*2;
    case 'ff'
        y2 = obj.ff;
        y2label = 'Friction Force (N)';
        y2plotmax = nanmedian(y2)*2;
        
    case 'fc'
        y2 = obj.fc;
        y2label = 'Friction Coefficient (\mu)';
        y2plotmax = 0.5;
    case 's'
        y2 = obj.s;
        y2label = 'Speed (mm/s)';
        y2plotmax = 101;
        
    case 'd'
        y2 = -1.*obj.d;
        y2label = 'Deformation (\mum)';
        y2plotmax = nanmedian(y2)*2;
        
    case 'st'
        y2 = -1.*obj.st;
        y2label = 'Strain (\epsilon)';
        y2plotmax = nanmedian(y2)*2;
        
end

%% Plotting setup
fig = clf;
fig.Position = [50, 50, 1200, 750];

timemins = (obj.t - obj.t(1))./60;

yyaxis left
hold on

% This section adds background shading to indicate when sliding is occuring
% Only displays if sliding has been detected
if isempty(obj.sstart) == 0
    for i = 1:numel(obj.sstart)
        if isempty(find((obj.sstart(i) < 0))) == 1
            re{i} = rectangle('Position',[timemins(obj.sstart(i)),  0, (timemins(obj.send(i))-timemins(obj.sstart(i))), y1plotmax]);
            cscale = .90;
            re{i}.FaceColor = [1,1,1].*cscale;
            re{i}.EdgeColor = [1,1,1].*cscale;
            uistack(re{i},'bottom')
        end
    end
end

% Plot data
py1 = plot(timemins,y1,'.')

ylim([0,y1plotmax]);
ylabel(y1label);
xlabel('Time (mins)');
hold off

yyaxis right

hold on
py2 = plot(timemins,y2,'.')
ylabel(y2label)
ylim([0 y2plotmax]);
xlim([0, max(timemins)]);
if isempty(obj.filename) == 0
    ti = title(obj.filename,'Interpreter','none');
end
ax = gca;
ax.FontSize = 18;
ax.Layer = 'top';

end
