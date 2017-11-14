% Tribology class file
classdef insituTRIB < handle
    
    properties
        filename
        timeminsraw
        speedmmsraw
        normalforceNraw
        frictionforceNraw
        frictioncoefficientraw
        deformationumraw
        frontclipindex
        backclipindex
        timemins
        speedmms
        normalforceN
        frictionforceN
        frictioncoefficient
        deformationum
        defadj
        thickness
        
        timeplus15index
        timeplus15
        maxfricindex
        strain_relax_index
        endsearchtime
        slide_start_index
        strain_slide_start_peak_index
        slideendsearchindex
        
        strain
        strain_relax
        strain_slide_start_peak
        strain_15
        strain_15_index
        strain_sliding_min
        strain_recov_relaxto15
        strain_recov_peakto15
        strain_sliding_min_index
        friction_startup
        friction_startup_index
        friction_15
        friction_15_index
        friction_min
        friction_min_index
        
        fit_relax_strain
        fit_relax_timemins
        fit_recov_strain
        fit_recov_timemins_strain
        fit_recov_friction
        fit_recov_timemins_friction

    end
    
    methods
        %Import data
        function obj = insituTRIB(filename)
           obj.filename = filename;
           [obj.timeminsraw,obj.speedmmsraw,obj.normalforceNraw,...
               obj.frictionforceNraw,obj.frictioncoefficientraw,...
               obj.deformationumraw] = importTRIBdata(filename);
        end
        %plot raw
        function plotraw(obj)
            fig = clf;
            fig.Position = [50, 50, 1200, 750];
            timemins = obj.timeminsraw - obj.timeminsraw(1);
            yyaxis left
            ptd = plot(timemins,-1*obj.deformationumraw,'.')
            ylabel('Deformation (\mum)')
            xlabel('Time (minutes)')
            yyaxis right
            plot(timemins,obj.frictioncoefficientraw,'.')
            ylabel('Friction Coefficient')
            ylim([0 .5])
            ti = title(obj.filename,'Interpreter','none');
        end
        % plot raw all params
        function plotrawall(obj)
           fig = clf;
            fig.Position = [100,100,1200,700];
            t = obj.timeminsraw - obj.timeminsraw(1);
            
            % def and friction
            sub1 = subplot(2,1,1);
            yyaxis left
            ptd = plot(t,-1*obj.deformationumraw,'.');
            ylabel('Deformation (\mum)')
            xlabel('Time (minutes)')
            ylim([-1 1000]);
            yyaxis right
            plot(t,obj.frictioncoefficientraw,'.');
            ylabel('Friction Coefficient')
            ylim([0 .5]);
            ti = title(obj.filename,'Interpreter','none');
            
            % def and force
            sub2 = subplot(2,1,2);
            yyaxis left
            ptd = plot(t,-1*obj.deformationumraw,'.');
            ylabel('Deformation (\mum)')
            xlabel('Time (minutes)')
            ylim([-1 1000]);
            yyaxis right
            plot(t,obj.normalforceNraw,'.');
            ylabel('Friction Coefficient')
            ylim([-1 10]);
            ti = title(obj.filename,'Interpreter','none'); 
        end
        %clip data
        function clipdata(obj)
            plotraw(obj)
            btn1 = uicontrol('Style', 'pushbutton', 'String', 'Clip Front',...
                'Position', [300 10 150 30],...
                'FontSize',18,...
                'Callback', @getfrontclipindex);
            btn2 = uicontrol('Style', 'pushbutton', 'String', 'Clip Back',...
                'Position', [500 10 150 30],...
                'FontSize',18,...
                'Callback', @getbackclipindex);
            btn3 = uicontrol('Style', 'pushbutton', 'String', 'Done',...
                'Position', [900 10 150 30],...
                'FontSize',18,...
                'Callback', @closefigure);
            
            function getfrontclipindex(source,event)
                dcm_obj = datacursormode(gcf);
                set(dcm_obj,'DisplayStyle','datatip','SnapToDataVertex','off');
                c_info = getCursorInfo(dcm_obj);
                obj.frontclipindex = c_info.DataIndex;
            end
            function getbackclipindex(source,event)
                dcm_obj = datacursormode(gcf);
                set(dcm_obj,'DisplayStyle','datatip','SnapToDataVertex','off');
                c_info = getCursorInfo(dcm_obj);
                obj.backclipindex = c_info.DataIndex;
            end
            function closefigure(source,event)
                close(gcf)
                obj.timemins = obj.timeminsraw(obj.frontclipindex:obj.backclipindex);
                obj.speedmms = obj.speedmmsraw(obj.frontclipindex:obj.backclipindex);
                obj.normalforceN = obj.normalforceNraw(obj.frontclipindex:obj.backclipindex);
                obj.frictionforceN = obj.frictionforceNraw(obj.frontclipindex:obj.backclipindex);
                obj.frictioncoefficient = obj.frictioncoefficientraw(obj.frontclipindex:obj.backclipindex);
                obj.deformationum = obj.deformationumraw(obj.frontclipindex:obj.backclipindex);
            end
            waitfor(btn1)
            waitfor(btn2)
            waitfor(btn3)
        end
        %plot clipped data 
        function plotclip(obj)
            fig = clf;
            t = obj.timemins - obj.timemins(1);
            yyaxis left
            ptd = plot(t,-1*obj.deformationum,'.');
            ylabel('Deformation (\mum)')
            xlabel('Time (minutes)')
            yyaxis right
            plot(t,obj.normalforceN,'.')
            ylabel('Friction Coefficient')
            ylim([0 10])
            ti = title(obj.filename,'Interpreter','none');
        end
        % get rid of elastic deformation
        function clean(obj)
           
           % Preprocessing of data
           forcelogical = obj.normalforceN > 1;
           fc = forcelogical.*obj.frictioncoefficient;
           
           frictionlogical = fc > 0 & fc <1;

           defdiff = diff(obj.deformationum)./diff(obj.timemins);
           forcediff = diff(obj.normalforceN)./diff(obj.timemins);
           
           % GUI Begin
           h = gcf;
           h.Position = [200,100,1000,700];
           
           % GUI text
            uicontrol(...
                'Style','text',...
                'String','Deformation Cutoff (um/min)',...
                'FontSize',18,...
                'Position',[100,670,250,25],...
                'HorizontalAlignment','Right');
            uicontrol(...
                'Style','text',...
                'String','Force Cutoff (N/min)',...
                'FontSize',18,...
                'Position',[100,645,250,25],...
                'HorizontalAlignment','Right');
            
            % GUI inputs
            dcut = uicontrol(...
                'Style','edit',...
                'String','400',...
                'FontSize',18,...
                'Position',[400,670,75,25]);
            fcut = uicontrol(...
                'Style','edit',...
                'String','15',...
                'FontSize',18,...
                'Position',[400,645,75,25]);

            % GUI Outputs
            
            axdef = axes(...
                'Units','Pixels',...
                'Position',[100,375,800,225]);
            axforce = axes(...
                'Units','Pixels',...
                'Position',[100,100,800,225]);
            
            set(h,'CurrentAxes',axdef)
            yyaxis left
            topd = plot(obj.timemins,-1*obj.deformationum,'.');
            ylabel('Deformation (\mum)')
            xlabel('Time (minutes)')
            yyaxis right
            topf =plot(obj.timemins,obj.frictioncoefficient,'.');
            ylabel('Friction Coefficient')
            ylim([0 .5]);
            ti = title(obj.filename,'Interpreter','none');

            set(h,'CurrentAxes',axforce)
            yyaxis left
            botd = plot(obj.timemins,-1*obj.deformationum,'.');
            ylabel('Deformation (\mum)')
            xlabel('Time (minutes)')
            yyaxis right
            botf = plot(obj.timemins,obj.normalforceN,'.');
            ylabel('Force (N)')
            ylim([0 10]);
            ti = title(obj.filename,'Interpreter','none');
            
            % GUI buttons
            uicontrol(...
                'Style','pushbutton',...
                'String','UPDATE',...
                'FontSize',20,...
                'Position',[650,645,250,50],...
                'callback',@clean_callback);
            donebuttom = uicontrol(...
                'Style','pushbutton',...
                'String','Done',...
                'FontSize',20,...
                'Position',[400,10,200,50],...
                'HorizontalAlignment','Right',...
                'callback',@close_callback);
            
            function clean_callback(~,~)
                % Clean tribology data based on several key assumptions and inputs.  Gets
                % rid of the elastic deformation of the cantilever leavign only flow
                % deformation
                
                % Sliding never occurs when there is no loading in most experiments.  In
                % this case, the normal force should be high when sliding is occuring so we
                % set all friction valeus to 0 when the normal force is less than 1 N
                defjumpcutoff = str2double(get(dcut,'string'));
                forcejumpcutoff = str2double(get(fcut,'string'));
                
                defadj = obj.deformationum;

                jumps = ((abs(defdiff) > defjumpcutoff)| (abs(forcediff) > forcejumpcutoff)) > 0;
                adjpts = find(jumps==1);
                
                for i = 1:numel(adjpts)
                    diffposneg(i) = defadj(adjpts(i)+1) - defadj(adjpts(i));
                    defadj((adjpts(i)+1):end) = defadj((adjpts(i)+1):end) - diffposneg(i);
                end
                obj.defadj = defadj-defadj(1);
                set(topd,'YData',-1*obj.defadj);
                set(botd,'YData',-1*obj.defadj);
            end
            
            function close_callback(~,~)
                close(h)
            end
            
            waitfor(h)
                        
        end        
        %plotadjusted def
        function plotdef(obj)
            fig = clf;
            fig.Position = [100,100,1200,700];
            t = obj.timemins - obj.timemins(1);
            
            % def and friction
            sub1 = subplot(2,1,1);
            yyaxis left
            ptd = plot(t,-1*(obj.defadj-obj.defadj(1)),'.');
            ylabel('Deformation (\mum)')
            xlabel('Time (minutes)')
            ylim([0,1000])
            yyaxis right
            plot(t,obj.frictioncoefficient,'.');
            ylabel('Friction Coefficient')
            ylim([0 .5]);
            ti = title(obj.filename,'Interpreter','none');
            
            % def and force
            sub2 = subplot(2,1,2);
            yyaxis left
            ptd = plot(t,-1*(obj.defadj-obj.defadj(1)),'.');
            ylabel('Deformation (\mum)')
            xlabel('Time (minutes)')
            ylim([0,1000])
            yyaxis right
            plot(t,obj.normalforceN,'.');
            ylabel('Friction Coefficient')
            ylim([0 10]);
            ti = title(obj.filename,'Interpreter','none');
        end
        %import thickness value in microns
        function thick(obj,t)
           obj.thickness = t;
           obj.strain = 100*(obj.defadj)./t;
        end
        %plot with strain
        function plot(obj)
            fig = clf;
            fig.Position = [100,100,1200,700];
            t = obj.timemins - obj.timemins(1);
            
            % def and friction
            sub1 = subplot(2,1,1);
            yyaxis left
            ptd = plot(t,-1*obj.strain,'.');
            ylabel('Strain (%)')
            xlabel('Time (minutes)')
            yyaxis right
            plot(t,obj.frictioncoefficient,'.');
            ylabel('Friction Coefficient')
            ylim([0 .5]);
            ti = title(obj.filename,'Interpreter','none');
            
            % def and force
            sub2 = subplot(2,1,2);
            yyaxis left
            ptd = plot(t,-1*obj.strain,'.');
            ylabel('Strain (%)')
            xlabel('Time (minutes)')
            yyaxis right
            plot(t,obj.normalforceN,'.');
            ylabel('Force (N)')
            ylim([0 10]);
            ti = title(obj.filename,'Interpreter','none');
        end
        %plot with strain on 100% scale
        function plot100(obj)
            fig = clf;
            fig.Position = [100,100,1200,700];
            t = obj.timemins - obj.timemins(1);
            
            % def and friction
            sub1 = subplot(2,1,1);
            yyaxis left
            ptd = plot(t,-1*obj.strain,'.');
            ylabel('Strain (%)')
            xlabel('Time (minutes)')
            ylim([0 100]);
            yyaxis right
            plot(t,obj.frictioncoefficient,'.');
            ylabel('Friction Coefficient')
            ylim([0 .5]);
            ti = title(obj.filename,'Interpreter','none');
            
            % def and force
            sub2 = subplot(2,1,2);
            yyaxis left
            ptd = plot(t,-1*obj.strain,'.');
            ylabel('Strain (%)')
            xlabel('Time (minutes)')
            ylim([0 100]);
            yyaxis right
            plot(t,obj.normalforceN,'.');
            ylabel('Force (N)')
            ylim([0 10]);
            ti = title(obj.filename,'Interpreter','none');
        end
        %get key strain and recovered strain automatically
        function auto(obj)
            
            obj.timemins = obj.timemins - obj.timemins(1);
            
            % Find where sliding starts, and where relaxation ends
            obj.strain_relax_index = obj.slide_start_index(1) - 1;
            obj.strain_relax = obj.strain(obj.strain_relax_index);

            % Find the peak strain value after sliding starts
            % there seems to be some gradual response again before recovery
            obj.endsearchtime = obj.timemins(obj.strain_relax_index) + 1; % 1 minute seach window
            timediff = obj.timemins - obj.endsearchtime;
            [~,obj.slideendsearchindex] = min(abs(timediff));
            [obj.strain_slide_start_peak,tempind] = ...
                min(obj.strain(obj.strain_relax_index:obj.slideendsearchindex));
            obj.strain_slide_start_peak_index = obj.slide_start_index(1) + tempind;
            % Find max friction value, within 1st sliding minute
            frictionsmooth = movmean(obj.frictioncoefficient,10);
            [obj.friction_startup, obj.friction_startup_index] = ...
                max(frictionsmooth(obj.strain_relax_index:obj.slide_start_index(1)));
            
            % Find the friction and strain after 15 minutes sliding from this
            % point of max friciton, usually start of sliding
            obj.timeplus15 = obj.timemins(obj.slide_start_index(1)) + 15;
            timediffplus15 = obj.timemins - obj.timeplus15(1);
            [~,obj.timeplus15index] = min(abs(timediffplus15));
            obj.friction_15 = frictionsmooth(obj.timeplus15index);
            obj.friction_15_index = obj.timeplus15index;
            obj.strain_15 = obj.strain(obj.timeplus15index);
            obj.strain_15_index = obj.timeplus15index;
            
            % Find minimum of strain and friction during sliding
            [obj.friction_min,obj.friction_min_index] = min(frictionsmooth(obj.maxfricindex:obj.timeplus15index));
            [obj.strain_sliding_min,obj.strain_sliding_min_index] = min(obj.strain(obj.maxfricindex:obj.timeplus15index));
            % friction end and strain end should be 15 minutes after strain
            % relax or strain start sliding
            obj.strain_recov_peakto15 = obj.strain_slide_start_peak-obj.strain_15;
            obj.strain_recov_relaxto15 = obj.strain_relax-obj.strain_15;
        end
        %get key strain and recovered strain manuallu
        function man(obj)
            
            h = clf;
            h.Position = [100,100,1200,700];
            
            axdef = axes(...
                'Units','Pixels',...
                'Position',[100,375,800,225]);
            ptd = plot(obj.timemins,-1*obj.strain,'.');
            ylabel('Strain (%)')
            xlabel('Time (minutes)')
            
            relaxstrain = uicontrol('Style', 'pushbutton', 'String', 'Relaxation Strain',...
                'Position', [400 2 50 20],...
                'Callback', @relaxstrain_callback);
            slidestartstrain = uicontrol('Style', 'pushbutton', 'String', 'Slide Start Strain',...
                'Position', [450 2 50 20],...
                'Callback', @slidestartstrain_callback);
            closebttn = uicontrol('Style', 'pushbutton', 'String', 'Done',...
                'Position', [500 2 50 20],...
                'Callback', @closefigure_callback);
            
            function relaxstrain_callback(~,~)
                cursordata = datacursormode(h);
                set(cursordata,'DisplayStyle','datatip','SnapToDataVertex','off');
                c_info = getCursorInfo(cursordata);
                obj.strain_relax = c_info.Position(2);
            end
            
            function slidestartstrain_callback(~,~)
                cursordata = datacursormode(gcf);
                set(cursordata,'DisplayStyle','datatip','SnapToDataVertex','off');
                c_info = getCursorInfo(cursordata);
                obj.strain_slide_start_peak = c_info.Position(2);
            end
            
            function closefigure_callback(~,~)
                close(h)
            end
            
            waitfor(relaxstrain)
            waitfor(slidestartstrain)
            waitfor(closebttn)
            obj.strain_recovered = obj.strain_slide_start_peak - obj.strain_15;
        end
        %get time constants for relaxation/recovery
        function getfitdata(obj)
            obj.fit_relax_strain = obj.strain(1:obj.strain_relax_index);
            obj.fit_relax_timemins = obj.timemins(1:obj.strain_relax_index);
            
            obj.fit_recov_strain = obj.strain(obj.strain_slide_start_peak_index:obj.timeplus15index);
            obj.fit_recov_timemins_strain = obj.timemins(obj.strain_slide_start_peak_index:obj.timeplus15index);
            
            obj.fit_recov_friction = obj.frictioncoefficient(obj.slide_start_index:obj.timeplus15index);
            obj.fit_recov_timemins_friction = obj.timemins(obj.slide_start_index:obj.timeplus15index);

        end
        % get initial loading
        function autoclean(obj)
            %% clip off the large portions on the area before and after loading occurs
            flog = obj.normalforceNraw > .05;
            fdifflog = find(diff(flog) == 1);
            for i = 1:numel(fdifflog)
                if i == numel(fdifflog)
                    fsum(i) = sum(flog(fdifflog(i):end));
                else
                    fsum(i) = sum(flog(fdifflog(i):fdifflog(i+1)));
                end    
            end
            [~,tempind] = max(fsum);
            obj.frontclipindex = fdifflog(tempind);
            obj.frictioncoefficientraw = obj.frictioncoefficientraw.*(obj.speedmmsraw > 0.1)
            obj.backclipindex = max(find((obj.speedmmsraw > 0.1)==1))-1;
            
            %recalc
            timemins_int = obj.timeminsraw(obj.frontclipindex:obj.backclipindex);
            speedmms_int = obj.speedmmsraw(obj.frontclipindex:obj.backclipindex);
            normalforceN_int = obj.normalforceNraw(obj.frontclipindex:obj.backclipindex);
            frictionforceN_int = obj.frictionforceNraw(obj.frontclipindex:obj.backclipindex);
            frictioncoefficient_int = obj.frictioncoefficientraw(obj.frontclipindex:obj.backclipindex);
            deformationum_int = obj.deformationumraw(obj.frontclipindex:obj.backclipindex);

            %def adjust for elastic at beginning of test
            %% deformation rate as cutoff
            defjumpcutoff = 100;
            defdiff = diff(deformationum_int)./diff(timemins_int);
            
            speedlog = (speedmms_int > 0.1);
            obj.slide_start_index = find(speedlog == 1);
            
            jumps = ((abs(defdiff) > defjumpcutoff)) > 0;%| (abs(forcediff) > forcejumpcutoff)) > 0;
            adjpts = find(jumps==1);
            deformationum_int2 = deformationum_int;
            %only search first few data points around start of sliding and
            %adjust there
            movmean(deformationum_int2,10);
            bigjumps = find(((adjpts > (obj.slide_start_index(1)-30)) & (adjpts < (obj.slide_start_index(1)+20))));
            cutpoints(:,1) = adjpts(bigjumps);
            for i = 1:numel(bigjumps)
                diffposneg(i) = deformationum_int2(cutpoints(i)+1) - deformationum_int2(cutpoints(i));
                deformationum_int2((cutpoints(i)+1):end) = deformationum_int2((cutpoints(i)+1):end) - diffposneg(i);
            end

