classdef Connectivity < handle
    properties
        C
        srcLabel
        roiName
        roiIndices
    end
    methods
        function self = Connectivity(C, srcLabel, roiName, roiIndices)
            self.C = C;
            self.roiIndices = roiIndices;
            self.roiName = roiName;
            self.srcLabel = srcLabel;
        end
        function ax = image(self, ax, scaleType)
            if nargin < 2,
                hFigure = figure;
                ax = axes;
            else
                hFigure = get(ax,'Parent');
                cla(ax);
            end
            if nargin < 3, scaleType = 'bipolar';end
            [Cs, I] = self.sort();
            mx = prctile(nonzeros(Cs(:)),95);
            mx(mx==0) = max(abs(Cs(:)));
            if strcmp(scaleType,'bipolar')
                scale = [-mx mx];
                color = bipolar(256,0.99);
            else
                scale = [0 mx];
                color = bipolar(256,0.99);
                color = color(129:end,:);
            end
            imagesc(Cs,scale);
            colormap(color);
            colorbar;
            xlabel('Sources');
            ylabel('Sources');
            title('Connectivity matrix')
            dcmHandle = datacursormode(hFigure);
            dcmHandle.SnapToDataVertex = 'off';
            set(dcmHandle,'UpdateFcn',@(src,event)showLabel(self,event));
            dcmHandle.Enable = 'off';
            set(hFigure,'UserData', {dcmHandle, I});
        end
        function [Cs, I] = sort(self)
            Cs = self.C*0;
            I = zeros(1,size(self.C,1));
            ptr_i = 0;
            ptr_j = 0;
            for i=1:length(self.roiName)
                ind_i = find(self.roiIndices(:,i));
                for j=1:length(self.roiName)
                    ind_j = find(self.roiIndices(:,j));
                    if isempty([ind_i(:); ind_j(:)]), continue;end
                    n_i = length(ind_i);
                    n_j = length(ind_j);
                    loc_i = (1:n_i)+ptr_i;
                    loc_j = (1:n_j)+ptr_j;
                    Cs(loc_i,loc_j) = self.C(ind_i,ind_j);
                    ptr_j = ptr_j+n_j;
                end
                I(ptr_i+1:ptr_i+n_i) = i;
                ptr_i = ptr_i+n_i;
                ptr_j = 0;
            end
        end
    end
    methods(Hidden)
        function output_txt = showLabel(self,eventObj)
            userData = get(eventObj.Target.Parent.Parent,'userdata');
            loc = userData{2};
            pos = get(eventObj,'Position');
            try
                roi_i = self.roiName{loc(pos(2))};roi_i(1) = upper(roi_i(1));
                roi_j = self.roiName{loc(pos(1))};roi_j(1) = upper(roi_j(1));
                output_txt = ['(' roi_i ', ' roi_j ', ' num2str(eventObj.Target.CData(pos(2),pos(1))) ')'];
            catch
                output_txt = 'No labeled';
            end
        end
    end
end