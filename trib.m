% Tribology data class file
% ----v1 Created 20170425----
% Brian Graham
% This is tribology class file that creates an object to hold
% all the experiment data.  The idea is to make it easy to take subsets of
% and analyze the data

classdef trib < handle
    
    properties
        filename % name of file  - experiment data
        t % time in secs - experiment data 
        s % speed in mm/s - experiment data 
        sstart % start speed index - calculated by other trib functions
        send % end speed index - calculated by other trib functions
        speedseg % speed for a sliding segment  - calculated by other trib functions
        loadseg % load for a static segment  - calculated by other trib functions
        nf % normal force in N - experiment data 
        ff % friction force in N - experiment data 
        fc % friction coefficient - experiment data 
        d % deformation in um - experiment data 
        th % thickness in um - manual entry
        r % radius of curvature of the sample in mm - manual entry
        st % strain - calculated --> st = d/th
        a % contact radius - calculated --> a = sqrt(2*r*d) - reported in mm
        ca % contact area - calculated --> ca = pi*a^2 - mm^2
        sh % shear stress  - calculated --> sh = ff/ca - MPa
        cp  % contact pressure - calculated --> cp = nf/ca - MPa
        nfeq % equilibrium normal force in N for eeq calculation - manual entry
        deq % equilibrium deformation force in um for eeq calculation - manual entry
        eeq % equilibrium modulus - calculated --> eeq = (nfeq*th)/(2*pi*r*deq^2) - MPa
        eef % effective modulus - calculated --> eef = (nf*th)/(2*pi*r*d^2) - MPa
        ip % interstitial pressure - calculated --> ip = (eef-eeq)*(d/th) - MPa
        fl % fluid load support fraction - calculated --> fl = (eef-eeq)/eef
    end
    
    methods
        
        %Import data
        function import(obj,filename)
            obj.filename = filename;
            if isempty(regexp(filename,'.xls')) == 0
                [obj.t,obj.s,obj.nf,...
                    obj.ff,obj.fc,...
                    obj.d] = importPODdata(filename);
            elseif isempty(regexp(filename,'.csv')) == 0
                [obj.t,obj.s,obj.nf,...
                    obj.ff,obj.fc,...
                    obj.d] = importCSVdata(filename);
            else
                [obj.t,obj.s,obj.nf,...
                    obj.ff,obj.fc,...
                    obj.d] = importINSITUdata(filename);    
            end
        end
        
        % Calculated Parameters
        function calcparams(obj)
            % Checks if thickness and radius of curvature are available
            % If so, calculate relevant params that require each geometry
            thcheck = ~isempty(obj.th);
            rcheck = ~isempty(obj.r);
            nfeqcheck = ~isempty(obj.nfeq);
            deqcheck = ~isempty(obj.deq);
            % thickness-based params only
            if thcheck == 1
                obj.st = obj.d./obj.th;
            end
            
            % radius-based params only
            if rcheck == 1
                obj.a = (sqrt(2.*obj.r.*-1.*(obj.d./1000))); % mm
                obj.ca = 3.141593.*obj.a.^2; % mm^2
                obj.sh = obj.ff./obj.ca; % MPa
                obj.cp = obj.nf./obj.ca; % MPa
            end
            
            % params that require both thickness and radius
            if (thcheck & rcheck & nfeqcheck & deqcheck) == 1
                obj.eeq = (obj.nfeq.*obj.th./1000)./(2.*3.141593.*obj.r.*(obj.deq./1000).^2); % MPa
                obj.eef = (obj.nf.*obj.th./1000)./(2.*3.141593.*obj.r.*((-1.*obj.d)./1000).^2); % MPa
                obj.ip = (obj.eef-obj.eeq).*((-1.*obj.d)./obj.th); % MPa
                obj.fl = (obj.eef-obj.eeq)./obj.eef; % fraction
            end
            
        end
    end
end