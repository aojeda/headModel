function [r,x,y,z] = projectOnSphere(X,Y,Z,xo,yo,zo)
            % projectOnSphere - calculates projections of xyz positions
            % onto the unitary sphere
            %
            % Usage: [r,x,y,z] = projectOnSphere(X,Y,Z,xo,yo,zo,plotFlag)
            %
            % Notes:    The general formula for a sphere, with radius r is given by:
            %
            %           (x - xo)^2  +  (y - yo)^2  +  (z - zo)^2  =  r^2
            %
            %           This function takes arguments for cartesian co-ordinates
            %           of X,Y,Z (assume Z > 0) and the center of the sphere (xo,yo,zo).
            %           If (xo,yo,zo) is not provided a cnter at (0,0,0) is assumed.
            %
            %           Returned values are the fitted radius 'r' (constant)
            %           and the (x,y,z) Cartesian coordinates of the projected points
            %
            %
            % $Revision: 1.3 $ $Date: 2005/07/12 22:16:48 $
            % Licence:  GNU GPL, no express or implied warranties
            % History:  02/2002, Darren.Weber_at_radiology.ucsf.edu
            %                    adapted from elec_fit_sph
            %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % initialise centroid, unless input parameters defined
            if nargin < 4, xo = 0;end
            if nargin < 5, yo = 0;end
            if nargin < 6, zo = 0;end
            
            % Initialise r0 as a rough guess at the sphere radius
            rX = (max(X) - min(X)) / 2;
            rY = (max(Y) - min(Y)) / 2;
            rZ =  max(Z) - zo;
            r0 = mean([ rX rY rZ ]);
            
            % perform least squares estimate of spherical radius (r)
            options = optimset('fminsearch');
            r = fminsearch(@geometricTools.fit2sphere,r0, options, X, Y, Z, xo, yo, zo);
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Find the projection point of X,Y,Z to the fitted sphere radius r
            
            % Convert Cartesian X,Y,Z to spherical (radians)
            theta = atan2( (Y-yo), (X-xo) );
            phi = atan2( sqrt( (X-xo).^2 + (Y-yo).^2 ), (Z-zo) );
            % do not recalc: r = sqrt( (X-xo).^2 + (Y-yo).^2 + (Z-zo).^2);
            
            %   Recalculate X,Y,Z for constant r, given theta & phi.
            R = ones(size(phi)) * r;
            x = R .* sin(phi) .* cos(theta);
            y = R .* sin(phi) .* sin(theta);
            z = R .* cos(phi);
        end