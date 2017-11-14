% Tribology data class file
% ----Created 20170425----
% Brian Graham
% This is tribology class file that holds all the experiment data
% The idea is to make it easy to trim data and data
% subset so I may add methods in the future to aid in trimming this data.
classdef trib < handle
    
    properties
        filename % name of file
        t % time in secs
        s % speed in mm/s
        sstart % start speed index
        send % end speed index
        speedseg % speed for a sliding segment
        loadseg % load for a static segment
        nf % normal force in N
        ff % friction force in N
        fc % friction coefficient
        d % deformation in um
        th % thickness in um
        st % strain

    end
    
    methods
        %Import data
        function import(obj,filename)
            obj.filename = filename;
            if isempty(regexp(filename,'.xls')) == 0
                [obj.t,obj.s,obj.nf,...
                    obj.ff,obj.fc,...
                    obj.d] = importPODdata(filename);
            else
                [obj.t,obj.s,obj.nf,...
                    obj.ff,obj.fc,...
                    obj.d] = importINSITUdata(filename);
                
            end
        end
        function plot(obj)
            fig = clf;
            fig.Position = [50, 50, 1200, 750];
            timemins = (obj.t - obj.t(1))./60;
            
            yyaxis left
            maxdefplot = -1*nanmedian(obj.d)*2;
            hold on
            if isempty(obj.sstart) == 0
                for i = 1:numel(obj.sstart)
                    if isempty(find((obj.sstart(i) < 0))) == 1
                        re{i} = rectangle('Position',[timemins(obj.sstart(i)),  0, (timemins(obj.send(i))-timemins(obj.sstart(i))), maxdefplot]);
                        % Different background shading options for when
                        % different speeds are present
                        %cscale = 0.95-log(obj.speedseg(i))./log(100)*0.3;
                        %cscale = (-0.003*obj.speedseg(i)+.93);
                        %cscale = (.95-(obj.speedseg(i).^1.85)./80^2);
                        cscale = .90;
                        re{i}.FaceColor = [1,1,1].*cscale;
                        re{i}.EdgeColor = [1,1,1].*cscale;
                        uistack(re{i},'bottom')
                    end
                end
            end
            %ptd = plot(timemins,-1*sgolayfilt(obj.d,1,11),'.')
            ptd = plot(timemins,-1*(obj.d),'.')

            ylim([0,abs(nanmedian(obj.d)*2)]);
            ylabel('Deformation (\mum)')
            xlabel('Time (mins)')
            
            yyaxis right
            maxfricplot = 0.5;
            
            hold on
            ptf = plot(timemins,obj.fc,'.')
            ylabel('Friction Coefficient')
            ylim([0 maxfricplot])
            xlim([0, max(timemins)])            
   
            ti = title(obj.filename,'Interpreter','none');
            ax = gca;
            ax.FontSize = 18;
            ax.Layer = 'top';
            
        end
    end
end