% Tribology data class file
% ----Created 20170425----
% Brian Graham
% This is tribology class file that holds all the experiment data
% The idea is to make it easy to trim data and analyze data
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
        
        % Add the sample thickness and compute strain
        % Thickness should be in same units as deformation
        % the default it microns
        function importthickness(obj,thickness)
            obj.th = thickness;
            obj.st = obj.d/obj.th;
        end
    end
end