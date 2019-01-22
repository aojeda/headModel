% Defines the class headModel for solving forward/inverse problem of the EEG.
%
% Author: Alejandro Ojeda, Swartz Center for Computational Neuroscience, 
%                           University of California San Diego, 2013

classdef headModel < handle
    properties(GetAccess=public, SetAccess=public,SetObservable)
        channelSpace = [];     % xyz coordinates of the sensors.
        labels = [];
        cortex = [];
        inskull = []'
        outskull = [];
        scalp = [];
        cortexNormals = [];
        fiducials = []; % xyz of the fiducial landmarks: nassion, lpa, rpa, vertex, and inion.
        atlas           % Atlas that labels each vertex in the most internal surface (gray matter).
        K = [];         % Lead field matrix
        L = [];         % Laplacian operator
    end
    properties(Hidden)
        fvLeft
        fvRight
        leftH
        rightH
    end
    properties(GetAccess = private, SetAccess = private, Hidden)
        F = [];
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
        function removeSensor(obj,channel2remove)
            if isa(channel2remove,'char') || iscellstr(channel2remove)
                channel2remove = find(ismember(obj.labels,channel2remove));
            end
            obj.labels(channel2remove) = [];
            obj.channelSpace(channel2remove,:) = [];
            obj.K(channel2remove,:) = [];
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
            if isempty(obj.channelSpace) || isempty(obj.labels)
                error('Channel positions and labels may be missing.');
            end
            if isempty(obj.scalp) || isempty(obj.outskull) || isempty(obj.inskull) || isempty(obj.cortex)
                warning('Head model is incomplete.');
                obj.plotMontage();
                return;
            end
            h = vis.headModelViewer(obj);
        end
        %%
        function H = removeAverageReference(obj,channel2remove)
            Ny = size(obj.K,1);
            if nargin<2, channel2remove = [];end
            H = eye(Ny)-ones(Ny)/Ny;    % Average reference operator
            obj.K = H*obj.K;            % Remove the average reference
            obj.removeSensor(channel2remove)
        end
        function stdLeadField(obj, alpha)
            if nargin < 2,
                indz = [];
            else
                indz = std(obj.K)< prctile(std(obj.K),alpha);
            end
            obj.K = bsxfun(@rdivide,obj.K,eps+sqrt(sum(obj.K.^2,1)));
            obj.K(:,indz) = 0;
