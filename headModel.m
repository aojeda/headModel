% Defines the class headModel for solving forward/inverse problem of the EEG. 
% 
% Author: Alejandro Ojeda, Syntrogi Inc. 2015

classdef headModel < handle
    properties(GetAccess=public, SetAccess=public,SetObservable)
        channelSpace = [];     % xyz coordinates of the sensors.
        labels = [];
        cortex = [];
        inskull = []'
        outskull = [];
        scalp = [];
        fiducials = []; % xyz of the fiducial landmarks: nassion, lpa, rpa, vertex, and inion.                       
        atlas           % Atlas that labels each vertex in the most internal surface (gray matter).
        K = [];         % Lead field matrix
        L = [];         % Laplacian operator
    end
    properties(GetAccess = private, SetAccess = private, Hidden)
        F = [];
        tmpFiles = {}
    end
    properties(Dependent, Hidden)
        channelLabel = []
        surfaces = [];
        leadFieldFile = [];
    end
    methods
        function obj = headModel(varargin)
            if length(varargin)==1, varargin = varargin{1};end
            if ~iscell(varargin) && ischar(varargin) && exist(varargin,'file')
                [obj.channelSpace,obj.labels,obj.fiducials] = readMontage(varargin);
                return
            end
            for k=1:2:length(varargin)
                if isprop(obj,varargin{k})
                    try
                        obj.(varargin{k}) = varargin{k+1};
                    end
                end
            end
            if isempty(obj.channelSpace), error('"channelSpace" cannot be empty.');end
            if isempty(obj.labels)
                N = size(obj.channelSpace,1);
                obj.labels = cell(N,1);
                for k=1:N, obj.labels{k} = num2str(k);end
            end
            if isempty(obj.L) && ~isempty(obj.cortex)
                disp('Computing the Laplacian operator...')
                try
                    obj.L = geometricTools.getSurfaceLaplacian(obj.cortex.vertices,obj.cortex.faces);
                end
            end
        end
        %%
        function removeSensor(obj,indices)
            obj.labels(indices) = [];
            obj.channelSpace(indices,:) = [];
            obj.K(indices,:) = [];
        end
        %%
        function [roiname,roinumber] = labelDipole(obj,dipole)
            if isempty(obj.F)
                obj.F = scatteredInterpolant(obj.cortex.vertices(:,1),...
                    obj.cortex.vertices(:,2),obj.cortex.vertices(:,3),...
                    obj.atlas.colorTable,'nearest');
            end
            roinumber = obj.F(dipole(:,1),dipole(:,2),dipole(:,3));
            roiname = obj.atlas.label(roinumber);
        end
        %%
        function h = plot(obj)
            % Plots the different layers of tissue, the sensor positions, and their labels.
            % It colors different regions of the cortical surface according to a defined
            % anatomical atlas. Several interactive options for customizing the figure are
            % available.
            if isempty(obj.channelSpace) || isempty(obj.labels) || isempty(obj.scalp) || ...
                    isempty(obj.outskull) || isempty(obj.inskull) || isempty(obj.cortex)
                error('Head model is incomplete.');
            end
            h = headModelViewerHandle(obj);
        end
        %%
        function H = removeAverageReference(obj,channel2remove)
            Ny = size(obj.K,1);
            if nargin<2, channel2remove = [];end
            H = eye(Ny)-ones(Ny)/Ny;    % Average reference operator
            obj.K = H*obj.K;            % Remove the average reference
            obj.K(channel2remove,:) = [];
            obj.labels(channel2remove) = [];
            obj.channelSpace(channel2remove,:) = [];
        end
        function stdLeadField(obj)
            obj.K = bsxfun(@rdivide,obj.K,eps+sqrt(sum(obj.K.^2,1)));
            % obj.K = bsxfun(@rdivide,obj.K,eps+std(obj.K,[],2));
        end
        %%
        function hFigureObj = plotOnModel(obj,J,V,figureTitle,autoscale,fps,time)
            % Plots cortical/topographical maps onto the cortical/scalp surface.
            % 
            % Input parameters:
            %       J:           cortical map size number of vertices of the cortical surface by number of time points
            %       V:           topographic map size number of vertices of the scalp surface by number of time points; 
            %                    if V is empty, a single color is used simulating the color of the skin 
            %       figureTitle: title of the figure (optional)
            %                    
            % Output argument:   
            %       hFigure:     figure handle 
            
            if nargin < 2, error('Not enough input arguments');end
            if nargin < 3, V = [];end
            if nargin < 4, figureTitle = '';end
            if nargin < 5, autoscale = false;end
            if nargin < 6, fps = 30;end
            if nargin < 7, time = 1:size(J,2);end
            if isempty(figureTitle), figureTitle = '';end
            if isempty(autoscale), autoscale = false;end
            if isempty(fps), fps = 30;end
            if isa(J,'gpuArray'), J = gather(J);end
            if isa(V,'gpuArray'), V = gather(V);end
            hFigureObj = currentSourceViewer(obj,J,V,figureTitle, autoscale, fps, time);
        end
        %%
        function h = plotMontage(obj,showNewfig)
            % Plots a figure with the xyz distribution of sensors, fiducial landmarks, and
            % coordinate axes.
            
            if isempty(obj.channelSpace) || isempty(obj.labels);error('"channelSpace or "labels" are empty.');end
            if nargin < 2, showNewfig = true;end
            color = [0.93 0.96 1];
            if showNewfig, figure('Color',color);end
            h = scatter3(obj.channelSpace(:,1),obj.channelSpace(:,2),obj.channelSpace(:,3),'filled',...
                'MarkerEdgeColor','k','MarkerFaceColor','y','parent',gca);
            hold on;
            N = length(obj.labels);
            k = 1.1;
            for it=1:N, text('Position',k*obj.channelSpace(it,:),'String',obj.labels{it});end
            mx = max(obj.channelSpace);
            k = 1.2;
            line([0 k*mx(1)],[0 0],[0 0],'LineStyle','-.','Color','b','LineWidth',2)
            line([0 0],[0 k*mx(2)],[0 0],'LineStyle','-.','Color','g','LineWidth',2)
            line([0 0],[0 0],[0 k*mx(3)],'LineStyle','-.','Color','r','LineWidth',2)
            text('Position',[k*mx(1) 0 0],'String','X','FontSize',12,'FontWeight','bold','Color','b')
            text('Position',[0 k*mx(2) 0],'String','Y','FontSize',12,'FontWeight','bold','Color','g')
            text('Position',[0 0 k*mx(3)],'String','Z','FontSize',12,'FontWeight','bold','Color','r')
            
            try %#ok
                scatter3(obj.fiducials.nasion(1),obj.fiducials.nasion(2),obj.fiducials.nasion(3),'filled','MarkerEdgeColor','k','MarkerFaceColor','K');
                text('Position',1.1*obj.fiducials.nasion,'String','Nas','FontSize',12,'FontWeight','bold','Color','k');
                scatter3(obj.fiducials.lpa(1),obj.fiducials.lpa(2),obj.fiducials.lpa(3),'filled','MarkerEdgeColor','k','MarkerFaceColor','K');
                text('Position',1.1*obj.fiducials.lpa,'String','LPA','FontSize',12,'FontWeight','bold','Color','k');
                scatter3(obj.fiducials.rpa(1),obj.fiducials.rpa(2),obj.fiducials.rpa(3),'filled','MarkerEdgeColor','k','MarkerFaceColor','K');
                text('Position',1.1*obj.fiducials.rpa,'String','RPA','FontSize',12,'FontWeight','bold','Color','k');
                scatter3(obj.fiducials.vertex(1),obj.fiducials.vertex(2),obj.fiducials.vertex(3),'filled','MarkerEdgeColor','k','MarkerFaceColor','K');
                text('Position',1.1*obj.fiducials.vertex,'String','Ver','FontSize',12,'FontWeight','bold','Color','k');
                scatter3(obj.fiducials.inion(1),obj.fiducials.inion(2),obj.fiducials.inion(3),'filled','MarkerEdgeColor','k','MarkerFaceColor','K');
                text('Position',1.1*obj.fiducials.inion,'String','Ini','FontSize',12,'FontWeight','bold','Color','k');
            end
            hold off;
            axis equal
            axis vis3d
            grid on;
        end
        %%
        function warpedTemplateObj = warpTemplate(obj,templateObj)
            % Warps a template head model to the space defined by the sensor positions (channelSpace) using Dirk-Jan Kroon's
            % nonrigid_version23 toolbox.
            %
            % For more details see: http://www.mathworks.com/matlabcentral/fileexchange/20057-b-spline-grid-image-and-point-based-registration
            % 
            % Input arguments:
            %       templateObj:             head model object that will be warped
            %
            % Output arguments:
            %       warpedSourceObj: warped head model
            %
            % References: 
            %    D. Rueckert et al. "Nonrigid Registration Using Free-Form Deformations: Application to Breast MR Images".
            %    Seungyong Lee, George Wolberg, and Sung Yong Shing, "Scattered Data interpolation with Multilevel B-splines"

            if nargin < 2, error('Reference head model is missing.');end
            if isempty(obj.channelSpace) || isempty(obj.labels), error('"channelSpace" or "labels" are missing.');end
            
            gTools = geometricTools;
            th = norminv(0.90);
            % mapping source to target spaces: S->T
            % target space: individual geometry
            
            try
                T = [obj.fiducials.nasion;...
                    obj.fiducials.lpa;...
                    obj.fiducials.rpa];
                
                % source space: template
                S = [templateObj.fiducials.nasion;...
                    templateObj.fiducials.lpa;...
                    templateObj.fiducials.rpa;...
                    templateObj.fiducials.vertex];
                
                % estimates vertex if is missing
                if isfield(obj.fiducials,'vertex')
                    if numel(obj.fiducials.vertex) == 3
                        T = [T;obj.fiducials.vertex];
                    else
                        point = 0.5*(obj.fiducials.lpa + obj.fiducials.rpa);
                        point = ones(50,1)*point;
                        point(:,3) = linspace(point(3),1.5*max(obj.channelSpace(:,3)),50)';
                        [~,d] = gTools.nearestNeighbor(obj.channelSpace,point);
                        [~,loc] = min(d);
                        point = point(loc,:);
                        T = [T;point];
                    end
                else
                    point = 0.5*(obj.fiducials.lpa + obj.fiducials.rpa);
                    point = ones(50,1)*point;
                    point(:,3) = linspace(point(3),1.5*max(obj.channelSpace(:,3)),50)';
                    [~,d] = gTools.nearestNeighbor(obj.channelSpace,point);
                    [~,loc] = min(d);
                    point = point(loc,:);
                    T = [T;point];
                end
                
                if isfield(obj.fiducials,'inion')
                    if numel(obj.fiducials.vertex) == 3
                        T = [T;obj.fiducials.inion];
                        S = [S;templateObj.fiducials.inion];
                    end
                end
            catch
                disp('Fiducials are missing in the individual head model, selecting the common set of points based on the channel labels.')
                [~,loc1,loc2] = intersect(obj.labels,templateObj.labels,'stable');
                T = obj.channelSpace(loc1,:);
                S = templateObj.channelSpace(loc2,:);
            end
                        
            % Affine co-registration
            [Aff,~,scale] = gTools.affineMapping(S,T);
            
            % Affine warping
            surfData = [templateObj.scalp;templateObj.outskull;templateObj.inskull;templateObj.cortex];
            Ns = length(surfData);
            for it=1:Ns
                surfData(it).vertices = gTools.applyAffineMapping(surfData(it).vertices,Aff);
            end
            warpedChannelSpace = gTools.applyAffineMapping(templateObj.channelSpace,Aff);
            
            % b-spline co-registration (only fiducial landmarks)
            options.Verbose = true;
            options.MaxRef = 2;
            Saff = gTools.applyAffineMapping(S,Aff);
            [Def,spacing,offset] = gTools.bSplineMapping(Saff,T,surfData(1).vertices,options);
            
            % b-spline co-registration (second pass)
            for it=1:Ns
                surfData(it).vertices = gTools.applyBSplineMapping(Def,spacing,offset,surfData(it).vertices);
            end
            T = obj.channelSpace;
            T(T(:,3) <= min(surfData(1).vertices(:,3)),:) = [];
            [T,d] = gTools.nearestNeighbor(S,T);
            z = zscore(d);
            S(abs(z)>th,:) = [];
            T(abs(z)>th,:) = [];
            [Def,spacing,offset] = gTools.bSplineMapping(S,T,surfData(1).vertices,options);
            
            % b-spline co-registration (third pass)
            for it=1:Ns
                surfData(it).vertices = gTools.applyBSplineMapping(Def,spacing,offset,surfData(it).vertices);
            end
            T = obj.channelSpace;
            T(T(:,3) <= min(surfData(1).vertices(:,3)),:) = [];
            [T,d] = gTools.nearestNeighbor(S,T);
            z = zscore(d);
            S(abs(z)>th,:) = [];
            T(abs(z)>th,:) = [];
            Tm = 0.5*(T+S);
            [Def,spacing,offset] = gTools.bSplineMapping(S,Tm,surfData(1).vertices,options);
            
            % apply the final transformation
            for it=1:Ns
                surfData(it).vertices = gTools.applyBSplineMapping(Def,spacing,offset,surfData(it).vertices);
                surfData(it).vertices = gTools.smoothSurface(surfData(it).vertices,surfData(it).faces);
            end
            warpedTemplateObj = headModel({'channelSpace',warpedChannelSpace,'labels',templateObj.labels,...
                'K',[],'L',templateObj.L,'atlas',templateObj.atlas,'scalp',surfData(1),'outskull',...
                surfData(2),'inskull',surfData(3),'cortex',surfData(4)});
            disp('Done!')
        end
        %%
        function Aff = warpToTemplate(obj,templateObj,regType)
            % Estimates a mapping from this head to a template's head.
            % It uses Dirk-Jan Kroon's nonrigid_version23 toolbox.
            %
            % For more details see: http://www.mathworks.com/matlabcentral/fileexchange/20057-b-spline-grid-image-and-point-based-registration
            %
            % Input arguments:
            %       templateObj:             Template head model.
            %       regType:                 co-registration type, could be 'affine' or 'bspline'. In case
            %                                of 'affine' only the affine mapping is estimated (rotation,
            %                                traslation, and scaling). 'bspline' starts from the affine 
            %                                mapping and goes on to estimate a non-linear defformation
            %                                field that captures better the shape of the head.
            %
            % Output arguments:
            %       Aff: affine matrix
            %
            % References: 
            %    D. Rueckert et al. "Nonrigid Registration Using Free-Form Deformations: Application to Breast MR Images".
            %    Seungyong Lee, George Wolberg, and Sung Yong Shing, "Scattered Data interpolation with Multilevel B-splines"

            if nargin < 2, error('Reference head model is missing.');end
            if nargin < 3, regType = 'bspline';end
            if isempty(obj.channelSpace) || isempty(obj.labels), error('"channelSpace" or "labels" are missing.');end
            
            gTools = geometricTools;
            th = norminv(0.90);
            % mapping source to target spaces: S->T
            % target space: template
            
            try
                T = [templateObj.fiducials.nasion;...
                    templateObj.fiducials.lpa;...
                    templateObj.fiducials.rpa;...
                    templateObj.fiducials.vertex];
                
                % source space: individual geometry
                S = [obj.fiducials.nasion;...
                    obj.fiducials.lpa;...
                    obj.fiducials.rpa];
                
                % estimates vertex if is missing
                if isfield(obj.fiducials,'vertex')
                    if numel(obj.fiducials.vertex) == 3
                        S = [S;obj.fiducials.vertex];
                    else
                        point = 0.5*(obj.fiducials.lpa + obj.fiducials.rpa);
                        point = ones(50,1)*point;
                        point(:,3) = linspace(point(3),1.5*max(obj.channelSpace(:,3)),50)';
                        [~,d] = gTools.nearestNeighbor(obj.channelSpace,point);
                        [~,loc] = min(d);
                        point = point(loc,:);
                        S = [S;point];
                    end
                else
                    point = 0.5*(obj.fiducials.lpa + obj.fiducials.rpa);
                    point = ones(50,1)*point;
                    point(:,3) = linspace(point(3),1.5*max(obj.channelSpace(:,3)),50)';
                    [~,d] = gTools.nearestNeighbor(obj.channelSpace,point);
                    [~,loc] = min(d);
                    point = point(loc,:);
                    S = [S;point];
                end
                
                if isfield(obj.fiducials,'inion')
                    if numel(obj.fiducials.vertex) == 3
                        S = [S;obj.fiducials.inion];
                        T = [T;templateObj.fiducials.inion];
                    end
                end
            catch
                disp('Fiducials are missing in the individual head model, selecting the common set of points based on the channel labels.')
                [~,loc1,loc2] = intersect(lower(obj.labels),lower(templateObj.labels),'stable');
                S = obj.channelSpace(loc1,:);
                T = templateObj.channelSpace(loc2,:);
            end
            if isa(obj,'eeg')
                obj.initStatusbar(1,8,'Co-registering...');
            else
                disp('Co-registering...');
            end
            
            % affine co-registration
            Aff = gTools.affineMapping(S,T);
            if isa(obj,'eeg'), obj.statusbar(1);end
            
            obj.channelSpace = gTools.applyAffineMapping(obj.channelSpace,Aff);
            if ~isempty(obj.fiducials)
                obj.fiducials.lpa = gTools.applyAffineMapping(obj.fiducials.lpa,Aff);
                obj.fiducials.rpa = gTools.applyAffineMapping(obj.fiducials.rpa,Aff);
                obj.fiducials.nasion = gTools.applyAffineMapping(obj.fiducials.nasion,Aff);
            end
            if ~strcmp(regType,'affine')
                % b-spline co-registration (coarse warping)
                options.Verbose = true;
                options.MaxRef = 2;
                Saff = gTools.applyAffineMapping(S,Aff);
                [Def,spacing,offset] = gTools.bSplineMapping(Saff,T,obj.channelSpace,options);
                if isa(obj,'eeg'), obj.statusbar(2);end
                obj.channelSpace = gTools.applyBSplineMapping(Def,spacing,offset,obj.channelSpace);
                if ~isempty(obj.fiducials)
                    obj.fiducials.lpa = gTools.applyBSplineMapping(Def,spacing,offset,obj.fiducials.lpa);
                    obj.fiducials.rpa = gTools.applyBSplineMapping(Def,spacing,offset,obj.fiducials.rpa);
                    obj.fiducials.nasion = gTools.applyBSplineMapping(Def,spacing,offset,obj.fiducials.nasion);
                end
                
                % b-spline co-registration (detailed warping)
                for it=1:3
                    T = templateObj.scalp.vertices;
                    S = obj.channelSpace;
                    S(S(:,3) <= min(T(:,3)),:) = [];
                    [T,d] = gTools.nearestNeighbor(S,T);
                    z = zscore(d);
                    S(abs(z)>th,:) = [];
                    T(abs(z)>th,:) = [];
                    [Def,spacing,offset] = gTools.bSplineMapping(S,T,obj.channelSpace,options);
                    obj.channelSpace = gTools.applyBSplineMapping(Def,spacing,offset,obj.channelSpace);
                    if ~isempty(obj.fiducials)
                        obj.fiducials.lpa = gTools.applyBSplineMapping(Def,spacing,offset,obj.fiducials.lpa);
                        obj.fiducials.rpa = gTools.applyBSplineMapping(Def,spacing,offset,obj.fiducials.rpa);
                        obj.fiducials.nasion = gTools.applyBSplineMapping(Def,spacing,offset,obj.fiducials.nasion);
                    end
                    if ~isempty(obj.outskull)
                        obj.scalp.vertices = gTools.applyBSplineMapping(Def,spacing,offset,obj.scalp.vertices);
                        obj.outskull.vertices = gTools.applyBSplineMapping(Def,spacing,offset,obj.outskull.vertices);
                        obj.inskull.vertices = gTools.applyBSplineMapping(Def,spacing,offset,obj.inskull.vertices);
                        obj.cortex.vertices = gTools.applyBSplineMapping(Def,spacing,offset,obj.cortex.vertices);
                    end
                end
            end
        end
        %%
        function computeLeadFieldBEM(obj, conductivity,orientation)
            % Computes the lead field matrix interfacing OpenMEEG toolbox [1].
            %
            % Input arguments:
            %       conductivity: conductivity of each layer of tissue, scalp - skull - brain,
            %                     default: 0.33-0.022-0.33 S/m. See [2, 3, 4] for details.
            %        orientation: if true, computes the orientation free lead field, otherwise
            %                     it constrain the dipoles to be normal to the cortical surface
            %
            % The computed lead field is stored inside the object in obj.leadFieldFile.
            %
            % References:
            %   [1] Gramfort, A., Papadopoulo, T., Olivi, E., & Clerc, M. (2010).
            %         OpenMEEG: opensource software for quasistatic bioelectromagnetics.
            %         Biomedical engineering online, 9, 45. doi:10.1186/1475-925X-9-45
            %   [2] Vald??s-Hern??ndez, P.A., Von Ellenrieder, N., Ojeda-Gonzalez, A., Kochen, S.,
            %         Alem??n-G??mez, Y., Muravchik, C., & A Vald??s-Sosa, P. (2009). Approximate
            %         average head models for EEG source imaging. Journal of Neuroscience Methods,
            %         185(1), 125???132.
            %   [3] Wendel, K., Malmivuo, J., 2006. Correlation between live and post mortem skull
            %         conductivity measurements. Conf Proc IEEE Eng Med Biol Soc 1, 4285-4288.
            %   [4] Oostendorp, T.F., Delbeke, J., Stegeman, D.F., 2000. The conductivity of the 
            %         human skull: Results of in vivo and in vitro measurements. Ieee Transactions
            %         on Biomedical Engineering 47, 1487-1492.
                        
            if nargin < 2, conductivity = [0.33 0.022 0.33];end
            if nargin < 3, orientation = true;end
            if isempty(obj.channelSpace), error('"channelSpace" is missing.');end
            if isempty(obj.scalp) || isempty(obj.outskull) || isempty(obj.inskull) || isempty(obj.cortex),
                error('The file containing the surfaces is missing.');
            end
            status = system('which om_assemble');
            existOM = ~status;
            if ~existOM
                error('OpenMEEG is not intalled. Please download and install the sources you need from https://gforge.inria.fr/frs/?group_id=435.');
            end
            
            gTools = geometricTools;            
            rootDir = tempdir;
            binDir = fileparts(which('libmatio.a'));
            [~,rname] = fileparts(tempname);
            headModelGeometry = fullfile(rootDir,[rname '.geom']);
            try %#ok
                copyfile(which('head_model.geom'),headModelGeometry,'f');
                c1 = onCleanup(@()delete(headModelGeometry));
            end
            headModelConductivity = fullfile(rootDir,[rname '.cond']);
            fid = fopen(headModelConductivity,'w');
            fprintf(fid,'# Properties Description 1.0 (Conductivities)\n\nAir         0.0\nScalp       %.3f\nBrain       %0.3f\nSkull       %0.3f',...
                conductivity(1),conductivity(3),conductivity(2));
            fclose(fid);
            c2 = onCleanup(@()delete(headModelConductivity));
            
            dipolesFile = fullfile(rootDir,[rname '_dipoles.txt']);
            normalsIn = false;
            [normals,obj.cortex.faces] = gTools.getSurfaceNormals(obj.cortex.vertices,obj.cortex.faces,normalsIn);
            
            normalityConstrained = ~orientation;
            if normalityConstrained, sourceSpace = [obj.cortex.vertices normals];
            else One = ones(length(normals(:,2)),1);
                Zero = 0*One;
                sourceSpace = [obj.cortex.vertices One Zero Zero;...
                    obj.cortex.vertices Zero One Zero;...
                    obj.cortex.vertices Zero Zero One];
            end
            dlmwrite(dipolesFile, sourceSpace, 'precision', 6,'delimiter',' ')
            c3 = onCleanup(@()delete(dipolesFile));
            
            electrodesFile = fullfile(rootDir,[rname '_elec.txt']);
            dlmwrite(electrodesFile, obj.channelSpace, 'precision', 6,'delimiter',' ')
            c4 = onCleanup(@()delete(electrodesFile));
            
            normalsIn = true;
            brain = fullfile(rootDir,'brain.tri');
            [normals,obj.inskull.faces] = gTools.getSurfaceNormals(obj.inskull.vertices,obj.inskull.faces,normalsIn);
            om_save_tri(brain,obj.inskull.vertices,obj.inskull.faces,normals)
            c5 = onCleanup(@()delete(brain));
            
            skull = fullfile(rootDir,'skull.tri');
            [normals,obj.outskull.faces] = gTools.getSurfaceNormals(obj.outskull.vertices,obj.outskull.faces,normalsIn);
            om_save_tri(skull,obj.outskull.vertices,obj.outskull.faces,normals)
            c6 = onCleanup(@()delete(skull));
            
            head = fullfile(rootDir,'head.tri');
            [normals,obj.scalp.faces] = gTools.getSurfaceNormals(obj.scalp.vertices,obj.scalp.faces,normalsIn);
            om_save_tri(head,obj.scalp.vertices,obj.scalp.faces,normals)
            c7 = onCleanup(@()delete(head));
            
            hmFile    = fullfile(rootDir,'hm.bin');    c8  = onCleanup(@()delete(hmFile));
            hmInvFile = fullfile(rootDir,'hm_inv.bin');c9  = onCleanup(@()delete(hmInvFile));
            dsmFile   = fullfile(rootDir,'dsm.bin');   c10 = onCleanup(@()delete(dsmFile));
            h2emFile  = fullfile(rootDir,'h2em.bin');  c11 = onCleanup(@()delete(h2emFile));
            lfFile    = fullfile(rootDir,[rname '_LF.mat']);
            
            if ~existOM
                runHere = './';
                wDir = pwd;
                cd(binDir);
            else runHere = '';
            end
            try
                out = system([runHere 'om_assemble -HM "' headModelGeometry '" "' headModelConductivity '" "' hmFile '"']);
                if out, error('An unexpected error occurred running OpenMEEG binaries. Report this to alejandro@sccn.ucsd.edu');end
                
                out = system([runHere 'om_minverser "' hmFile '" "' hmInvFile '"']);
                if out, error('An unexpected error occurred running OpenMEEG binaries. Report this to alejandro@sccn.ucsd.edu');end
                
                out = system([runHere 'om_assemble -DSM "' headModelGeometry '" "' headModelConductivity '" "' dipolesFile '" "' dsmFile '"']);
                if out, error('An unexpected error occurred running OpenMEEG binaries. Report this to alejandro@sccn.ucsd.edu');end
                
                out = system([runHere 'om_assemble -H2EM "' headModelGeometry '" "' headModelConductivity '" "' electrodesFile '" "' h2emFile '"']);
                if out, error('An unexpected error occurred running OpenMEEG binaries. Report this to alejandro@sccn.ucsd.edu');end
                
                out = system([runHere 'om_gain -EEG "' hmInvFile '" "' dsmFile '" "' h2emFile '" "' lfFile '"']);
                if out, error('An unexpected error occurred running OpenMEEG binaries. Report this to alejandro@sccn.ucsd.edu');end
            catch ME
                if strcmp(pwd,binDir), cd(wDir);end
                ME.rethrow;
            end
            if strcmp(pwd,binDir), cd(wDir);end
            if ~exist(lfFile,'file'), error('An unexpected error occurred running OpenMEEG binaries. Report this to alejandro@sccn.ucsd.edu');end
                        
            load(lfFile);
            obj.K = linop;
            clear linop;
            if exist(lfFile,'file'), delete(lfFile);end
            disp('Done.')
        end
        %%
        function [Ht,K,L,ind] = svd4KalmanFilter(obj, structName, rmIndices,model_order)
            if nargin < 2
                structName = {'Thalamus_L' 'Thalamus_R'};
                disp('Undefined structure to remove. Opening the surface by the Thalamus.')
            end
            if nargin < 3, rmIndices = [];end
            [~, ~,~, K,ind,~,L] = svd4sourceLoc(obj, structName, rmIndices);
            [Nch,Ns] = size(K);
            Ht = [K/L zeros(Nch,(model_order-1)*Ns)];
        end
        function [Ut, s2,iLV, Kstd,ind,K,L] = svd4sourceLoc(obj, structName, rmIndices)
            if nargin < 2
                structName = {'Thalamus_L' 'Thalamus_R'};
                disp('Undefined structure to remove. Opening the surface by the Thalamus.')
            end
            if nargin < 3, rmIndices = [];end
            [~,K,L,rmIndices] = getSourceSpace4PEB(obj,structName, rmIndices);
            Ns = size(obj.cortex.vertices,1);
            ind = setdiff(1:Ns,rmIndices);
            Ny = size(obj.K,1);
            H = eye(Ny)-ones(Ny)/Ny;
            K = H*K;
            Kstd = bsxfun(@rdivide,K,std(K,[],1)+eps);
            [U,S,V] = svd(Kstd/L,'econ');
            Ut = U';
            iLV = L\V;
            s2 = diag(S).^2;
        end
        %%
        function [Ut, s2,iHsqrtV, Klb, B, Hsqrt] = svd4sourceLocLB(obj,numberOfBasis)
            persistent P
            if nargin < 2, numberOfBasis = 128;end
            if isempty(obj.K)
                error('Need to compute leead field matrix first!');
            end
            K = obj.K;
            L = obj.L;
            %--
            if isempty(P) || size(P,2) ~= numberOfBasis+2
                [A,C] = FEM(obj.cortex);
                [P,~] = eigs(C,A,numberOfBasis+10,'sm');
            end
            B = -P(:,1:numberOfBasis);
            %--
            LtL = sqrtm(full(L'*L));
            H = B'*LtL*B;
            H = sqrtm(full(H*H'));
            Hsqrt = chol(H);
            %--
            Kstd = bsxfun(@rdivide,K,std(K,[],1)+eps);
            Klb = Kstd*B;
            [U,S,V] = svd(Klb/Hsqrt,'econ');
            Ut = U';
            iHsqrtV = Hsqrt\V;
            s = diag(S);
            s2 = s.^2;
        end
        %%
        function [sourceSpace,K,L,rmIndices] = getSourceSpace4PEB(obj,structName, rmIndices)
            if nargin < 2
                structName = {'Thalamus_L' 'Thalamus_R'};
                disp('Undefined structure to remove. Opening the surface by the Thalamus.')
            end
            if nargin < 3, rmIndices = [];end
            if isempty(obj.K)
                error('Need to compute leead field matrix first!');
            end
            K = obj.K;
            L = obj.L;
            maxNumVertices2rm = 10;
            sourceSpace = obj.cortex;
            try
                [sourceSpace,rmIndices] = obj.removeStructureFromSourceSpace(structName,maxNumVertices2rm, rmIndices);
            catch ME
                warning(ME.message);
                disp('Doing my best to open the surface.')
                n = size(sourceSpace.vertices,1);
                rmIndices = fix(n/2)-maxNumVertices2rm/2:fix(n/2)+maxNumVertices2rm/2;
                [sourceSpace.vertices, sourceSpace.faces] = geometricTools.openSurface(sourceSpace.vertices,sourceSpace.faces,rmIndices);
            end
            dim = size(K);
            L(rmIndices,:) = [];
            L(:,rmIndices) = [];
            if dim(2)/3 == size(obj.cortex.vertices,1)
                K = reshape(K,[dim(1) dim(2)/3 3]);
                K(:,rmIndices,:) = [];
                % K = permute(K,[1 3 2]);
                K = reshape(K,[dim(1) (dim(2)/3-length(rmIndices))*3]);
                L = kron(eye(3),L);
            else
                K(:,rmIndices) = [];
            end
        end
       %%
        function indices = indices4Structure(obj,structName)
            if nargin < 2, error('Not enough input arguments.');end
            if iscellstr(structName)
                ind = [];
                for k=1:length(structName)
                    ind = [ind find(ismember(obj.atlas.label,structName{k}))];
                end
            else
                ind = find(ismember(obj.atlas.label,structName));
            end
            ind = ind(:);
            if isempty(ind), error('The structure you want to remove is not defined in this atlas.');end
            indices = bsxfun(@eq,obj.atlas.colorTable,ind');
        end
       %%
        function xyz = getCentroidROI(obj,ROInames)
            if nargin < 2, error('Not enough input arguments.');end
            if isempty(obj.atlas) || isempty(obj.cortex), error('"cortex" or "atlas" are empty.');end
            if ~iscell(ROInames), ROInames = {ROInames}; end
            N = length((ROInames));
            xyz = nan(N,3);
            for it=1:N
                try indices = obj.indices4Structure(ROInames{it});
                    xyz(it,:) = median(obj.cortex.vertices(indices,:));
                end
            end
        end
       %%
        function [FP,S] = getForwardProjection(obj,xyz)
            if nargin < 2, error('Not enough input arguments.');end
            if isempty(obj.atlas), error('The atlas is missing.');end
            if isempty(obj.K), error('Need to compute lead field first!');end
            [~,~,loc] = geometricTools.nearestNeighbor(obj.cortex.vertices,xyz);
            K = obj.K;
            dim = size(K);
            if size(obj.cortex.vertices,1) == dim(2)/3, K = reshape(K,[dim(1) dim(2)/3 3]);end
            FP = sum(K(:,loc,:),3);
            S = geometricTools.simulateGaussianSource(obj.cortex.vertices,xyz,0.016);
        end
       %%
        function hFigureObj = plotDipoles(obj,xyz,ecd,dipoleLabel,figureTitle)
            if nargin < 2, error('Not enough input arguments.');end
            N = size(xyz,1);
            if nargin < 3, ecd = 3*ones(N,3);end
            if isempty(ecd), ecd = 3*ones(N,3);end
            if nargin < 4, dipoleLabel = [];end
            if nargin < 5, figureTitle = '';end
            hFigureObj = equivalentCurrentDipoleViewer(obj,xyz,ecd,dipoleLabel,figureTitle);
        end
        function hFigureObj = plotDipolesForwardProjection(obj,xyz,figureTitle,autoscale,fps)
            if nargin < 3, figureTitle = '';end
            if nargin < 4, autoscale = false;end
            if nargin < 5, fps = 30;end
            [FP,S] = getForwardProjection(obj,xyz);
            hFigureObj = obj.plotOnModel(S,FP,figureTitle,autoscale,fps);
            
        end
       %%
        function [sourceSpace,rmIndices] = removeStructureFromSourceSpace(obj,structName,maxNumVertices2rm, structIndices)
            if isempty(obj.atlas) || isempty(obj.cortex), error('"atlas" or "cortex" are empty.');end
            if nargin < 2, error('Not enough input arguments.');end
            if nargin < 3, maxNumVertices2rm = [];end
            if nargin < 4, structIndices = [];end
            if ~iscell(structName), structName = {structName}; end
            sourceSpace = obj.cortex;
            if ~isempty(structName)
                tmpIndices = indices4Structure(obj,structName);
            else
                tmpIndices = [];
            end
            if ~any(tmpIndices(:)) && isempty(structIndices),
                error('The structure you want to remove is not defined in this atlas.');
            end
            if ~isempty(structIndices)
                % concatenate elements of structIndices into a single column vector
                structIndices = cellfun(@(x)x(:),structIndices,'UniformOutput',false)';
                structIndices = cell2mat(structIndices);
            end
            if ~isempty(maxNumVertices2rm) && any(sum(tmpIndices) > maxNumVertices2rm+1)
                I = [];
                maxNumVertices2rm = fix(maxNumVertices2rm/size(tmpIndices,2));
                for it=1:size(tmpIndices,2)
                    ind = find(tmpIndices(:,it));
                    if length(ind) > maxNumVertices2rm
                        I = [I; ind(1:maxNumVertices2rm)];
                    else
                        I = [I; ind];
                    end
                end
                tmpIndices = I;
            end
            rmIndices = unique_bc([tmpIndices(:) ; structIndices]);
            [nVertices,nFaces] = geometricTools.openSurface(sourceSpace.vertices,sourceSpace.faces,rmIndices);
            sourceSpace.vertices = nVertices;
            sourceSpace.faces = nFaces;
        end
        %%
        function chanlocs = makeChanlocs(obj)
            % make EEGLAB chanlocs structure from channel locations and
            % labels
            if isempty(which('convertlocs'))
                error('EEGLAB function convertlocs.m is missing.');
            end
            for k=1:length(obj.labels)
                chanlocs(k) = struct('labels',obj.labels{k}, ...
                                     'ref','', ...
                                     'theta',[], ...
                                     'radius',[], ...
                                     'X',obj.channelSpace(k,1), ...
                                     'Y',obj.channelSpace(k,2), ...
                                     'Z',obj.channelSpace(k,3), ...
                                     'sph_theta', [], ...
                                     'sph_phi',[], ...
                                     'sph_radius',[], ...
                                     'type', 'EEG', ...
                                     'urchan', []);
            end
            chanlocs = convertlocs( chanlocs, 'cart2all');
        end
        %%
        function saveToFile(obj,filename)
            if nargin < 2,
                error('Need to pass in the name of the file where to save the object.')
            end
            pname = properties(obj);
            s = struct();
            for k=1:length(pname)
                s.(pname{k}) = obj.(pname{k});
            end
            s.version = 2;
            save(filename,'-struct','s');
        end
        function delete(obj)
            for k=1:length(obj.tmpFiles)
                if exist(obj.tmpFiles{k},'file')
                    delete(obj.tmpFiles{k});
                end
            end
        end
        
        %% Deprecated fields and methods
        function surfaces = get.surfaces(obj)
            surfData = [obj.scalp;obj.outskull;obj.inskull;obj.cortex];
            surfaces = tempname;
            save(surfaces,'surfData');
            obj.tmpFiles{end+1} = surfaces;
            warning('"surfaces" has been deprecated, instead you can access directly the properties "scalp", "outskull", "inskull", or "cortex".')
        end
        function leadFieldFile = get.leadFieldFile(obj)
            leadFieldFile = tempname;
            K = obj.K;
            L = obj.L;
            save(leadFieldFile,'K','L');
            obj.tmpFiles{end+1} = leadFieldFile;
            warning('"leadFieldFile" has been deprecated, instead you can access directly the properties "K" and "L".');
        end
        function cobj = copy(obj)
            filename = tempname;
            obj.saveToFile(filename)
            cobj = headModel.loadFromFile(filename);
            delete(filename);
        end
        function labels = getChannelLabels(obj)
            labels = obj.labels;
            warning('This method hass been deprecated, instead you can access directly the property "labels".')
        end
        function channelLabel = get.channelLabel(obj)
            channelLabel = obj.labels;
            warning('This method hass been deprecated, instead you can access directly the property "labels".')
        end
        function h = plotHeadModel(obj)
            h = plot(obj);
            warning('This method hass been deprecated, instead you can use "plot".')
        end
        function individualHeadModelFile = warpTemplate2channelSpace(obj,headModelFile,individualHeadModelFile)
            % Warps a template head model to the space defined by the sensor positions (channelSpace). It uses Dirk-Jan Kroon's
            % nonrigid_version23 toolbox.
            %
            % For more details see: http://www.mathworks.com/matlabcentral/fileexchange/20057-b-spline-grid-image-and-point-based-registration
            % 
            % Input arguments:
            %       headModelFile:           pointer to the template head model file. To see an example of
            %                                templates see the folder mobilab/data/headModelXX.mat
            %       individualHeadModelFile: pointer to the warped head model (output file)
            % 
            % Output arguments:
            %       individualHeadModelFile: pointer to the warped head model (same as the second input argument)
            %
            % References: 
            %    D. Rueckert et al. "Nonrigid Registration Using Free-Form Deformations: Application to Breast MR Images".
            %    Seungyong Lee, George Wolberg, and Sung Yong Shing, "Scattered Data interpolation with Multilevel B-splines"

            if nargin < 2, error('Reference head model is missing.');end
            if nargin < 3, individualHeadModelFile = [tempname '.mat'];end
            if isempty(obj.channelSpace) || isempty(obj.label), error('Channel space or labels are missing.');end
            if ~exist(headModelFile,'file'), error('The file you''ve entered does not exist.');end
            
            warning('This method hass been deprecated, instead you can use "warpTemplate".')
            template = load(headModelFile);
            if isfield(template,'metadata')
                tmp = headModel.loadFromFile(headModelFile);
                template = template.metadata;
                load(tmp.surfaces)
                template.surfData = surfData;
            end
            gTools = geometricTools;
            th = norminv(0.90);
            % mapping source to target spaces: S->T
            % target space: individual geometry
            
            try
                T = [obj.fiducials.nasion;...
                    obj.fiducials.lpa;...
                    obj.fiducials.rpa];
                
                % source space: template
                S = [template.fiducials.nasion;...
                    template.fiducials.lpa;...
                    template.fiducials.rpa;...
                    template.fiducials.vertex];
                
                % estimates vertex if is missing
                if isfield(obj.fiducials,'vertex')
                    if numel(obj.fiducials.vertex) == 3
                        T = [T;obj.fiducials.vertex];
                    else
                        point = 0.5*(obj.fiducials.lpa + obj.fiducials.rpa);
                        point = ones(50,1)*point;
                        point(:,3) = linspace(point(3),1.5*max(obj.channelSpace(:,3)),50)';
                        [~,d] = gTools.nearestNeighbor(obj.channelSpace,point);
                        [~,loc] = min(d);
                        point = point(loc,:);
                        T = [T;point];
                    end
                else
                    point = 0.5*(obj.fiducials.lpa + obj.fiducials.rpa);
                    point = ones(50,1)*point;
                    point(:,3) = linspace(point(3),1.5*max(obj.channelSpace(:,3)),50)';
                    [~,d] = gTools.nearestNeighbor(obj.channelSpace,point);
                    [~,loc] = min(d);
                    point = point(loc,:);
                    T = [T;point];
                end
                
                if isfield(obj.fiducials,'inion')
                    if numel(obj.fiducials.vertex) == 3
                        T = [T;obj.fiducials.inion];
                        S = [S;template.fiducials.inion];
                    end
                end
            catch
                disp('Fiducials are missing in the individual head model, selecting the common set of points based on the channel labels.')
                [~,loc1,loc2] = intersect(obj.getChannelLabels,template.label,'stable');
                T = obj.channelSpace(loc1,:);
                S = template.channelSpace(loc2,:);
            end
            try obj.initStatusbar(1,8,'Co-registering...');end %#ok
            
            % affine co-registration
            [Aff,~,scale] = gTools.affineMapping(S,T);
            if isa(obj,'eeg'), obj.statusbar(1);end
            
            % b-spline co-registration (only fiducial landmarks)
            options.Verbose = true;
            options.MaxRef = 2;
            surfData = template.surfData;
            Ns = length(surfData);
            for it=1:Ns
                surfData(it).vertices = gTools.applyAffineMapping(template.surfData(it).vertices,Aff);
            end
            Saff = gTools.applyAffineMapping(S,Aff);
            [Def,spacing,offset] = gTools.bSplineMapping(Saff,T,surfData(1).vertices,options);
            try obj.statusbar(2);end %#ok
            
            % b-spline co-registration (second pass)
            for it=1:Ns
                surfData(it).vertices = gTools.applyBSplineMapping(Def,spacing,offset,surfData(it).vertices);
            end
            T = obj.channelSpace;
            T(T(:,3) <= min(surfData(1).vertices(:,3)),:) = [];
            [S,d] = gTools.nearestNeighbor(surfData(1).vertices,T);
            z = zscore(d);
            S(abs(z)>th,:) = [];
            T(abs(z)>th,:) = [];
            [Def,spacing,offset] = gTools.bSplineMapping(S,T,surfData(1).vertices,options);
            try obj.statusbar(3);end %#ok
            
            % b-spline co-registration (third pass)
            for it=1:Ns
                surfData(it).vertices = gTools.applyBSplineMapping(Def,spacing,offset,surfData(it).vertices);
            end
            T = obj.channelSpace;
            T(T(:,3) <= min(surfData(1).vertices(:,3)),:) = [];
            [S,d] = gTools.nearestNeighbor(surfData(1).vertices,T);
            z = zscore(d);
            S(abs(z)>th,:) = [];
            T(abs(z)>th,:) = [];
            Tm = 0.5*(T+S);
            [Def,spacing,offset] = gTools.bSplineMapping(S,Tm,surfData(1).vertices,options);
            try obj.statusbar(4);end %#ok
            
            % apply the final transformation
            for it=1:Ns
                surfData(it).vertices = gTools.applyBSplineMapping(Def,spacing,offset,surfData(it).vertices);
                surfData(it).vertices = gTools.smoothSurface(surfData(it).vertices,surfData(it).faces);
            end
           
            ind =  obj.channelSpace(:,3) > min(surfData(1).vertices(:,3));
            T = gTools.nearestNeighbor(surfData(1).vertices,obj.channelSpace);
            channelSpace = obj.channelSpace; %#ok
            channelSpace(ind,:) = T(ind,:);  %#ok
            [~,loc] = unique(channelSpace,'rows');%#ok
            indInterp = setdiff(1:size(obj.channelSpace,1),loc);
            if ~isempty(indInterp)
                x = setdiff(channelSpace,channelSpace(indInterp,:),'rows');%#ok
                xi = gTools.nearestNeighbor(x,channelSpace(indInterp,:));%#ok
                channelSpace(indInterp,:) = 0.5*(xi + channelSpace(indInterp,:));%#ok
            end
            obj.channelSpace = channelSpace; %#ok
            
            if isfield(template,'atlas'), 
                if isfield(template.atlas,'color')
                    colorTable = template.atlas.color;
                    template.atlas = rmfield(template.atlas,'color');
                    template.atlas.colorTable = colorTable;
                end
                obj.atlas = template.atlas;
            end
            if exist(obj.surfaces,'file'), delete(obj.surfaces);end
            obj.surfaces = individualHeadModelFile;
            save(obj.surfaces,'surfData');
            try obj.statusbar(8);end %#ok
            disp('Done!')
        end
        function Aff = warpChannelSpace2Template(obj,headModelFile,individualHeadModelFile,regType)
            % Estimates a mapping from channel space to a template's head. It uses Dirk-Jan Kroon's
            % nonrigid_version23 toolbox.
            %
            % For more details see: http://www.mathworks.com/matlabcentral/fileexchange/20057-b-spline-grid-image-and-point-based-registration
            %
            % Input arguments:
            %       headModelFile:           pointer to the template head model file. To see an example
            %                                of templates see the folder mobilab/data/headModelXX.mat
            %       individualHeadModelFile: pointer to the warped head model (output file)
            %       regType:                 co-registration type, could be 'affine' or 'bspline'. In case
            %                                of 'affine' only the affine mapping is estimated (rotation,
            %                                traslation, and scaling). 'bspline' starts from the affine 
            %                                mapping and goes on to estimate a non-linear defformation
            %                                field that captures better the shape of the head.
            %
            % Output arguments:
            %       Aff: affine matrix
            %
            % References: 
            %    D. Rueckert et al. "Nonrigid Registration Using Free-Form Deformations: Application to Breast MR Images".
            %    Seungyong Lee, George Wolberg, and Sung Yong Shing, "Scattered Data interpolation with Multilevel B-splines"

            if nargin < 2, error('Reference head model is missing.');end
            if nargin < 3, individualHeadModelFile = ['surfaces_' num2str(round(1e5*rand)) '.mat'];end
            if nargin < 4, regType = 'bspline';end
            if isempty(obj.channelSpace) || isempty(obj.label), error('Channel space or labels are missing.');end
            if ~exist(headModelFile,'file'), error('The file you''ve entered does not exist.');end
            
            warning('This method hass been deprecated, instead you can use "warpToTemplate".')
            template = load(headModelFile);
            if isfield(template,'metadata')
                tmp = headModel.loadFromFile(headModelFile);
                template = template.metadata;
                load(tmp.surfaces)
                template.surfData = surfData;
            end
            surfData = template.surfData;
            gTools = geometricTools;
            th = norminv(0.90);
            % mapping source to target spaces: S->T
            % target space: template
            
            try
                T = [template.fiducials.nasion;...
                    template.fiducials.lpa;...
                    template.fiducials.rpa;...
                    template.fiducials.vertex];
                
                % source space: individual geometry
                S = [obj.fiducials.nasion;...
                    obj.fiducials.lpa;...
                    obj.fiducials.rpa];
                
                % estimates vertex if is missing
                if isfield(obj.fiducials,'vertex')
                    if numel(obj.fiducials.vertex) == 3
                        S = [S;obj.fiducials.vertex];
                    else
                        point = 0.5*(obj.fiducials.lpa + obj.fiducials.rpa);
                        point = ones(50,1)*point;
                        point(:,3) = linspace(point(3),1.5*max(obj.channelSpace(:,3)),50)';
                        [~,d] = gTools.nearestNeighbor(obj.channelSpace,point);
                        [~,loc] = min(d);
                        point = point(loc,:);
                        S = [S;point];
                    end
                else
                    point = 0.5*(obj.fiducials.lpa + obj.fiducials.rpa);
                    point = ones(50,1)*point;
                    point(:,3) = linspace(point(3),1.5*max(obj.channelSpace(:,3)),50)';
                    [~,d] = gTools.nearestNeighbor(obj.channelSpace,point);
                    [~,loc] = min(d);
                    point = point(loc,:);
                    S = [S;point];
                end
                
                if isfield(obj.fiducials,'inion')
                    if numel(obj.fiducials.vertex) == 3
                        S = [S;obj.fiducials.inion];
                        T = [T;template.fiducials.inion];
                    end
                end
            catch
                disp('Fiducials are missing in the individual head model, selecting the common set of points based on the channel labels.')
                [~,loc1,loc2] = intersect(obj.getChannelLabels,template.label,'stable');
                S = obj.channelSpace(loc1,:);
                T = template.channelSpace(loc2,:);
            end
            if isa(obj,'eeg')
                obj.initStatusbar(1,8,'Co-registering...');
            else
                disp('Co-registering...');
            end
            
            % affine co-registration
            Aff = gTools.affineMapping(S,T);
            if isa(obj,'eeg'), obj.statusbar(1);end
            
            obj.channelSpace = gTools.applyAffineMapping(obj.channelSpace,Aff);
            if ~isempty(obj.fiducials)
                obj.fiducials.lpa = gTools.applyAffineMapping(obj.fiducials.lpa,Aff);
                obj.fiducials.rpa = gTools.applyAffineMapping(obj.fiducials.rpa,Aff);
                obj.fiducials.nasion = gTools.applyAffineMapping(obj.fiducials.nasion,Aff);
            end
            if ~strcmp(regType,'affine')
                % b-spline co-registration (coarse warping)
                options.Verbose = true;
                options.MaxRef = 2;
                Saff = gTools.applyAffineMapping(S,Aff);
                [Def,spacing,offset] = gTools.bSplineMapping(Saff,T,obj.channelSpace,options);
                if isa(obj,'eeg'), obj.statusbar(2);end
                obj.channelSpace = gTools.applyBSplineMapping(Def,spacing,offset,obj.channelSpace);
                if ~isempty(obj.fiducials)
                    obj.fiducials.lpa = gTools.applyBSplineMapping(Def,spacing,offset,obj.fiducials.lpa);
                    obj.fiducials.rpa = gTools.applyBSplineMapping(Def,spacing,offset,obj.fiducials.rpa);
                    obj.fiducials.nasion = gTools.applyBSplineMapping(Def,spacing,offset,obj.fiducials.nasion);
                end
                
                % b-spline co-registration (detailed warping)
                Npass = 4;
                for it=2:Npass
                    T = template.surfData(1).vertices;
                    S = obj.channelSpace;
                    S(S(:,3) <= min(T(:,3)),:) = [];
                    [T,d] = gTools.nearestNeighbor(T,S);
                    z = zscore(d);
                    S(abs(z)>th,:) = [];
                    T(abs(z)>th,:) = [];
                    [Def,spacing,offset] = gTools.bSplineMapping(S,T,obj.channelSpace,options);
                    if isa(obj,'eeg'), obj.statusbar(it);end
                    obj.channelSpace = gTools.applyBSplineMapping(Def,spacing,offset,obj.channelSpace);
                    if ~isempty(obj.fiducials)
                        obj.fiducials.lpa = gTools.applyBSplineMapping(Def,spacing,offset,obj.fiducials.lpa);
                        obj.fiducials.rpa = gTools.applyBSplineMapping(Def,spacing,offset,obj.fiducials.rpa);
                        obj.fiducials.nasion = gTools.applyBSplineMapping(Def,spacing,offset,obj.fiducials.nasion);
                    end
                end
            end
            if isfield(template,'atlas'), obj.atlas = template.atlas;end
            if exist(obj.surfaces,'file'), delete(obj.surfaces);end
            obj.surfaces = individualHeadModelFile;
            save(obj.surfaces,'surfData');
            if isa(obj,'eeg'), obj.statusbar(8);end
        end
    end
    %%
    methods(Static)
        function obj = loadFromFile(filename)
            if ~exist(filename,'file')
                error('File does not exist');
            end
            fileContent = load(filename);
            if ~isfield(fileContent,'version')
               fileContent = headModel.loadFromFile_old(filename);
            end
            pnames = fieldnames(fileContent);
            inputParameters = cell(length(pnames),2);            
            for k=1:length(pnames)
                inputParameters{k,1} = pnames{k};
                inputParameters{k,2} = fileContent.(pnames{k});
            end
            inputParameters = inputParameters';
            inputParameters = inputParameters(:)';
            obj = headModel(inputParameters(:));
        end
    end
    methods(Static, Hidden)
        function fileContent = loadFromFile_old(file)
            metadata = load(file,'-mat');
            if isfield(metadata,'metadata')
                metadata = metadata.metadata;
            end
            if isfield(metadata,'surfaces') && isstruct(metadata.surfaces)
                metadata.surfData = metadata.surfaces;
            end
            if ~isempty(metadata.surfData)
                surfData = metadata.surfData;
                if isfield(surfData,'surfData'), surfData = surfData.surfData;end
                % [~,filename] = fileparts(tempname);
                % metadata.surfaces = [getHomeDir filesep '.' filename '.mat'];
                metadata.surfaces = [tempname '.mat'];
                save(metadata.surfaces,'surfData');
            end
            if isfield(metadata,'leadField') && ~isempty(metadata.leadField)
                % [~,filename] = fileparts(tempname);
                % metadata.leadFieldFile = [getHomeDir filesep '.' filename '.mat'];
                metadata.leadFieldFile = [tempname '.mat'];
                if isfield(metadata.leadField,'K')
                    K = metadata.leadField.K; %#ok
                else
                    K = metadata.leadField; %#ok
                end
                if isfield(metadata.leadField,'L')
                    L = metadata.leadField.L; %#ok
                    save(metadata.leadFieldFile,'K','L');
                else save(metadata.leadFieldFile,'K');
                end
            else
                metadata.leadFieldFile = [];
            end
            scalp = [];
            outskull = [];
            inskull = [];
            cortex = [];
            K = [];
            L = [];
            if isfield(metadata,'surfaces')
                load(metadata.surfaces)
                scalp = surfData(1);
                outskull = surfData(2);
                inskull = surfData(3);
                cortex = surfData(4);
                delete(metadata.surfaces)
            end
            if isfield(metadata,'leadFieldFile')
                load(metadata.leadFieldFile)
                delete(metadata.leadFieldFile)
            end
            
            fileContent = struct('channelSpace',metadata.channelSpace,'labels',[],'fiducials',[],'scalp',scalp,...
                'outskull',outskull,'inskull',inskull,'cortex',cortex,'atlas',metadata.atlas,'K',K,'L',L);
            fileContent.labels = metadata.label;
        end
    end
end

%--
function [elec,labels,fiducials] = readMontage(file)
[eloc, labels] = readlocs(file);
elec = [cell2mat({eloc.X}'), cell2mat({eloc.Y}'), cell2mat({eloc.Z}')];
Nl = length(labels);
count = 1;
lowerLabels = lower(labels);
rmThis = false(Nl,1);
for it=1:Nl
    if ~isempty(strfind(lowerLabels{it},'fidnz')) || ~isempty(strfind(lowerLabels{it},'nasion')) || ~isempty(strfind(lowerLabels{it},'nz'))
        fiducials.nasion = elec(it,:);
        rmThis(it) = true;
        count = count+1;
    elseif ~isempty(strfind(lowerLabels{it},'fidt9')) || ~isempty(strfind(lowerLabels{it},'lpa'))
        fiducials.lpa = elec(it,:);  
        rmThis(it) = true;
        count = count+1;
    elseif ~isempty(strfind(lowerLabels{it},'fidt10')) || ~isempty(strfind(lowerLabels{it},'rpa'))
        fiducials.rpa = elec(it,:);
        rmThis(it) = true;
        count = count+1;
    elseif ~isempty(strfind(lowerLabels{it},'fidt10')) || ~isempty(strfind(lowerLabels{it},'vertex'))
        fiducials.vertex = elec(it,:);
        rmThis(it) = true;
        count = count+1;
    end
    if count > 4, break;end
end
elec(rmThis,:) = [];
labels(rmThis) = [];
end


%% unique_bc - unique backward compatible with Matlab versions prior to 2013a
function [C,IA,IB] = unique_bc(A,varargin);

errorFlag = error_bc;

v = version;
indp = find(v == '.');
v = str2num(v(1:indp(2)-1));
if v > 7.19, v = floor(v) + rem(v,1)/10; end;

if nargin > 2
    ind = strmatch('legacy', varargin);
    if ~isempty(ind)
        varargin(ind) = [];
    end;
end;

if v >= 7.14
    [C,IA,IB] = unique(A,varargin{:},'legacy');
    if errorFlag
        [C2,IA2] = unique(A,varargin{:});
        if ~isequal(C, C2) || ~isequal(IA, IA2) || ~isequal(IB, IB2)
            warning('backward compatibility issue with call to unique function');
        end;
    end;
else
    [C,IA,IB] = unique(A,varargin{:});
end
end

%% ismember_bc - ismember backward compatible with Matlab versions prior to 2013a
function [C,IA] = ismember_bc(A,B,varargin);

errorFlag = error_bc;

v = version;
indp = find(v == '.');
v = str2num(v(1:indp(2)-1));
if v > 7.19, v = floor(v) + rem(v,1)/10; end;

if nargin > 2
    ind = strmatch('legacy', varargin);
    if ~isempty(ind)
        varargin(ind) = [];
    end;
end;

if v >= 7.14
    [C,IA] = ismember(A,B,varargin{:},'legacy');
    if errorFlag
        [C2,IA2] = ismember(A,B,varargin{:});
        if (~isequal(C, C2) || ~isequal(IA, IA2))
            warning('backward compatibility issue with call to ismember function');
        end;
    end;
else
    [C,IA] = ismember(A,B,varargin{:});
end
end

%%
function res = error_bc
res = false;
end
