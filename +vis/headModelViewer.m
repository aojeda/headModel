classdef headModelViewer < handle
    properties
        hFigure
        hAxes
        hmObj
        hFiducials
        hLabels
        hSensors
        hScalp
        hSkull
        hCortexL
        hCortexR
        dcmHandle
        roiLabels = {};
    end
    properties(GetAccess=private,Hidden)
        DT = [];
        lrState = 0;
        leftH
        rightH
        FaceVertexCData = [];
    end
    methods
        function obj = headModelViewer(hmObj)
            obj.hmObj = hmObj; 
            color = ones(1, 3); %[0.93 0.96 1];
            path = fileparts(which('headModel.m'));
            path = fullfile(path,'+vis','icons');
            labelsOn  = imresize(imread([path filesep 'labelsOn.png']),[28 28]);
            sensorsOn = imresize(imread([path filesep 'sensorsOn.png']),[20 20]);
            scalpOn = imread([path filesep 'scalpOn.png']);
            skullOn = imread([path filesep 'skullOn.png']);
            atlasOn = imread([path filesep 'atlasOn.png']);
            roiModeOn  = imread([path filesep 'selectRoiOn.svg.png']);
            lrBrain = imresize(imread([path filesep 'LeftRightView.png']),[25 28]);
            helpIcon = imresize(imread([path filesep 'Gnome-help-browser.svg.png']),[28 28]);
            
            if isempty(hmObj.leftH)
                [hmObj.fvLeft,hmObj.fvRight, hmObj.leftH, hmObj.rightH] = geometricTools.splitBrainHemispheres(hmObj.cortex); 
            end
            obj.leftH = hmObj.leftH;
            obj.rightH = hmObj.rightH;
            obj.hFigure = figure('Menubar','figure','ToolBar','figure','renderer','opengl','Visible','on','Color',color,'Name','Head model');
            position = get(obj.hFigure,'position');
            if ispc
                set(obj.hFigure,'position',[position(1:2).*[1 0.75] 648 490]);
            else
                set(obj.hFigure,'position',[position(1:2) 648 490]);
            end

            obj.hAxes = axes('Parent',obj.hFigure);
            
            toolbarHandle = findall(obj.hFigure,'Type','uitoolbar');
            
            hcb = uitoggletool(toolbarHandle,'CData',labelsOn,'Separator','on','HandleVisibility','off','TooltipString','Labels On/Off','State','off');
            set(hcb,'OnCallback',@(src,event)rePaint(obj,hcb,'labelsOff'),'OffCallback',@(src, event)rePaint(obj,hcb,'labelsOn'));
            
            hcb = uitoggletool(toolbarHandle,'CData',sensorsOn,'Separator','off','HandleVisibility','off','TooltipString','Sensors On/Off','State','off');
            set(hcb,'OnCallback',@(src,event)rePaint(obj,hcb,'sensorsOff'),'OffCallback',@(src, event)rePaint(obj,hcb,'sensorsOn'));
            
            hcb = uitoggletool(toolbarHandle,'CData',scalpOn,'Separator','off','HandleVisibility','off','TooltipString','Scalp On/Off','State','off');
            set(hcb,'OnCallback',@(src,event)rePaint(obj,hcb,'scalpOff'),'OffCallback',@(src, event)rePaint(obj,hcb,'scalpOn'));
            
            hcb = uitoggletool(toolbarHandle,'CData',skullOn,'Separator','off','HandleVisibility','off','TooltipString','Skull On/Off','State','off');
            set(hcb,'OnCallback',@(src,event)rePaint(obj,hcb,'skullOff'),'OffCallback',@(src, event)rePaint(obj,hcb,'skullOn'));
            
            hcb = uitoggletool(toolbarHandle,'CData',atlasOn,'Separator','off','HandleVisibility','off','TooltipString','Atlas On/Off','State','off');
            set(hcb,'OnCallback',@(src,event)rePaint(obj,hcb,'atlasOff'),'OffCallback',@(src, event)rePaint(obj,hcb,'atlasOn'));
            
            hcb = uitoggletool(toolbarHandle,'CData',roiModeOn,'Separator','off','HandleVisibility','off','TooltipString','ROI mode On/Off','State','off');
            set(hcb,'OnCallback',@(src,event)rePaint(obj,hcb,'roiModeOn'),'OffCallback',@(src, event)rePaint(obj,hcb,'roiModeOff'));
            
            hcb = uitoggletool(toolbarHandle,'CData',lrBrain,'Separator','off','HandleVisibility','off','TooltipString','View left/right hemisphere','State','off');
            set(hcb,'OnCallback',@(src,event)viewHemisphere(obj,hcb),'OffCallback',@(src, event)viewHemisphere(obj,hcb));
            
            uitoggletool(toolbarHandle,'CData',helpIcon,'Separator','on','HandleVisibility','off','TooltipString','Help','State','off',...
                'onCallback','web(''https://github.com/aojeda/headModel#headmodel-toolbox-for-matlabeeglab'')','offCallback','web(''https://github.com/aojeda/headModel#headmodel-toolbox-for-matlabeeglab'')');
            
            obj.dcmHandle = datacursormode(obj.hFigure);
            obj.dcmHandle.SnapToDataVertex = 'off';
            set(obj.dcmHandle,'UpdateFcn',@(src,event)showLabel(obj,event));
            obj.dcmHandle.Enable = 'off';
            
            hold(obj.hAxes,'on');
            
            obj.hSensors = scatter3(obj.hAxes,obj.hmObj.channelSpace(:,1),obj.hmObj.channelSpace(:,2),...
                obj.hmObj.channelSpace(:,3),'filled','MarkerEdgeColor','k','MarkerFaceColor','y');
            N = length(obj.hmObj.labels);
            k = 1.1;
            obj.hLabels = zeros(N,1);
            for it=1:N, obj.hLabels(it) = text('Position',k*obj.hmObj.channelSpace(it,:),'String',obj.hmObj.labels{it},'Parent',obj.hAxes);end
            
            try %#ok
                obj.hFiducials(1) = scatter3(obj.hAxes,obj.hmObj.fiducials.nasion(1),obj.hmObj.fiducials.nasion(2),obj.hmObj.fiducials.nasion(3),'filled',...
                    'MarkerEdgeColor','k','MarkerFaceColor','K');
                obj.hLabels(end+1) = text('Position',1.1*obj.hmObj.fiducials.nasion,'String','Nas','FontSize',12,'FontWeight','bold','Color','k','Parent',obj.hAxes);
                
                obj.hFiducials(2) = scatter3(obj.hAxes,obj.hmObj.fiducials.lpa(1),obj.hmObj.fiducials.lpa(2),obj.hmObj.fiducials.lpa(3),'filled',...
                    'MarkerEdgeColor','k','MarkerFaceColor','K');
                obj.hLabels(end+1) = text('Position',1.1*obj.hmObj.fiducials.lpa,'String','LPA','FontSize',12,'FontWeight','bold','Color','k','Parent',obj.hAxes);
                
                obj.hFiducials(3) = scatter3(obj.hAxes,obj.hmObj.fiducials.rpa(1),obj.hmObj.fiducials.rpa(2),obj.hmObj.fiducials.rpa(3),'filled',...
                    'MarkerEdgeColor','k','MarkerFaceColor','K');
                obj.hLabels(end+1) = text('Position',1.1*obj.hmObj.fiducials.rpa,'String','RPA','FontSize',12,'FontWeight','bold','Color','k','Parent',obj.hAxes);
                
                obj.hFiducials(4) = scatter3(obj.hAxes,obj.hmObj.fiducials.vertex(1),obj.hmObj.fiducials.vertex(2),obj.hmObj.fiducials.vertex(3),'filled',...
                    'MarkerEdgeColor','k','MarkerFaceColor','K');
                obj.hLabels(end+1) = text('Position',1.1*obj.hmObj.fiducials.vertex,'String','Ver','FontSize',12,'FontWeight','bold','Color','k','Parent',obj.hAxes);
                
                obj.hFiducials(5) = scatter3(obj.hAxes,obj.hmObj.fiducials.inion(1),obj.hmObj.fiducials.inion(2),obj.hmObj.fiducials.inion(3),'filled',...
                    'MarkerEdgeColor','k','MarkerFaceColor','K');
                obj.hLabels(end+1) = text('Position',1.1*obj.hmObj.fiducials.inion,'String','Ini','FontSize',12,'FontWeight','bold','Color','k','Parent',obj.hAxes);
            end
            
            % cortex
            color = obj.getAtlasColor();
            obj.hCortexL = patch('vertices',obj.hmObj.fvLeft.vertices,'faces',obj.hmObj.fvLeft.faces,'FaceVertexCData',color(obj.hmObj.leftH,:),...
                'FaceColor','interp','FaceLighting','phong','LineStyle','none','FaceAlpha',1,'SpecularColorReflectance',0,...
                'SpecularExponent',50,'SpecularStrength',0.5,'Parent',obj.hAxes);
            
            obj.hCortexR = patch('vertices',obj.hmObj.fvRight.vertices,'faces',obj.hmObj.fvRight.faces,'FaceVertexCData',color(obj.hmObj.rightH,:),...
                'FaceColor','interp','FaceLighting','phong','LineStyle','none','FaceAlpha',1,'SpecularColorReflectance',0,...
                'SpecularExponent',50,'SpecularStrength',0.5,'Parent',obj.hAxes);
            
            camlight(0,180)
            camlight(0,0)
            
            % skull
            obj.hSkull = patch('vertices',obj.hmObj.outskull.vertices,'faces',obj.hmObj.outskull.faces,'facecolor','white',...
                'facelighting','phong','LineStyle','none','FaceAlpha',.45,'Parent',obj.hAxes);
            
            % scalp
            skinColor = [1,.75,.65];
            obj.hScalp = patch('vertices',obj.hmObj.scalp.vertices,'faces',obj.hmObj.scalp.faces,'facecolor',skinColor,...
                'facelighting','phong','LineStyle','none','FaceAlpha',.45,'Parent',obj.hAxes);
            colormap(hsv(length(obj.hmObj.atlas.label)))
            camlight(0,180)%,'infinite') gouraud
            camlight(0,0)
            view(obj.hAxes,[90 0]);
            hold(obj.hAxes,'off');
            axis(obj.hAxes,'equal','vis3d');
            axis(obj.hAxes,'off')
            set(obj.hFigure,'Visible','on','userData',obj);
            rotate3d
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
                    set(obj.hFiducials,'Visible','on');
                case 'sensorsOff'
                    set(obj.hSensors,'Visible','off');
                    set(obj.hFiducials,'Visible','off');
                case 'scalpOn'
                    set(obj.hScalp,'FaceAlpha',0.45)
                case 'scalpOff'
                    set(obj.hScalp,'FaceAlpha',0)
                case 'skullOn'
                    set(obj.hSkull,'Visible','on');
                case 'skullOff'
                    set(obj.hSkull,'Visible','off');
                case 'atlasOn'
                    color = obj.getAtlasColor();
                    set(obj.hCortexL,'FaceVertexCData',color(obj.hmObj.leftH,:),'LineStyle','none','FaceColor','interp');
                    set(obj.hCortexR,'FaceVertexCData',color(obj.hmObj.rightH,:),'LineStyle','none','FaceColor','interp');
                case 'atlasOff'
                    set([obj.hCortexL obj.hCortexR],'FaceColor',[1,.75,.65],'LineStyle','-');
                case 'roiModeOn'
                    set(obj.dcmHandle,'UpdateFcn',@(src,event)showLabel(obj,event,true));
                    obj.roiLabels = {};
                case 'roiModeOff'
                    set(obj.dcmHandle,'UpdateFcn',@(src,event)showLabel(obj,event,false));
            end
        end
        function color = getAtlasColor(obj)
            if isfield(obj.hmObj.atlas,'color')
                color = obj.hmObj.atlas.color;
            else
                colorTmp = jet(length(obj.hmObj.atlas.label));
                color = ones(size(obj.hmObj.K,2),3);
                color(obj.hmObj.atlas.colorTable~=0,:) = colorTmp(obj.hmObj.atlas.colorTable(obj.hmObj.atlas.colorTable~=0),:);
            end
        end
        %%
        function output_txt = showLabel(obj,event_obj, storeLabel)
            if strcmp(obj.dcmHandle.Enable,'off'),return;end
            if nargin < 3, storeLabel = true;end
            pos = get(event_obj,'Position');
            [~,~,loc] = geometricTools.nearestNeighbor(pos,obj.hmObj.cortex.vertices);
            try
                output_txt = obj.hmObj.atlas.label{obj.hmObj.atlas.colorTable(loc)};
            catch
                output_txt = 'No labeled';
            end            
            % store label in cell array
            if storeLabel, obj.roiLabels = unique([obj.roiLabels(:); output_txt]);end
        end
        %%
        function viewHemisphere(obj,~)
            obj.lrState = obj.lrState+1;
            obj.lrState(obj.lrState>2) = 0;
            switch obj.lrState
                case 1
                    obj.hCortexR.Visible = 'off';
                    obj.hCortexL.Visible = 'on';
                    
                case 2
                    obj.hCortexR.Visible = 'on';
                    obj.hCortexL.Visible = 'off';
                    
                otherwise
                    obj.hCortexR.Visible = 'on';
                    obj.hCortexL.Visible = 'on';
            end
        end
    end
end