%             obj.K = bsxfun(@rdivide,obj.K,eps+std(obj.K,[],2));
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
            hFigureObj = vis.currentSourceViewer(obj,J,V,figureTitle, autoscale, fps, time);
        end
        %%
        function h = plotMontage(obj,showNewfig, ax)
            % Plots a figure with the xyz distribution of sensors, fiducial landmarks, and
            % coordinate axes.
            
            color = [0.93 0.96 1];
            if isempty(obj.channelSpace) || isempty(obj.labels);error('"channelSpace or "labels" are empty.');end
            if nargin < 2, showNewfig = true;end
            if showNewfig, figure('Color',color);end
            if nargin < 3, ax = gca;end
            
            h = scatter3(obj.channelSpace(:,1),obj.channelSpace(:,2),obj.channelSpace(:,3),'filled',...
                'MarkerEdgeColor','k','MarkerFaceColor','y','parent',ax);
            hold(ax,'on');
            N = length(obj.labels);
            k = 1.1;
            for it=1:N, text(ax,'Position',k*obj.channelSpace(it,:),'String',obj.labels{it});end
            mx = max(obj.channelSpace);
            k = 1.2;
            line(ax,[0 k*mx(1)],[0 0],[0 0],'LineStyle','-.','Color','b','LineWidth',2)
            line(ax,[0 0],[0 k*mx(2)],[0 0],'LineStyle','-.','Color','g','LineWidth',2)
            line(ax,[0 0],[0 0],[0 k*mx(3)],'LineStyle','-.','Color','r','LineWidth',2)
            text(ax,'Position',[k*mx(1) 0 0],'String','X','FontSize',12,'FontWeight','bold','Color','b')
            text(ax,'Position',[0 k*mx(2) 0],'String','Y','FontSize',12,'FontWeight','bold','Color','g')
            text(ax,'Position',[0 0 k*mx(3)],'String','Z','FontSize',12,'FontWeight','bold','Color','r')

            try %#ok
                scatter3(ax,obj.fiducials.nasion(1),obj.fiducials.nasion(2),obj.fiducials.nasion(3),'filled','MarkerEdgeColor','k','MarkerFaceColor','K');
                text(ax,'Position',1.1*obj.fiducials.nasion,'String','Nas','FontSize',12,'FontWeight','bold','Color','k');
                scatter3(ax,obj.fiducials.lpa(1),obj.fiducials.lpa(2),obj.fiducials.lpa(3),'filled','MarkerEdgeColor','k','MarkerFaceColor','K');
                text(ax,'Position',1.1*obj.fiducials.lpa,'String','LPA','FontSize',12,'FontWeight','bold','Color','k');
                scatter3(ax,obj.fiducials.rpa(1),obj.fiducials.rpa(2),obj.fiducials.rpa(3),'filled','MarkerEdgeColor','k','MarkerFaceColor','K');
                text(ax,'Position',1.1*obj.fiducials.rpa,'String','RPA','FontSize',12,'FontWeight','bold','Color','k');
                scatter3(ax,obj.fiducials.vertex(1),obj.fiducials.vertex(2),obj.fiducials.vertex(3),'filled','MarkerEdgeColor','k','MarkerFaceColor','K');
                text(ax,'Position',1.1*obj.fiducials.vertex,'String','Ver','FontSize',12,'FontWeight','bold','Color','k');
                scatter3(ax,obj.fiducials.inion(1),obj.fiducials.inion(2),obj.fiducials.inion(3),'filled','MarkerEdgeColor','k','MarkerFaceColor','K');
                text(ax,'Position',1.1*obj.fiducials.inion,'String','Ini','FontSize',12,'FontWeight','bold','Color','k');
            end
            skinColor = [1 0.75 0.65];
            patch('vertices',obj.scalp.vertices,'faces',obj.scalp.faces,'facecolor',skinColor,...
                'facelighting','phong','LineStyle','none','FaceAlpha',0.25,'Parent',ax,'Visible','on');
            hold(ax, 'off');
            axis(ax,'equal');
            axis(ax,'vis3d')
            grid(ax,'on');
            rotate3d(ax);
        end
        %%
        
        function coregister(obj,xyz,labels, manualCoreg)
            if nargin < 4, manualCoreg = false;end
            [~,loc1,loc2] = intersect(labels,obj.labels,'stable');
            isCoreg = false;
            if ~isempty(loc2)
                % Before we move on with the automatic corregistration we need 
                % to make sure that the target channels are well distributed on 
                % the surface of the head (as oposed to all in one place)
                if all([sum(unique(sign(obj.channelSpace(loc2,1)))) sum(unique(sign(obj.channelSpace(loc2,2))))] == [0 0])
                    % Affine co-registration
                    Aff = geometricTools.affineMapping(xyz(loc1,:),obj.channelSpace(loc2,:));
                    xyz = geometricTools.applyAffineMapping(xyz,Aff);
                    
                    if ~manualCoreg
                        % Nonlinear co-registration
                        [Def,spacing,offset] = geometricTools.bSplineMapping(xyz(loc1,:),obj.channelSpace(loc2,:),xyz);
                        xyz = geometricTools.applyBSplineMapping(Def,spacing,offset,xyz);
                        
                        xyzScalpNei = geometricTools.kNearestNeighbor(xyz,obj.scalp.vertices,4);
                        xyz_proj = mean(xyzScalpNei,3);
                        
                        [azimuth,elevation] = cart2sph(xyz(:,1),xyz(:,2),xyz(:,3));
                        [~,~,r] = cart2sph(xyz_proj(:,1),xyz_proj(:,2),xyz_proj(:,3));
                        [xyz(:,1),xyz(:,2),xyz(:,3)] = sph2cart(azimuth(:),elevation(:),1.01*r(:));
                        obj.channelSpace = xyz;
                        obj.labels = labels;
                        obj.K = [];
                        isCoreg = true;
                    end
                end
            end
            if ~isCoreg
                Coregister(obj,xyz, labels);
            end
            if isa(obj.labels,'MException')
            	ME = obj.labels;
                ME.rethrow;
            end
        end
        function warpTemplate(obj,templateObj, regType)
            % Warps a template head model to the space defined by the sensor positions (channelSpace)
            % using Dirk-Jan Kroon's nonrigid_version23 toolbox.
            %
            % For more details see: http://www.mathworks.com/matlabcentral/fileexchange/20057-b-spline-grid-image-and-point-based-registration
            %
            % Input arguments:
            %       templateObj:     head model object that will be warped
            %       regType:         co-registration type, could be 'affine' or 'bspline'. In case
            %                        of 'affine' only the affine mapping is estimated (rotation,
            %                        traslation, and scaling). 'bspline' starts from the affine
            %                        mapping and goes on to estimate a non-linear defformation
            %                        field that captures better the shape of the head.
            %
            % References:
            %    D. Rueckert et al. "Nonrigid Registration Using Free-Form Deformations: Application to Breast MR Images".
            %    Seungyong Lee, George Wolberg, and Sung Yong Shing, "Scattered Data interpolation with Multilevel B-splines"

            if nargin < 2, error('Reference head model is missing.');end
            if nargin < 3, regType = 'bspline';end
            if isempty(obj.channelSpace) || isempty(obj.labels), error('"channelSpace" or "labels" are missing.');end

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
                        [~,d] = geometricTools.nearestNeighbor(obj.channelSpace,point);
                        [~,loc] = min(d);
                        point = point(loc,:);
                        T = [T;point];
                    end
                else
                    point = 0.5*(obj.fiducials.lpa + obj.fiducials.rpa);
                    point = ones(50,1)*point;
                    point(:,3) = linspace(point(3),1.5*max(obj.channelSpace(:,3)),50)';
                    [~,d] = geometricTools.nearestNeighbor(obj.channelSpace,point);
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
                [~,loc1,loc2] = intersect(lower(obj.labels),lower(templateObj.labels),'stable');
                if isempty(loc1)
                    error('Cannot perform the co-registration because we could not find a common set of labels between the template and the individual channels.')
                end
                T = obj.channelSpace(loc1,:);
                S = templateObj.channelSpace(loc2,:);
            end

            obj.scalp    = templateObj.scalp;
            obj.outskull = templateObj.outskull;
            obj.inskull  = templateObj.inskull;
            obj.cortex   = templateObj.cortex;
            obj.K        = [];
            obj.L        = [];
            obj.atlas    = templateObj.atlas;

            % Affine co-registration
            Aff = geometricTools.affineMapping(S,T);

            % Affine warping
            obj.scalp.vertices    = geometricTools.applyAffineMapping(templateObj.scalp.vertices,Aff);
            obj.outskull.vertices = geometricTools.applyAffineMapping(templateObj.outskull.vertices,Aff);
            obj.inskull.vertices  = geometricTools.applyAffineMapping(templateObj.inskull.vertices,Aff);
            obj.cortex.vertices   = geometricTools.applyAffineMapping(templateObj.cortex.vertices,Aff);

            % b-spline co-registration (only fiducial landmarks)
            if strcmp(regType,'bspline')
                options.Verbose = true;
                options.MaxRef = 2;
                Saff = geometricTools.applyAffineMapping(S,Aff);
                [Def,spacing,offset] = geometricTools.bSplineMapping(Saff,T,obj.scalp.vertices,options);

                % b-spline co-registration (second pass)
                obj.scalp.vertices    = geometricTools.applyBSplineMapping(Def,spacing,offset,obj.scalp.vertices);
                obj.outskull.vertices = geometricTools.applyBSplineMapping(Def,spacing,offset,obj.outskull.vertices);
                obj.inskull.vertices  = geometricTools.applyBSplineMapping(Def,spacing,offset,obj.inskull.vertices);
                obj.cortex.vertices   = geometricTools.applyBSplineMapping(Def,spacing,offset,obj.cortex.vertices);
            end
            % Project sensors to the scalp (in case they are not already exactly on the scalp)
            obj.channelSpace = geometricTools.nearestNeighbor(obj.channelSpace,obj.scalp.vertices);
            disp('Done!')
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
                
            % Locate OpenMEEG binaries
            if ~isempty(strfind(computer,'PCWIN')) %#ok
                
                % on Windows
                if exist('C:\Program Files\OpenMEEG\bin\om_assemble.exe','file')
                    binDir = '"C:\Program Files\OpenMEEG\bin"';
                elseif exist('C:\Program Files (x86)\OpenMEEG\bin\om_assemble.exe','file')
                    binDir = '"C:\Program Files (x86)\OpenMEEG\bin"';
                elseif exist([pwd '\OpenMEEG\bin\om_assemble.exe'],'file')
                    binDir = [pwd '\OpenMEEG\bin\'];
                else
                    binDir = '';
                end
                
            elseif ~isempty(strfind(computer,'MACI64')) %#ok
                
                % on Mac
                if exist('/usr/local/bin/om_assemble','file')
                    binDir = '"/usr/local/bin"';
                else
                    binDir = '';
                end
            else  
                [tmp, binFile] = system('which om_assemble');
                existOM = ~tmp;
                if existOM
                    binDir = fileparts(deblank(binFile));
                else
                    binDir = '';
                end
            end
            
            if ~exist(binDir,'dir')
                binDir = input('Enter the full path to OpenMEEG\bin directory:');
                if ~exist(fullfile(binDir,'om_assemble.exe'),'file')
                    error('OpenMEEG:NoInstalled','Cannot locate OpenMEEG installation directory.\nClick on the link to download and install <a href="https://gforge.inria.fr/frs/?group_id=435">OpenMEEG</a>.');
                end
            end
            
            tmpDir = tempdir;
            
            [~,rname] = fileparts(tempname);
            headModelGeometry = fullfile(tmpDir,[rname '.geom']);
            try %#ok
                copyfile(which('head_model.geom'),headModelGeometry,'f');
                c1 = onCleanup(@()delete(headModelGeometry));
            end
            headModelConductivity = fullfile(tmpDir,[rname '.cond']);
            fid = fopen(headModelConductivity,'w');
            fprintf(fid,'# Properties Description 1.0 (Conductivities)\n\nAir         0.0\nScalp       %.3f\nBrain       %0.3f\nSkull       %0.3f',...
                conductivity(1),conductivity(3),conductivity(2));
            fclose(fid);
            c2 = onCleanup(@()delete(headModelConductivity));

            dipolesFile = fullfile(tmpDir,[rname '_dipoles.txt']);
            
            if isempty(obj.cortexNormals)
                normalsIn = true;
                [normals,obj.cortex.faces] = geometricTools.getSurfaceNormals(obj.cortex.vertices,obj.cortex.faces,normalsIn);
            else
                normals = obj.cortexNormals;
            end

            normalityConstrained = ~orientation;
            if normalityConstrained
                sourceSpace = [obj.cortex.vertices normals];
            else
                One = ones(length(normals(:,2)),1)*norm(obj.cortex.vertices)/sqrt(size(obj.cortex.vertices,1));
                Zero = 0*One;
                sourceSpace = [obj.cortex.vertices One Zero Zero;...
                    obj.cortex.vertices Zero One Zero;...
                    obj.cortex.vertices Zero Zero One];
            end
            dlmwrite(dipolesFile, sourceSpace, 'precision', 6,'delimiter',' ')
            c3 = onCleanup(@()delete(dipolesFile));

            electrodesFile = fullfile(tmpDir,[rname '_elec.txt']);
            dlmwrite(electrodesFile, obj.channelSpace, 'precision', 6,'delimiter',' ')
            c4 = onCleanup(@()delete(electrodesFile));

            normalsIn = true;
            brain = fullfile(tmpDir,'brain.tri');
            [normals,obj.inskull.faces] = geometricTools.getSurfaceNormals(obj.inskull.vertices,obj.inskull.faces,normalsIn);
            om_save_tri(brain,obj.inskull.vertices,obj.inskull.faces,normals)
            c5 = onCleanup(@()delete(brain));

            skull = fullfile(tmpDir,'skull.tri');
            [normals,obj.outskull.faces] = geometricTools.getSurfaceNormals(obj.outskull.vertices,obj.outskull.faces,normalsIn);
            om_save_tri(skull,obj.outskull.vertices,obj.outskull.faces,normals)
            c6 = onCleanup(@()delete(skull));

            head = fullfile(tmpDir,'head.tri');
            [normals,obj.scalp.faces] = geometricTools.getSurfaceNormals(obj.scalp.vertices,obj.scalp.faces,normalsIn);
            om_save_tri(head,obj.scalp.vertices,obj.scalp.faces,normals)
            c7 = onCleanup(@()delete(head));

            hmFile    = fullfile(tmpDir,'hm.bin');    c8  = onCleanup(@()delete(hmFile));
            hmInvFile = fullfile(tmpDir,'hm_inv.bin');c9  = onCleanup(@()delete(hmInvFile));
            dsmFile   = fullfile(tmpDir,'dsm.bin');   c10 = onCleanup(@()delete(dsmFile));
            h2emFile  = fullfile(tmpDir,'h2em.bin');  c11 = onCleanup(@()delete(h2emFile));
            lfFile    = fullfile(tmpDir,[rname '_LF.mat']);

            try
                out = system([fullfile(binDir,'om_assemble') ' -HM "' headModelGeometry '" "' headModelConductivity '" "' hmFile '"']);
                if out, error('An unexpected error occurred running OpenMEEG binaries. Report this to alejandro@sccn.ucsd.edu');end

                out = system([fullfile(binDir,'om_minverser') ' "' hmFile '" "' hmInvFile '"']);
                if out, error('An unexpected error occurred running OpenMEEG binaries. Report this to alejandro@sccn.ucsd.edu');end

                out = system([fullfile(binDir,'om_assemble') ' -DSM "' headModelGeometry '" "' headModelConductivity '" "' dipolesFile '" "' dsmFile '"']);
                if out, error('An unexpected error occurred running OpenMEEG binaries. Report this to alejandro@sccn.ucsd.edu');end

                out = system([fullfile(binDir,'om_assemble') ' -H2EM "' headModelGeometry '" "' headModelConductivity '" "' electrodesFile '" "' h2emFile '"']);
                if out, error('An unexpected error occurred running OpenMEEG binaries. Report this to alejandro@sccn.ucsd.edu');end

                out = system([fullfile(binDir,'om_gain') ' -EEG "' hmInvFile '" "' dsmFile '" "' h2emFile '" "' lfFile '"']);
                if out, error('An unexpected error occurred running OpenMEEG binaries. Report this to alejandro@sccn.ucsd.edu');end
            catch ME
                ME.rethrow;
            end
            if ~exist(lfFile,'file'), error('An unexpected error occurred running OpenMEEG binaries. Report this to alejandro@sccn.ucsd.edu');end

            load(lfFile);
            obj.K = linop;
            clear linop;
            if exist(lfFile,'file'), delete(lfFile);end
            disp('Done.')
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
            hFigureObj = vis.equivalentCurrentDipoleViewer(obj,xyz,ecd,dipoleLabel,figureTitle);
        end
        function hFigureObj = plotDipolesForwardProjection(obj,xyz,figureTitle,autoscale,fps)
            if nargin < 3, figureTitle = '';end
            if nargin < 4, autoscale = false;end
            if nargin < 5, fps = 30;end
            [FP,S] = getForwardProjection(obj,xyz);
            hFigureObj = obj.plotOnModel(S,FP,figureTitle,autoscale,fps);

        end
       %%
       function transform2MNI(obj)
           M = [...
               cos(pi/2)  sin(pi/2) 0  0;...
               sin(pi/2)  cos(pi/2) 0 -0.0322;...
               0          0         1 -0.0414;...
               0          0         0 1];
           s = [1000*[1 1 1] 0];
           M = diag(s)*M;
           obj.cortex.vertices   = (M*[obj.cortex.vertices   ones(size(obj.cortex.vertices,1),1)]')';   obj.cortex.vertices(:,4)   = [];
           obj.inskull.vertices  = (M*[obj.inskull.vertices  ones(size(obj.inskull.vertices,1),1)]')';  obj.inskull.vertices(:,4)  = [];
           obj.outskull.vertices = (M*[obj.outskull.vertices ones(size(obj.outskull.vertices,1),1)]')'; obj.outskull.vertices(:,4) = [];
           obj.scalp.vertices    = (M*[obj.scalp.vertices    ones(size(obj.scalp.vertices,1),1)]')';    obj.scalp.vertices(:,4)    = [];
           obj.channelSpace      = (M*[obj.channelSpace      ones(size(obj.channelSpace,1),1)]')';      obj.channelSpace(:,4)      = [];
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

        %% Deprecated fields and methods
        function surfaces = get.surfaces(obj)
            surfaces = [obj.scalp;obj.outskull;obj.inskull;obj.cortex];
            warning('"surfaces" has been deprecated, instead you can access directly the properties "scalp", "outskull", "inskull", or "cortex".')
        end
        function leadFieldFile = get.leadFieldFile(obj)
            leadFieldFile = tempname;
            K = obj.K;
            L = obj.L;
            save(leadFieldFile,'K','L');
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
    end
    %%
    methods(Static)
        function obj = loadFromFile(filename)
            coder.extrinsic('exist');
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
        function obj = loadDefault()
            obj = headModel.loadFromFile(headModel.getDefaultTemplateFilename());
        end
        function filename = getDefaultTemplateFilename()
            filename = which('head_modelColin27_8003_Standard-10-5-Cap339.mat');
            % filename = which('head_modelColin27_5003_Standard-10-5-Cap339-Destrieux148.mat');
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
                if length(surfData) >3
                    scalp = surfData(1);
                    outskull = surfData(2);
                    inskull = surfData(3);
                    cortex = surfData(4);
                else
                    scalp = surfData(1);
                    outskull = surfData(2);
                    outskull.vertices = outskull.vertices*1.01;
                    inskull = surfData(2);
                    cortex = surfData(3);
                end
                delete(metadata.surfaces)
            end
            if isfield(metadata,'leadFieldFile')
                load(metadata.leadFieldFile)
                delete(metadata.leadFieldFile)
            end
            if isfield(metadata.atlas,'color')
                metadata.atlas.colorTable = metadata.atlas.color;
                metadata.atlas = rmfield(metadata.atlas,'color');
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
