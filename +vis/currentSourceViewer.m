% Defines the class currentSourceViewer for visualization of EEG inverse solutions on a realistic head model.
% This class is part of MoBILAB software.
% For more details visit:  https://code.google.com/p/mobilab/
%
% Author: Alejandro Ojeda, SCCN/INC/UCSD, Jan-2012

classdef currentSourceViewer < handle
    properties
        hFigure
        hAxes
        hmObj
        hLabels
        hSensors
        hScalp
        hCortex
        hVector
        dcmHandle
        sourceMagnitud
        sourceOrientation
        scalpData
        pointer
        clim
        figureName = '';
        autoscale = false;
        fps = 30;
        time
    end
    properties(GetAccess=private,Hidden)
        Nframes
        is3d
        DT
        isPaused = true;
        playIcon
        pauseIcon
        lrState = 0;
        leftH
        rightH
        interpolator
        smoothness = 1;
    end
    methods
        function obj = currentSourceViewer(hmObj,J,V,figureTitle,autoscale, fps, time)
            if nargin < 3, V = [];end
            if nargin < 4, figureTitle = '';end
            if nargin < 5, autoscale = false;end
            if nargin < 6, fps = 30;end
            if nargin < 7, time = 1:size(J,1);end
            obj.hmObj = hmObj;
            obj.autoscale = autoscale;
            obj.fps = fps;
            obj.time = time;
            color = ones(1,3); % [0.93 0.96 1];
            path = fileparts(which('headModel.m'));
            path = fullfile(path,'+vis','icons');
            labelsOn  = imread([path filesep 'labelsOn.png']);
            labelsOff = imread([path filesep 'labelsOff.png']);
            sensorsOn = imread([path filesep 'sensorsOn.png']);
            sensorsOff = imread([path filesep 'sensorsOff.png']);
            scalpOn = imread([path filesep 'scalpOn.png']);
            scalpOff = imread([path filesep 'scalpOff.png']);
            vectorOn = imread([path filesep 'vectorOn.png']);
            vectorOff = imread([path filesep 'vectorOff.png']);
            prev = imread([path filesep '32px-Gnome-media-seek-backward.svg.png']);
            next = imread([path filesep '32px-Gnome-media-seek-forward.svg.png']);
            play = imread([path filesep '32px-Gnome-media-playback-start.svg.png']);
            pause = imread([path filesep '32px-Gnome-media-playback-pause.svg.png']);
            rec = imread([path filesep '32px-Gnome-media-record.svg.png']);
            lrBrain = imread([path filesep 'lr_brain.png']);
            
            [~,~, obj.leftH, obj.rightH] = geometricTools.splitBrainHemispheres(hmObj.cortex);
            obj.playIcon = play;
            obj.pauseIcon = pause;
            if isa(hmObj,'struct'), visible = 'off';else visible = 'on';end
            obj.figureName = figureTitle;

            obj.hFigure = figure('Menubar','figure','ToolBar','figure','renderer','opengl','Visible',visible,'Color',color,'Name',obj.figureName);
            position = get(obj.hFigure,'Position');
            set(obj.hFigure,'Position',[position(1:2) 1.25*position(3:4)]);
            obj.hAxes = axes('Parent',obj.hFigure);
            set(obj.hFigure,'KeyPressFcn', @(src,event)scalpSmoothControl(obj));
            toolbarHandle = findall(obj.hFigure,'Type','uitoolbar');

            hcb(1) = uitoggletool(toolbarHandle,'CData',labelsOff,'Separator','on','HandleVisibility','off','TooltipString','Labels On/Off','userData',{labelsOn,labelsOff},'State','off');
            set(hcb(1),'OnCallback',@(src,event)rePaint(obj,hcb(1),'labelsOn'),'OffCallback',@(src, event)rePaint(obj,hcb(1),'labelsOff'));

            hcb(2) = uitoggletool(toolbarHandle,'CData',sensorsOff,'Separator','off','HandleVisibility','off','TooltipString','Sensors On/Off','userData',{sensorsOn,sensorsOff},'State','off');
            set(hcb(2),'OnCallback',@(src,event)rePaint(obj,hcb(2),'sensorsOn'),'OffCallback',@(src, event)rePaint(obj,hcb(2),'sensorsOff'));

            hcb(3) = uitoggletool(toolbarHandle,'CData',scalpOff,'Separator','off','HandleVisibility','off','TooltipString','Scalp On/Off','userData',{scalpOn,scalpOff},'State','off');
            set(hcb(3),'OnCallback',@(src,event)rePaint(obj,hcb(3),'scalpOn'),'OffCallback',@(src, event)rePaint(obj,hcb(3),'scalpOff'));

            hcb(4) = uitoggletool(toolbarHandle,'CData',vectorOff,'Separator','off','HandleVisibility','off','TooltipString','Vectors On/Off','userData',{vectorOn,vectorOff},'State','off');
            set(hcb(4),'OnCallback',@(src,event)rePaint(obj,hcb(4),'vectorOn'),'OffCallback',@(src, event)rePaint(obj,hcb(4),'vectorOff'));

            hcb(5) = uitoggletool(toolbarHandle,'CData',lrBrain,'Separator','off','HandleVisibility','off','TooltipString','View left/right hemisphere','State','off');
            set(hcb(5),'OnCallback',@(src,event)viewHemisphere(obj,hcb(5)),'OffCallback',@(src, event)viewHemisphere(obj,hcb(5)));

            uipushtool(toolbarHandle,'CData',prev,'Separator','on','HandleVisibility','off','TooltipString','Previous','ClickedCallback',@obj.prev);
            uipushtool(toolbarHandle,'CData',next,'Separator','on','HandleVisibility','off','TooltipString','Next','ClickedCallback',@obj.next);
            uipushtool(toolbarHandle,'CData',play,'Separator','on','HandleVisibility','off','TooltipString','Play','ClickedCallback',@obj.play);
            uipushtool(toolbarHandle,'CData',rec,'Separator','on','HandleVisibility','off','TooltipString','Play','ClickedCallback',@obj.rec);
            set(obj.hFigure,'WindowScrollWheelFcn',@(src, event)mouseMove(obj,[], event));

            obj.dcmHandle = datacursormode(obj.hFigure);
            obj.dcmHandle.SnapToDataVertex = 'off';
            set(obj.dcmHandle,'UpdateFcn',@(src,event)showLabel(obj,event));
            obj.dcmHandle.Enable = 'off';
            hold(obj.hAxes,'on');

            obj.hSensors = scatter3(obj.hAxes,obj.hmObj.channelSpace(:,1),obj.hmObj.channelSpace(:,2),...
                obj.hmObj.channelSpace(:,3),'filled','MarkerEdgeColor','k','MarkerFaceColor','y');
            set(obj.hSensors,'Visible','off');

            N = length(obj.hmObj.labels);
            k = 1.1;
            obj.hLabels = zeros(N,1);
            for it=1:N, obj.hLabels(it) = text('Position',k*obj.hmObj.channelSpace(it,:),'String',obj.hmObj.labels{it},'Parent',obj.hAxes);end
            set(obj.hLabels,'Visible','off');

            if size(J,1) == 3*size(obj.hmObj.cortex.vertices,1)
                J = reshape(J,[size(J,1)/3 3 size(J,2)]);
                Jm = squeeze(sqrt(sum(J.^2,2)));
                normals = J;
            else
                Jm = J;
                normals = geometricTools.getSurfaceNormals(obj.hmObj.cortex.vertices,obj.hmObj.cortex.faces, false);
            end
            obj.sourceMagnitud = Jm;
            obj.sourceOrientation = J;
            obj.pointer = 1;
            obj.Nframes = num2str(size(obj.sourceMagnitud,2));
            obj.is3d = ndims(obj.sourceOrientation) > 2;

            % vectors
            obj.hVector = quiver3(obj.hmObj.cortex.vertices(:,1),obj.hmObj.cortex.vertices(:,2),obj.hmObj.cortex.vertices(:,3),...
                normals(:,1,1),normals(:,2,1),normals(:,3,1),2);
            set(obj.hVector,'Color','k','Visible','off');

            % cortex
            obj.hCortex = patch('vertices',obj.hmObj.cortex.vertices,'faces',obj.hmObj.cortex.faces,'FaceVertexCData',obj.sourceMagnitud(:,1),...
                'FaceColor','interp','FaceLighting','phong','LineStyle','none','FaceAlpha',1,'SpecularColorReflectance',0,...
                'SpecularExponent',25,'SpecularStrength',0.25,'Parent',obj.hAxes);
            camlight(0,180)
            camlight(0,0)

            % scalp
            if isempty(V)
                skinColor = [1,.75,.65];
                obj.hScalp = patch('vertices',obj.hmObj.scalp.vertices,'faces',obj.hmObj.scalp.faces,'facecolor',skinColor,...
                    'facelighting','phong','LineStyle','none','FaceAlpha',.85,'Parent',obj.hAxes,'Visible','off');
                obj.scalpData = [];
            else
                obj.smoothness = max(abs(obj.hmObj.channelSpace(:)))/10;
                obj.interpolator = geometricTools.localGaussianInterpolator(obj.hmObj.channelSpace,obj.hmObj.scalp.vertices,obj.smoothness);
                obj.scalpData = V;

                obj.hScalp = patch('vertices',obj.hmObj.scalp.vertices,'faces',obj.hmObj.scalp.faces,'FaceVertexCData',obj.interpolator*obj.scalpData(:,1),...
                    'FaceColor','interp','FaceLighting','phong','LineStyle','none','FaceAlpha',1,'SpecularColorReflectance',0,...
                    'SpecularExponent',25,'SpecularStrength',0.25,'Parent',obj.hAxes,'Visible','off');
            end
            view(obj.hAxes,[90 0]);
            if ~obj.autoscale
                disp('Calibrating the color scale...')
                mxsrc = obj.getRobustLimits(obj.sourceMagnitud(:),0.1);
                mxscp = obj.getRobustLimits(obj.scalpData,0.1);
                obj.clim = struct('source',[-mxsrc mxsrc],'scalp',[-mxscp mxscp]);
                set(obj.hAxes,'Clim',obj.clim.source);
                disp('Done.')
            end
            colorbar
            % box on;
            hold(obj.hAxes,'off');
            axis(obj.hAxes,'equal','vis3d');
            axis(obj.hAxes,'off')
            try
                colormap(bipolar(512, 0.99))
            catch
                warning('Bipolar colormap is missing, fallback with jet.')
            end
            set(obj.hFigure,'Name',[obj.figureName '  ' sprintf('%f sec  (%i',obj.time(obj.pointer),obj.pointer) '/' obj.Nframes ')']);
            rotate3d
            drawnow
        end
        function [mx,mn] = getRobustLimits(obj,vect,th)
            if isempty(vect)
                mx = 1;
                mn = -1;
                return
            end
            if size(vect,2) > 1
                samples = unidrnd(numel(vect),min([1000 ,round(0.75*numel(vect))]),20);
                prc = prctile(vect(samples),[th 100-th]);
                mn = median(prc(1,:));
                mx = median(prc(2,:));
                if mx == mn && mx == 0
                    mx = max(vect(:));
                    mn = min(vect(:));
                end
                mx = max(abs([mx mn]));
                mn = -mx;
            else
                mx = prctile(abs(vect),100-th);
                mn = -mx;
            end
        end
        %%
        function viewHemisphere(obj,~)
            val = obj.sourceMagnitud(:,obj.pointer);
            obj.lrState = obj.lrState+1;
            switch obj.lrState
                case 1
                    val(obj.rightH) = nan;
                case 2
                    val(obj.leftH) = nan;
            end
            if obj.lrState > 2; obj.lrState = 0;end
            set(obj.hCortex,'FaceVertexCData',val);
        end
       %%
        function rePaint(obj,hObject,opt)
            CData = get(hObject,'userData');
            if isempty(strfind(opt,'Off'))
                set(hObject,'CData',CData{2});
            else
                set(hObject,'CData',CData{1});
            end
            switch opt
                case 'labelsOn'
                    set(obj.hLabels,'Visible','on');
                case 'labelsOff'
                    set(obj.hLabels,'Visible','off');
                case 'sensorsOn'
                    set(obj.hSensors,'Visible','on');
                case 'sensorsOff'
                    set(obj.hSensors,'Visible','off');
                case 'scalpOn'
                    set(obj.hCortex,'FaceAlpha',0.15);
                    if strcmp(get(obj.hVector,'Visible'),'on')
                        set(obj.hScalp,'Visible','on','FaceAlpha',0.95);
                    else
                        set(obj.hScalp,'Visible','on','FaceAlpha',1);
                    end
                    if ~obj.autoscale
                        set(get(obj.hScalp,'Parent'),'Clim',obj.clim.scalp);
                    end
                case 'scalpOff'
                    set(obj.hScalp,'Visible','off');
                    set(obj.hCortex,'Visible','on','FaceAlpha',1);
                    if ~obj.autoscale
                        set(get(obj.hCortex,'Parent'),'Clim',obj.clim.source);
                    end
                case 'vectorOn'
                    set(obj.hVector,'Visible','on');
                    set(obj.hCortex,'FaceAlpha',0.75);
                case 'vectorOff'
                    set(obj.hVector,'Visible','off');
                    set(obj.hCortex,'FaceAlpha',1);
            end
        end
        %%
        function output_txt = showLabel(obj,event_obj)
            if strcmp(obj.dcmHandle.Enable,'off'),return;end
            if isempty(obj.DT)
                vertices = obj.hmObj.cortex.vertices;
                obj.DT = delaunayTriangulation(vertices(:,1),vertices(:,2),vertices(:,3));
            end
            pos = get(event_obj,'Position');
            loc = nearestNeighbor(obj.DT, pos);
            try
                output_txt = obj.hmObj.atlas.label{obj.hmObj.atlas.colorTable(loc)};
            catch
                output_txt = 'No labeled';
            end
        end
        %%
        function play(obj,thandler,~)
            if obj.isPaused
                set(thandler,'CData',obj.pauseIcon)
                obj.isPaused = false;
            else
                set(thandler,'CData',obj.playIcon)
                obj.isPaused = true;
            end
            n = size(obj.sourceMagnitud,2);
            if obj.pointer == n
                obj.pointer =1;
            end
            while obj.pointer < n && ~obj.isPaused
                try
                    obj.next();
                    pause(1/obj.fps);
                catch ME
                    disp(ME.message)
                    return
                end
            end
            set(thandler,'CData',obj.playIcon)
            obj.isPaused = true;
        end
        %%
        function rec(obj,~,~)
            [filename,filepath] = uiputfile('*.avi','Save movie as');
            if isnumeric(filename);return;end
            save_in = fullfile(filepath,filename);
            n = size(obj.sourceMagnitud,2);
            if obj.pointer == n
                obj.pointer =1;
            end
            obj.hAxes.XTickLabel = [];
            obj.hAxes.YTickLabel = [];
            obj.hAxes.ZTickLabel = [];
            axHeight = obj.hAxes.Position(4);
            obj.hAxes.Position(4) = 0.8;
            axis(obj.hAxes,'on')
            title(obj.hAxes,[obj.figureName '  ' sprintf('%f sec  (%i',obj.time(obj.pointer),obj.pointer) '/' obj.Nframes ')']);
            frames(n) = struct('cdata',[],'colormap',[]);
            start_loc = obj.pointer;
            frames(obj.pointer) = getframe(obj.hFigure);
            while obj.pointer < n
                obj.next();
                title(obj.hAxes,[obj.figureName '  ' sprintf('%f sec  (%i',obj.time(obj.pointer),obj.pointer) '/' obj.Nframes ')']);
                frames(obj.pointer) = getframe(obj.hFigure);
                pause(1/obj.fps);
            end
            frames(1:start_loc-1) = [];
            if isempty(frames), return;end
            disp(['Now saving movie in' save_in]);
            movie2avi(frames, save_in, 'compression', 'None');
            title(obj.hAxes,'');
            obj.hAxes.Position(4) = axHeight;
            axis(obj.hAxes,'off')
            disp('Done.')
        end
        %%
        function prev(obj,~,~)
            obj.pointer = obj.pointer-1;
            if obj.pointer < 1, obj.pointer = 1;end
            val = obj.sourceMagnitud(:,obj.pointer);
            switch obj.lrState
                case 1
                    val(obj.rightH) = nan;
                case 2
                    val(obj.leftH) = nan;
            end
            set(obj.hCortex,'FaceVertexCData',val);
            set(obj.hFigure,'Name',[obj.figureName '  ' sprintf('%f sec  (%i',obj.time(obj.pointer),obj.pointer) '/' obj.Nframes ')']);
            if isempty(obj.scalpData), drawnow;return;end
            val = obj.scalpData(:,obj.pointer);
            set(obj.hScalp,'FaceVertexCData',obj.interpolator*val);
            try %#ok
                set(obj.hVector,'UData',obj.sourceOrientation(:,1,obj.pointer),'VData',obj.sourceOrientation(:,2,obj.pointer),'WData',obj.sourceOrientation(:,3,obj.pointer));
            end
        end
        function next(obj,~,~)
            obj.pointer = obj.pointer+1;
            n = size(obj.sourceMagnitud,2);
            if obj.pointer > n, obj.pointer = n;end
            val = obj.sourceMagnitud(:,obj.pointer);

            switch obj.lrState
                case 1
                    val(obj.rightH) = nan;
                case 2
                    val(obj.leftH) = nan;
            end
            set(obj.hCortex,'FaceVertexCData',val);
            set(obj.hFigure,'Name',[obj.figureName '  ' sprintf('%f sec  (%i',obj.time(obj.pointer),obj.pointer) '/' obj.Nframes ')']);
            if isempty(obj.scalpData), drawnow;return;end
            val = obj.scalpData(:,obj.pointer);
            set(obj.hScalp,'FaceVertexCData',obj.interpolator*val);
            if obj.is3d
                set(obj.hVector,'UData',obj.sourceOrientation(:,1,obj.pointer),'VData',obj.sourceOrientation(:,2,obj.pointer),'WData',obj.sourceOrientation(:,3,obj.pointer));
            end
            drawnow
        end
        function mouseMove(obj,~,eventObj)
            obj.pointer = obj.pointer - eventObj.VerticalScrollCount;%*eventObj.VerticalScrollAmount;
            if obj.pointer < 1, obj.pointer = 1;end
            if obj.pointer > size(obj.sourceMagnitud,2), obj.pointer = size(obj.sourceMagnitud,2);end
            val = obj.sourceMagnitud(:,obj.pointer);
            switch obj.lrState
                case 1
                    val(obj.rightH) = nan;
                case 2
                    val(obj.leftH) = nan;
            end
            set(obj.hFigure,'Name',[obj.figureName '  ' sprintf('%f sec  (%i',obj.time(obj.pointer),obj.pointer) '/' obj.Nframes ')']);
            set(obj.hCortex,'FaceVertexCData',val);
            if isempty(obj.scalpData), drawnow;return;end
            val = obj.scalpData(:,obj.pointer);
            set(obj.hScalp,'FaceVertexCData',obj.interpolator*val);
        end
        function scalpSmoothControl(obj,~)
            if isempty(obj.scalpData),return;end
            key = get(obj.hFigure,'CurrentKey');
            if strcmp(key,'add')
                obj.smoothness = obj.smoothness*1.0125;
            elseif strcmp(key,'subtract')
                obj.smoothness = obj.smoothness/1.0125;
            else
                return;
            end
            obj.interpolator = geometricTools.localGaussianInterpolator(obj.hmObj.channelSpace,obj.hmObj.scalp.vertices,obj.smoothness);
            val = obj.scalpData(:,obj.pointer);
            set(obj.hScalp,'FaceVertexCData',obj.interpolator*val);
            drawnow;
        end
    end
end
