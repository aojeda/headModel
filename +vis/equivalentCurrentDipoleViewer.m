classdef equivalentCurrentDipoleViewer < vis.headModelViewer
    properties
        cortexAlpha
        hDipoles
        hVector
        ecd
        xyz
    end
    methods
        function obj = equivalentCurrentDipoleViewer(hmObj,xyz,ecd,dipoleLabel,figureTitle)
            if nargin < 2, error('Not enough input arguments.');end
            N = size(xyz,1);
            if nargin < 3, ecd = ones(N,3);end
            if nargin < 4, dipoleLabel = [];end
            if nargin < 5, figureTitle = '';end
            if size(ecd,2) == 1, ecd = [ecd,ecd,ecd]/3;end
            obj = obj@vis.headModelViewer(hmObj);
            obj.hScalp.Visible = 'off';
            obj.hSkull.Visible = 'off';
            obj.hSensors.Visible = 'off';
            set(obj.hLabels,'Visible','off');
            obj.hCortexL.FaceAlpha = 0.1;
            obj.hCortexR.FaceAlpha = 0.1;
            hold(obj.hAxes,'on');
            obj.ecd = ecd;
            obj.xyz = xyz;
            
            % dipoles
            Norm = 0.01*mean(sqrt(sum(obj.hmObj.cortex.vertices.^2,2)));
            ecd = Norm*ecd;%/norm(ecd);
            for it=1:size(xyz,1)
                [sx,sy,sz] = ellipsoid(xyz(it,1),xyz(it,2),xyz(it,3),ecd(it,1),ecd(it,2),ecd(it,3));
                obj.hDipoles = [obj.hDipoles surf(obj.hAxes,sx,sy,sz,'LineStyle','none','FaceColor','y')];
            end

            % vectors
            hvx = quiver3(xyz(:,1),xyz(:,2),xyz(:,3),ecd(:,1),0*ecd(:,2),0*ecd(:,3),0.25,'r','LineWidth',2);
            hvy = quiver3(xyz(:,1),xyz(:,2),xyz(:,3),0*ecd(:,1),ecd(:,2),0*ecd(:,3),0.25,'g','LineWidth',2);
            hvz = quiver3(xyz(:,1),xyz(:,2),xyz(:,3),0*ecd(:,1),0*ecd(:,2),ecd(:,3),0.25,'b','LineWidth',2);
            obj.hVector = [hvx;hvy;hvz];
            hold(obj.hAxes,'off');
            obj.cortexAlpha = uicontrol(obj.hFigure,'Style', 'slider','Min',0,'Max',1,'Value',1,'Units','normalized',...
                'Position',[0.0571    0.3347    0.0447    0.3922],'Value',0.5,'Callback',@obj.setCortexAlpha,'TooltipString','FaceAlpha');
        end
        function setCortexAlpha(obj,~,~)
            obj.hCortexL.FaceAlpha = obj.cortexAlpha.Value;
            obj.hCortexR.FaceAlpha = obj.cortexAlpha.Value;
        end
    end
end
