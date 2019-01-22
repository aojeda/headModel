% Defines the class ROITimeFrequencyGrid for visualization of time frequency stats on ROI space.
%
% Author: Alejandro Ojeda, NEATLABS/UCSD, Sep-2019

classdef  ROITimeFrequencyGrid < vis.headModelViewer
    properties
        hCortex
    end
    methods
        function obj = ROITimeFrequencyGrid(hm, data, timeStamps, freq, figureTitle)
            dim = size(data);
            if nargin < 3
                timeStamps = 1:dim(2);
            end
            if nargin < 4
                freq = 1:dim(3);
            end
            if nargin < 5, figureTitle = '';end
            [yTicks, yTickLabels] = logFreq2Ticks(freq);
            mx = max(abs(prctile(nonzeros(data),[10 90])));
            mn = -mx;
            obj = obj@vis.headModelViewer(hm);
            set(obj.hSensors,'Visible','off')
            set(obj.hLabels,'Visible','off')
            set(obj.hScalp,'Visible','off')
            set(obj.hSkull,'Visible','off')
            view(obj.hAxes,[-90 90])
            set(obj.hFigure,'units','normalized','outerposition',[0 0 1 1])
            skinColor = [1,.75,.65];
            obj.hCortexL.FaceVertexCData = repmat(skinColor, size(obj.hCortexL.FaceVertexCData,1),1);
            obj.hCortexR.FaceVertexCData = repmat(skinColor, size(obj.hCortexR.FaceVertexCData,1),1);
            set([obj.hCortexL obj.hCortexR],'FaceAlpha',0.05);
            hold(obj.hAxes,'on');
            obj.hCortex = patch('vertices',obj.hmObj.cortex.vertices,'faces',obj.hmObj.cortex.faces,'FaceVertexCData',nan(size(obj.hmObj.cortex.vertices,1),3),...
                'FaceColor','interp','FaceLighting','phong','LineStyle','none','FaceAlpha',1,'SpecularColorReflectance',0,...
                'SpecularExponent',50,'SpecularStrength',0.5,'Parent',obj.hAxes);
            hold(obj.hAxes,'off');
            set(obj.hAxes,'Position',[0.1250    0.6834    0.7608    0.3079])
            p1 = uipanel(obj.hFigure,'units','normalized','Position',[0   0 0.5 0.67]);
            p2 = uipanel(obj.hFigure,'units','normalized','Position',[0.5 0 0.5 0.67]);
            
            c = hm.getCentroidROI(hm.atlas.label(1:2:end));
            [~,sorting_L] = sort(c(:,1),'descend');
            n = length(hm.atlas.label);
            loc = 1:2:n;
            sorting_L = loc(sorting_L);
            sorting_R = sorting_L+1;
            nc = floor(n/2/5);
            nr = ceil(n/2/nc);
            panel = 1;
            rotate3d off;
%             colormap parula;
%             colormap bipolar
            colormap(bipolar(256,0.8));
            for i=1:nr
                for j=1:nc
                    if panel > n/2
                        continue
                    end
                    ax = subplot(nc,nr,panel,'parent',p1);
                    cla(ax)
                    imagesc(timeStamps,1:length(freq),squeeze(data(sorting_L(panel),:,:))','PickableParts','all','ButtonDownFcn',@onClick,'UserData',hm.atlas.label{sorting_L(panel)});
                    set(ax,'YDir','normal','FontSize',5,'YTick',yTicks,'YTickLabels',yTickLabels,'CLim',[mn mx]);
                    title(hm.atlas.label{sorting_L(panel)})
                    panel = panel+1;
                end
            end
            panel = 1;
            for i=1:nr
                for j=1:nc
                    if panel > n/2
                        continue
                    end
                    ax = subplot(nc,nr,panel,'parent',p2);
                    cla(ax)
                    imagesc(timeStamps,1:length(freq),squeeze(data(sorting_R(panel),:,:))','PickableParts','all','ButtonDownFcn',@onClick,'UserData',hm.atlas.label{sorting_R(panel)});
                    set(ax,'YDir','normal','FontSize',5,'YTick',yTicks,'YTickLabels',yTickLabels,'CLim',[mn mx]);
                    title(hm.atlas.label{sorting_R(panel)})
                    panel = panel+1;
                end
            end
        end
    end
end
%%
function onClick(src,evnt)
obj = src.Parent.Parent.Parent.UserData;
obj.hCortex.FaceVertexCData = nan(size(obj.hCortex.FaceVertexCData,1),3);
ind = find(obj.hmObj.indices4Structure(src.UserData));
if isempty(ind)
    return
end
if any(ismember(obj.hmObj.leftH,ind))
    roiColor = [0 0 1];
else
    roiColor = [1 0 0];
end
obj.hCortex.FaceVertexCData(ind,:) = repmat(roiColor,length(ind),1);
end
%%
function [yTicks, yTickLabels] = logFreq2Ticks(freq)
YTicks = [2 3 5 10 20 50 100];
YTicks(YTicks>max(freq) | YTicks<min(freq)) = [];
n = length(YTicks);
yTicks = zeros(n,1);
yTickLabels = cell(n,1);
for k=1:n
    [~, yTicks(k)] = min(abs(YTicks(k)-freq));
    yTickLabels{k} = num2str(YTicks(k));
end
end