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
        hCortexL
        hCortexR
        hVectorL
        hVectorR
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
        colorBar;
        timeCursor;
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
        cortexAlpha = [];
        scalpAlpha = [];
        indz = [];
    end
    methods
        function obj = currentSourceViewer(hmObj,J,V,figureTitle,~, fps, time)
            if nargin < 3, V = [];end
            if nargin < 4, figureTitle = '';end
            if nargin < 6, fps = 30;end
            if nargin < 7, time = 1:size(J,1);end
            obj.hmObj = hmObj;
            obj.autoscale = false;
            obj.fps = fps;
            obj.time = time;
            color = ones(1,3);
            path = fileparts(which('headModel.m'));
            path = fullfile(path,'+vis','icons');
            labelsOn  = imread([path filesep 'labelsOn.png']);
            sensorsOn = imread([path filesep 'sensorsOn.png']);%,[20 20])
            vectorOn = imread([path filesep 'vectorOn.png']);
            prev = imread([path filesep 'Gnome-media-seek-backward.svg.png']);
            next = imread([path filesep 'Gnome-media-seek-forward.svg.png']);
            play = imread([path filesep 'Gnome-media-playback-start.svg.png']);
            pause = imread([path filesep 'Gnome-media-playback-pause.svg.png']);
            rec = imread([path filesep 'Gnome-media-record.svg.png']);
            lrBrain = imread([path filesep 'LeftRightView.png']);
            helpIcon = imread([path filesep 'Gnome-help-browser.svg.png']);
            
            J = double(J);
            V = double(V);
            
            if isempty(hmObj.leftH)
                [hmObj.fvLeft,hmObj.fvRight, hmObj.leftH, hmObj.rightH] = geometricTools.splitBrainHemispheres(hmObj.cortex);
            end
            obj.leftH = hmObj.leftH;
            obj.rightH = hmObj.rightH;
            
            [~,~, obj.leftH, obj.rightH] = geometricTools.splitBrainHemispheres(hmObj.cortex);
            obj.playIcon = play;
            obj.pauseIcon = pause;
            if isa(hmObj,'struct'), visible = 'off';else visible = 'on';end
            obj.figureName = figureTitle;

            obj.hFigure = figure('Menubar','figure','ToolBar','figure','renderer','opengl','Visible',visible,'Color',color,'Name',obj.figureName);
            position = get(obj.hFigure,'Position');
            set(obj.hFigure,'Position',[position(1:2) 1.25*position(3:4)]);
            obj.hAxes = axes('Parent',obj.hFigure);
            
            toolbarHandle = findall(obj.hFigure,'Type','uitoolbar');
            
            hcb = uitoggletool(toolbarHandle,'CData',labelsOn,'Separator','on','HandleVisibility','off','TooltipString','Labels On/Off','State','off');
            set(hcb,'OnCallback',@(src,event)rePaint(obj,hcb,'labelsOn'),'OffCallback',@(src, event)rePaint(obj,hcb,'labelsOff'));

            hcb = uitoggletool(toolbarHandle,'CData',sensorsOn,'Separator','on','HandleVisibility','off','TooltipString','Sensors On/Off','State','off');
            set(hcb,'OnCallback',@(src,event)rePaint(obj,hcb,'sensorsOn'),'OffCallback',@(src, event)rePaint(obj,hcb,'sensorsOff'));

            hcb = uitoggletool(toolbarHandle,'CData',vectorOn,'Separator','on','HandleVisibility','off','TooltipString','Vectors On/Off','State','off');
            set(hcb,'OnCallback',@(src,event)rePaint(obj,hcb,'vectorOn'),'OffCallback',@(src, event)rePaint(obj,hcb,'vectorOff'));

            hcb = uitoggletool(toolbarHandle,'CData',lrBrain,'Separator','on','HandleVisibility','off','TooltipString','View left/right hemisphere','State','off');
            set(hcb,'OnCallback',@(src,event)viewHemisphere(obj,hcb),'OffCallback',@(src, event)viewHemisphere(obj,hcb));

            uipushtool(toolbarHandle,'CData',prev,'Separator','on','HandleVisibility','off','TooltipString','Previous','ClickedCallback',@obj.prev);
            uipushtool(toolbarHandle,'CData',next,'Separator','on','HandleVisibility','off','TooltipString','Next','ClickedCallback',@obj.next);
            uipushtool(toolbarHandle,'CData',play,'Separator','on','HandleVisibility','off','TooltipString','Play','ClickedCallback',@obj.play);
            uipushtool(toolbarHandle,'CData',rec,'Separator','on','HandleVisibility','off','TooltipString','Play','ClickedCallback',@obj.rec);
            uitoggletool(toolbarHandle,'CData',helpIcon,'Separator','on','HandleVisibility','off','TooltipString','Help','State','off',...
                'onCallback','web(''https://github.com/aojeda/headModel#headmodel-toolbox-for-matlabeeglab'')','offCallback','web(''https://github.com/aojeda/headModel#headmodel-toolbox-for-matlabeeglab'')');
            
            set(obj.hFigure,'WindowScrollWheelFcn',@(src, event)mouseMove(obj,[], event));
            pn = uipanel(obj.hFigure);
            pn.Position = [0 0.0 1 0.1];
            obj.cortexAlpha = uicontrol(pn,'Style', 'slider','Min',0,'Max',1,'Value',1,'Units','normalized',...
                'Position',[0.0201, 0.1, 0.1954, 0.3922],'Callback',@obj.setCortexAlpha);
            addlistener(obj.cortexAlpha,'ContinuousValueChange',@obj.setCortexAlpha);
            lb = uicontrol(pn,'Style', 'text','String','Cortex Transparency','Units','normalized',...
                'Position',[0.0115, 0.5294, 0.2112, 0.2941]);
            
            obj.scalpAlpha = uicontrol(pn,'Style', 'slider','Min',0,'Max',1,'Value',0.25,'Units','normalized',...
                'Position',[0.2600, 0.1000, 0.1954, 0.3922], 'Callback',@obj.setScalpAlpha);
            addlistener(obj.scalpAlpha,'ContinuousValueChange',@obj.setScalpAlpha);
            lb2 = uicontrol(pn,'Style', 'text','String','Scalp Transparency','Units','normalized',...
                'Position',[0.2558, 0.5294, 0.1867, 0.2941]);
            
            obj.timeCursor = uicontrol(pn,'Style', 'slider','Min',1,'Max',size(J,2),'Value',1,'Units','normalized',...
                'Position',[0.5057, 0.1, 0.4167, 0.3922], 'Callback',@obj.setTimeCursor);
            addlistener(obj.timeCursor,'ContinuousValueChange',@obj.setTimeCursor);
            lb3 = uicontrol(pn,'Style', 'text','String','Time Cursor','Units','normalized',...
                'Position',[0.6020, 0.5294, 0.1867, 0.2941]);
            
                        
            obj.hAxes.Position([2 4]) = [0.18 0.75];
            
            obj.dcmHandle = datacursormode(obj.hFigure);
            obj.dcmHandle.SnapToDataVertex = 'off';
            set(obj.dcmHandle,'UpdateFcn',@(src,event)showLabel(obj,event));
            obj.dcmHandle.Enable = 'off';
            addlistener(obj.dcmHandle,'Enable','PostSet',@obj.dataCursorSet);
            
            hold(obj.hAxes,'on');

            obj.hSensors = scatter3(obj.hAxes,obj.hmObj.channelSpace(:,1),obj.hmObj.channelSpace(:,2),...
                obj.hmObj.channelSpace(:,3),'filled','MarkerEdgeColor','k','MarkerFaceColor','y');
            set(obj.hSensors,'Visible','off');

            N = length(obj.hmObj.labels);
            k = 1.1;
            obj.hLabels = zeros(N,1);
            for it=1:N, obj.hLabels(it) = text('Position',k*obj.hmObj.channelSpace(it,:),'String',obj.hmObj.labels{it},'Parent',obj.hAxes);end
            set(obj.hLabels,'Visible','off');
            obj.indz = find(obj.hmObj.scalp.vertices(:,3) < min(obj.hmObj.channelSpace(:,3)) - 0.1*abs(min(obj.hmObj.channelSpace(:,3))));
            
            [~,neigDist] = geometricTools.kNearestNeighbor(obj.hmObj.channelSpace,obj.hmObj.channelSpace,3);
            mdist = mean(neigDist(:));
            
            Ns = size(obj.hmObj.scalp.vertices,1);
            %obj.indz = [];
            for k=1:Ns
                dk = sqrt(sum((ones(N,1)*obj.hmObj.scalp.vertices(k,:) - obj.hmObj.channelSpace).^2,2));
                if all(dk>1.1*mdist)
                    obj.indz(end+1) = k;
                end
            end
            obj.indz = unique(obj.indz);
            
            obj.setJ(J);
            obj.pointer = 1;
            obj.Nframes = num2str(size(obj.sourceMagnitud,2));
            obj.is3d = ndims(obj.sourceOrientation) > 2;
            
            fprintf('Calibrating the color scale...')
            mx = obj.getRobustLimits(obj.sourceMagnitud(:),0.5);
            obj.clim.source = [-mx mx];
            set(obj.hAxes,'Clim',obj.clim.source);
            fprintf('done\n')
            
            % vectors
            obj.hVectorL = quiver3(obj.hmObj.cortex.vertices(obj.leftH,1),obj.hmObj.cortex.vertices(obj.leftH,2),obj.hmObj.cortex.vertices(obj.leftH,3),...
                obj.sourceOrientation(obj.leftH,1,1),obj.sourceOrientation(obj.leftH,2,1),obj.sourceOrientation(obj.leftH,3,1),0,'MaxHeadSize',1);
            obj.hVectorR = quiver3(obj.hmObj.cortex.vertices(obj.rightH,1),obj.hmObj.cortex.vertices(obj.rightH,2),obj.hmObj.cortex.vertices(obj.rightH,3),...
                obj.sourceOrientation(obj.rightH,1,1),obj.sourceOrientation(obj.rightH,2,1),obj.sourceOrientation(obj.rightH,3,1),0,'MaxHeadSize',1);
            set([obj.hVectorL obj.hVectorR],'Color','k','Visible','off','LineWidth',0.5);

            % cortex
            obj.hCortexL = patch('vertices',obj.hmObj.fvLeft.vertices,'faces',obj.hmObj.fvLeft.faces,'FaceVertexCData',obj.sourceMagnitud(obj.hmObj.leftH,1),...
                'FaceColor','interp','FaceLighting','phong','LineStyle','none','FaceAlpha',obj.cortexAlpha.Value,'SpecularColorReflectance',0,...
                'SpecularExponent',25,'SpecularStrength',0.25,'Parent',obj.hAxes);
            
            obj.hCortexR = patch('vertices',obj.hmObj.fvRight.vertices,'faces',obj.hmObj.fvRight.faces,'FaceVertexCData',obj.sourceMagnitud(obj.hmObj.rightH,1),...
                'FaceColor','interp','FaceLighting','phong','LineStyle','none','FaceAlpha',obj.cortexAlpha.Value,'SpecularColorReflectance',0,...
                'SpecularExponent',25,'SpecularStrength',0.25,'Parent',obj.hAxes);
            camlight(0,180)
            camlight(0,0)

            % scalp
            if isempty(V)
                skinColor = [1,.75,.65];
                obj.hScalp = patch('vertices',obj.hmObj.scalp.vertices,'faces',obj.hmObj.scalp.faces,'facecolor',skinColor,...
                    'facelighting','phong','LineStyle','none','FaceAlpha',obj.scalpAlpha.Value,'Parent',obj.hAxes);
                obj.scalpData = [];
                obj.clim.scalp = obj.clim.source;
            else
                obj.setV(V);
                obj.hScalp = patch('vertices',obj.hmObj.scalp.vertices,'faces',obj.hmObj.scalp.faces,'FaceVertexCData',obj.scalpData(:,1),...
                    'FaceColor','interp','FaceLighting','phong','LineStyle','none','FaceAlpha',obj.scalpAlpha.Value,'SpecularColorReflectance',0,...
                    'SpecularExponent',25,'SpecularStrength',0.25,'Parent',obj.hAxes);
            end
            view(obj.hAxes,[90 0]);
            set(obj.hAxes,'Clim',obj.clim.source);
            obj.colorBar = colorbar(obj.hAxes);
            obj.colorBar.Label.String = ''; % 'PCD ($nA/mm^2$)';
            obj.colorBar.Label.Interpreter = 'Latex';
            tick = {};for k=linspace(obj.clim.scalp(1)*0.9,obj.clim.scalp(2)*0.9,3) tick{end+1} = num2str(k,4);end
            obj.colorBar.UserData.scalp = tick;
            tick = {};for k=linspace(obj.clim.source(1)*1.1,obj.clim.source(2)*0.9,3) tick{end+1} = num2str(k,4);end
            obj.colorBar.UserData.source = tick;
            obj.colorBar.UserData.scalp{2} = '0';
            obj.colorBar.UserData.source{2} = '0';
            obj.colorBar.Ticks = linspace(obj.clim.source(1)*0.9,obj.clim.source(2)*0.9,3);
            obj.colorBar.Ticks(2) = 0;
            obj.colorBar.TickLabels = {'Max' '0' 'Min'};
            hold(obj.hAxes,'off');
            axis(obj.hAxes,'equal','vis3d');
            axis(obj.hAxes,'off');
            try
                colormap(bipolar(512, 0.99))
            catch
                warning('Bipolar colormap is missing, fallback with jet.')
            end
            set(obj.hFigure,'Name',[obj.figureName '  ' sprintf('%f msec  (%i',obj.time(obj.pointer),obj.pointer) '/' obj.Nframes ')']);
            rotate3d
            drawnow
        end
        function setJ(obj,J)
            if size(J,1) == 3*size(obj.hmObj.cortex.vertices,1)
                J = reshape(J,[size(J,1)/3 3 size(J,2)]);
                Jm = squeeze(sqrt(sum(J.^2,2)));
                mx = max(std(obj.hmObj.cortex.vertices));
                obj.sourceOrientation = mx*J/max(abs(J(:)));
                obj.sourceMagnitud = Jm;
            else
                obj.sourceMagnitud = J;
                obj.sourceOrientation = geometricTools.getSurfaceNormals(obj.hmObj.cortex.vertices,obj.hmObj.cortex.faces, false);
                obj.sourceOrientation = obj.sourceOrientation/max(abs(obj.sourceOrientation(:)));
            end
        end
        function setV(obj,V)
            obj.scalpData = zeros(size(obj.hmObj.scalp.vertices,1),size(V,2));
            nt = size(V,2);
            fprintf('Interpolating scalp data');
            for k=1:nt
                F = scatteredInterpolant(obj.hmObj.channelSpace,V(:,k),'natural','linear');
                obj.scalpData(:,k) = F(obj.hmObj.scalp.vertices);
                if mod(k,100)==0, fprintf('.');end
            end
            obj.scalpData(obj.indz,:) = 0;
            fprintf('done\n');
            fprintf('Calibrating the scalp color scale...')
            mx = obj.getRobustLimits(V,0.1);
            fprintf('done\n')
            obj.clim.scalp = [-mx mx];
            obj.scalpData = obj.clim.source(2)*obj.scalpData/mx;
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
                mx = prctile(abs(nonzeros(vect)),100-th);
                mn = -mx;
            end
        end
        %%
        function viewHemisphere(obj,~)
            obj.lrState = obj.lrState+1;
            obj.lrState(obj.lrState>2) = 0;
            switch obj.lrState
                case 1
                    obj.hCortexR.Visible = 'off';
                    obj.hCortexL.Visible = 'on';
                    
                    if strcmp(obj.hVectorR.Visible,'on')
                        obj.hVectorR.Visible = 'off';
                    end
                case 2
                    obj.hCortexR.Visible = 'on';
                    obj.hCortexL.Visible = 'off';
                    
                    if strcmp(obj.hVectorL.Visible,'on')
                        obj.hVectorL.Visible = 'off';
                    end
                otherwise
                    obj.hCortexR.Visible = 'on';
                    obj.hCortexL.Visible = 'on';
                    if strcmp(obj.hVectorL.Visible,'on') || strcmp(obj.hVectorR.Visible,'on')
                        obj.hVectorR.Visible = 'on';
                        obj.hVectorL.Visible = 'on';
                    end
            end
        end
       %%
        function rePaint(obj,hObject,opt)
            switch opt
                case 'labelsOn'
                    set(obj.hLabels,'Visible','on');
                case 'labelsOff'
                    set(obj.hLabels,'Visible','off');
                case 'sensorsOn'
                    set(obj.hSensors,'Visible','on');
                case 'sensorsOff'
                    set(obj.hSensors,'Visible','off');
                case 'vectorOn'
                    set([obj.hVectorL obj.hVectorR],'Visible','on');
                case 'vectorOff'
                    set([obj.hVectorL obj.hVectorR],'Visible','off');
                case 'scalpOn'
                    %obj.colorBar.Label.String = 'Voltage ($\mu V$)';
                    %set(obj.hAxes,'Clim',obj.clim.scalp);
                    obj.colorBar.TickLabels = obj.colorBar.UserData.scalp;
                case 'scalpOff'
                    %obj.colorBar.Label.String = 'PCD ($nA/mm^2$)';
                    %set(obj.hAxes,'Clim',obj.clim.source);
                    obj.colorBar.TickLabels = obj.colorBar.UserData.source;
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
            writer = VideoWriter(save_in);
            writer.FrameRate = 30;
            writer.Quality = 100;
            open(writer);
            n = size(obj.sourceMagnitud,2);
            if obj.pointer == n
                obj.pointer =1;
            end
            obj.hAxes.XTickLabel = [];
            obj.hAxes.YTickLabel = [];
            obj.hAxes.ZTickLabel = [];
            axHeight = obj.hAxes.Position(4);
            obj.hAxes.Position(4) = 0.8;
            title(obj.hAxes,[obj.figureName '  ' sprintf('%f msec  (%i',obj.time(obj.pointer),obj.pointer) '/' obj.Nframes ')']);
            frame = getframe(obj.hFigure);
            writeVideo(writer, frame);
            while obj.pointer < n
                obj.next();
                title(obj.hAxes,[obj.figureName '  ' sprintf('%f msec  (%i',obj.time(obj.pointer),obj.pointer) '/' obj.Nframes ')']);
                frame = getframe(obj.hFigure);
                writeVideo(writer, frame);
                pause(1/obj.fps);
            end
            close(writer);
            title(obj.hAxes,'');
            obj.hAxes.Position(4) = axHeight;
            disp('Done.')
        end
        %%
        function plot(obj)
            val = obj.sourceMagnitud(:,obj.pointer);
            if obj.is3d
                set(obj.hVectorL,'UData',obj.sourceOrientation(obj.leftH,1,obj.pointer),'VData',obj.sourceOrientation(obj.leftH,2,obj.pointer),'WData',obj.sourceOrientation(obj.leftH,3,obj.pointer));
                set(obj.hVectorR,'UData',obj.sourceOrientation(obj.rightH,1,obj.pointer),'VData',obj.sourceOrientation(obj.rightH,2,obj.pointer),'WData',obj.sourceOrientation(obj.rightH,3,obj.pointer));
            end
            set(obj.hCortexL,'FaceVertexCData',val(obj.leftH));
            set(obj.hCortexR,'FaceVertexCData',val(obj.rightH));
            set(obj.hFigure,'Name',[obj.figureName '  ' sprintf('%f msec  (%i',obj.time(obj.pointer),obj.pointer) '/' obj.Nframes ')']);
            if isempty(obj.scalpData), drawnow;return;end
            val = obj.scalpData(:,obj.pointer);
            set(obj.hScalp,'FaceVertexCData',val);
            drawnow
        end
        %%
        function prev(obj,~,~)
            obj.pointer = obj.pointer - 1;
            n = size(obj.sourceMagnitud,2);
            if obj.pointer > n, obj.pointer = n;end
            if obj.pointer < 1, obj.pointer = 1;end
            obj.timeCursor.Value = obj.pointer;
            obj.plot;
        end
        function next(obj,~,~)
            obj.pointer = obj.pointer+1;
            n = size(obj.sourceMagnitud,2);
            if obj.pointer > n, obj.pointer = n;end
            if obj.pointer < 1, obj.pointer = 1;end
            obj.timeCursor.Value = obj.pointer;
            obj.plot;
        end
        function mouseMove(obj,~,eventObj)
            obj.pointer = obj.pointer + eventObj.VerticalScrollCount;
            n = size(obj.sourceMagnitud,2);
            if obj.pointer < 1, obj.pointer = 0;end
            if obj.pointer > n, obj.pointer = n;end
            obj.timeCursor.Value = obj.pointer;
            obj.plot;
        end
        function setCortexAlpha(obj,~,~)
            obj.hCortexL.FaceAlpha = obj.cortexAlpha.Value;
            obj.hCortexR.FaceAlpha = obj.cortexAlpha.Value;
        end
        function setScalpAlpha(obj,~,~)
            obj.hScalp.FaceAlpha = obj.scalpAlpha.Value;
            if obj.scalpAlpha.Value==0
                obj.hScalp.Visible = 'off';
            else
                obj.hScalp.Visible = 'on';
            end
        end
        function setTimeCursor(obj, ~, ~)
            obj.pointer = round(obj.timeCursor.Value);
            n = size(obj.sourceMagnitud,2);
            if obj.pointer > n, obj.pointer = n;end
            if obj.pointer < 1, obj.pointer = 1;end
            obj.plot;
        end
        function dataCursorSet(obj, src, evnt)
            return;
        end
    end
end
