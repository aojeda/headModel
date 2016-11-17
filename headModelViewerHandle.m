classdef headModelViewerHandle < handle
    properties
        hFigure
        hAxes
        hmObj
        hFiducials
        hLabels
        hSensors
        hScalp
        hSkull
        hCortex
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
        function obj = headModelViewerHandle(hmObj)
            obj.hmObj = hmObj; 
            color = ones(1, 3); %[0.93 0.96 1];
            path = fileparts(which('headModelViewerHandle.m'));
            path = fullfile(path,'skin');
            
            labelsOn  = imread([path filesep 'labelsOn.png']);
            labelsOff = imread([path filesep 'labelsOff.png']);
            sensorsOn = imread([path filesep 'sensorsOn.png']);
            sensorsOff = imread([path filesep 'sensorsOff.png']);
            scalpOn = imread([path filesep 'scalpOn.png']);
            scalpOff = imread([path filesep 'scalpOff.png']);
            skullOn = imread([path filesep 'skullOn.png']);
            skullOff = imread([path filesep 'skullOff.png']);
            cortexOn = imread([path filesep 'cortexOn.png']);
            cortexOff = imread([path filesep 'cortexOff.png']);
            atlasOn = imread([path filesep 'atlasOn.png']);
            atlasOff = imread([path filesep 'atlasOff.png']);
            roiModeOn  = imread([path filesep 'selectRoiOn.svg.png']);
            roiModeOff  = imread([path filesep 'selectRoiOff.svg.png']);
            lrBrain = imread([path filesep 'lr_brain.png']);
            
            [~,~, obj.leftH, obj.rightH] = geometricTools.splitBrainHemispheres(hmObj.cortex);

            obj.hFigure = figure('Menubar','figure','ToolBar','figure','renderer','opengl','Visible','on','Color',color,'Name','Head model');
            position = get(obj.hFigure,'position');
            set(obj.hFigure,'position',[position(1:2) 648 490]);

            obj.hAxes = axes('Parent',obj.hFigure);
            
            toolbarHandle = findall(obj.hFigure,'Type','uitoolbar');
            
            hcb(1) = uitoggletool(toolbarHandle,'CData',labelsOn,'Separator','on','HandleVisibility','off','TooltipString','Labels On/Off','userData',{labelsOn,labelsOff},'State','on');
            set(hcb(1),'OnCallback',@(src,event)rePaint(obj,hcb(1),'labelsOn'),'OffCallback',@(src, event)rePaint(obj,hcb(1),'labelsOff'));
            
            hcb(2) = uitoggletool(toolbarHandle,'CData',sensorsOn,'Separator','off','HandleVisibility','off','TooltipString','Sensors On/Off','userData',{sensorsOn,sensorsOff},'State','on');
            set(hcb(2),'OnCallback',@(src,event)rePaint(obj,hcb(2),'sensorsOn'),'OffCallback',@(src, event)rePaint(obj,hcb(2),'sensorsOff'));
            
            hcb(3) = uitoggletool(toolbarHandle,'CData',scalpOn,'Separator','off','HandleVisibility','off','TooltipString','Scalp On/Off','userData',{scalpOn,scalpOff},'State','on');
            set(hcb(3),'OnCallback',@(src,event)rePaint(obj,hcb(3),'scalpOn'),'OffCallback',@(src, event)rePaint(obj,hcb(3),'scalpOff'));
            
            hcb(4) = uitoggletool(toolbarHandle,'CData',skullOn,'Separator','off','HandleVisibility','off','TooltipString','Skull On/Off','userData',{skullOn,skullOff},'State','on');
            set(hcb(4),'OnCallback',@(src,event)rePaint(obj,hcb(4),'skullOn'),'OffCallback',@(src, event)rePaint(obj,hcb(4),'skullOff'));
            
            hcb(5) = uitoggletool(toolbarHandle,'CData',cortexOn,'Separator','off','HandleVisibility','off','TooltipString','Cortex On/Off','userData',{cortexOn,cortexOff},'State','on');
            set(hcb(5),'OnCallback',@(src,event)rePaint(obj,hcb(5),'cortexOn'),'OffCallback',@(src, event)rePaint(obj,hcb(5),'cortexOff'));
            
            hcb(6) = uitoggletool(toolbarHandle,'CData',atlasOn,'Separator','off','HandleVisibility','off','TooltipString','Atlas On/Off','userData',{atlasOn,atlasOff},'State','on');
            set(hcb(6),'OnCallback',@(src,event)rePaint(obj,hcb(6),'atlasOn'),'OffCallback',@(src, event)rePaint(obj,hcb(6),'atlasOff'));
            
            hcb(7) = uitoggletool(toolbarHandle,'CData',roiModeOn,'Separator','on','HandleVisibility','off','TooltipString','ROI mode On/Off','userData',{roiModeOn,roiModeOff},'State','off');
            set(hcb(7),'OnCallback',@(src,event)rePaint(obj,hcb(7),'roiModeOn'),'OffCallback',@(src, event)rePaint(obj,hcb(7),'roiModeOff'));
            
            hcb(8) = uitoggletool(toolbarHandle,'CData',lrBrain,'Separator','off','HandleVisibility','off','TooltipString','View left/right hemisphere','State','off');
            set(hcb(8),'OnCallback',@(src,event)viewHemisphere(obj,hcb(8)),'OffCallback',@(src, event)viewHemisphere(obj,hcb(8)));
            
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
            if ~isempty(obj.hmObj.atlas),
                obj.hCortex = patch('vertices',obj.hmObj.cortex.vertices,'faces',obj.hmObj.cortex.faces,'FaceVertexCData',obj.hmObj.atlas.colorTable,...
                    'FaceColor','interp','FaceLighting','phong','LineStyle','none','FaceAlpha',1,'SpecularColorReflectance',0,...
                    'SpecularExponent',50,'SpecularStrength',0.5,'Parent',obj.hAxes);
                camlight(0,180)
                camlight(0,0)
            else
                obj.hCortex = patch('vertices',obj.hmObj.cortex.vertices,'faces',obj.hmObj.cortex.faces,'facecolor','green',...
                    'FaceLighting','gouraud','LineStyle','-','LineWidth',.005,'EdgeColor',[.3 .3 .3],'AmbientStrength',.4,...
                    'FaceAlpha',1,'SpecularColorReflectance',0,'SpecularExponent',50,'SpecularStrength',0.5,'Parent',obj.hAxes);
            end
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
                    set(obj.hFiducials,'Visible','on');
                case 'sensorsOff'
                    set(obj.hSensors,'Visible','off');
                    set(obj.hFiducials,'Visible','off');
                case 'scalpOn'
                    set(obj.hScalp,'Visible','on');
                case 'scalpOff'
                    set(obj.hScalp,'Visible','off');
                case 'skullOn'
                    set(obj.hSkull,'Visible','on');
                case 'skullOff'
                    set(obj.hSkull,'Visible','off');
                case 'cortexOn'
                    set(obj.hCortex,'Visible','on');
                case 'cortexOff'
                    set(obj.hCortex,'Visible','off');
                case 'atlasOn'
                    set(obj.hCortex,'FaceVertexCData',obj.hmObj.atlas.colorTable,'LineStyle','none','FaceColor','interp');
                case 'atlasOff'
                    set(obj.hCortex,'FaceColor',[1,.75,.65],'LineStyle','-');
                case 'roiModeOn'
                    set(obj.dcmHandle,'UpdateFcn',@(src,event)showLabel(obj,event,true));
                    obj.roiLabels = {};
                case 'roiModeOff'
                    set(obj.dcmHandle,'UpdateFcn',@(src,event)showLabel(obj,event,false));
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
            if isempty(obj.FaceVertexCData)
                obj.FaceVertexCData = get(obj.hCortex,'FaceVertexCData');
            end
            val = obj.FaceVertexCData;
            obj.lrState = obj.lrState+1;
            switch obj.lrState
                case 1
                    val(obj.rightH,:) = nan;
                case 2
                    val(obj.leftH,:) = nan;
            end
            if obj.lrState > 2; obj.lrState = 0;end
            set(obj.hCortex,'FaceVertexCData',val);
        end
    end
end