% 
% 
%             obj.defadj = defadj(adjpts(end):end)-defadj(adjpts(end));
% 
%             obj.timemins = timemins_int(adjpts(end):end);
%             obj.speedmms = speedmms_int(adjpts(end):end);
%             obj.normalforceN = normalforceN_int(adjpts(end):end);
%             obj.frictionforceN = frictionforceN_int(adjpts(end):end);
%             obj.frictioncoefficient = frictioncoefficient_int(adjpts(end):end);
%             obj.deformationum = deformationum_int(adjpts(end):end);
%             
            %% force change rate as cutoff
            
%             forcejumpcutoff = 4;
%             forcediffall = diff(normalforceN_int)./diff(timemins_int);
%             forcediff = max(forcediffall(1:50));%forcediffall(1:50);
%             jumps = ((abs(forcediff) >= forcejumpcutoff)) > 0;
%             adjpts = find(jumps==1);
%             lastjump = numel(adjpts);
%             
%             % def adjust for elastic at slide start
%             friclog = frictioncoefficient_int > 0.01;
%             slide_start = find(friclog == 1);
%             obj.strain_relax_index = slide_start(1) - 1;
%             
%             obj.defadj = defadj(adjpts(end):end)-defadj(adjpts(end));
% 
%             obj.timemins = timemins_int(adjpts(end):end);
%             obj.speedmms = speedmms_int(adjpts(end):end);
%             obj.normalforceN = normalforceN_int(adjpts(end):end);
%             obj.frictionforceN = frictionforceN_int(adjpts(end):end);
%             obj.frictioncoefficient = frictioncoefficient_int(adjpts(end):end);
%             obj.deformationum = deformationum_int(adjpts(end):end);        

            %% calculate adjusted deformation values based on force max
            [mval,index] = max(normalforceN_int(1:300));
            obj.timemins = timemins_int;%(index:end);
            obj.speedmms = speedmms_int;%(index:end);
            obj.normalforceN = normalforceN_int;%(index:end);
            obj.frictionforceN = frictionforceN_int;%(index:end);
            obj.frictioncoefficient = frictioncoefficient_int;%(index:end);
            obj.deformationum = deformationum_int2;%(index:end);
            obj.defadj = deformationum_int2-deformationum_int2(index);

            
        end
    end
    
end