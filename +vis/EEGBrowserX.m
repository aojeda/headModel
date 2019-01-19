% Defines the class EEGBrowserX for visualization of EEG inverse solutions on a realistic head model.
%
% Author: Alejandro Ojeda, NEATLABS/UCSD, Sep-2018

classdef EEGBrowserX < vis.currentSourceViewer
    properties
        hAxes2
        hTCursor
        trial = 1;
        EEG
        hTrial
        source
    end
    properties(GetAccess=private,Hidden)
        hEEG;
        hEEG2
        scale = 1;
    end
    methods
        function obj = EEGBrowserX(EEG, figureTitle, clim)
            if nargin < 2, figureTitle = '';end
            if nargin < 3, clim = [];end
            J = EEG.etc.src.actFull(:,:,1);
            V = EEG.data(:,:,1);
            hm = headModel.loadFromFile(EEG.etc.src.hmfile);
            obj = obj@vis.currentSourceViewer(hm,J,V,figureTitle,false, EEG.srate, EEG.times);
            if ~isempty(clim)
                obj.clim.source = clim;
                obj.clim.scalp = clim;
                set(obj.hAxes,'Clim',obj.clim.source);
                obj.colorBar.Ticks = linspace(obj.clim.source(1)*0.9,obj.clim.source(2)*0.9,3);
            end
            obj.EEG = EEG;
            obj.source = EEGSource(EEG);
            
            obj.hFigure.Position(3) = 775;
            rotate3d(obj.hAxes,'off');
            set(obj.hFigure,'KeyPressFcn',@onKeyPress);
            obj.hFigure.UserData = obj;
            rotate3d(obj.hAxes,'on');
            obj.hAxes.Position = [0.1300    0.4464    0.6435    0.5434];
            obj.hAxes2 = axes('Position',[0.0915    0.1718    0.8662    0.2510]);
            sd = 5*median(median(std(obj.EEG.data,[],2),3));
            ytick = (obj.EEG.nbchan:-1:1)*sd;
            V = obj.scale*obj.EEG.data(:,:,obj.trial) + ytick'*ones(1,obj.EEG.pnts);
            obj.hEEG = plot(obj.hAxes2,EEG.times, V');
            % obj.hEEG = flipud(obj.hEEG);
            grid(obj.hAxes2,'on');
            xlabel(obj.hAxes2,'Time (msec)');
            ylabel(obj.hAxes2,'EEG (mV)');
            xlim(obj.hAxes2,EEG.times([1 end]));
            ylim(obj.hAxes2,[-ytick(end) ytick(1)+2*sd]);
            set(obj.hAxes2,'YTickLabel',fliplr({obj.EEG.chanlocs.labels}),'YTick',fliplr(ytick))
            hold(obj.hAxes2,'on');
            yl = get(obj.hAxes2,'ylim');
            obj.hTCursor = plot(obj.hAxes2,obj.time(obj.timeCursor.Value)*[1 1],10*yl,'k-.','linewidth',0.5);
            set(obj.hAxes2,'ylim',yl)
            hold(obj.hAxes2,'off');
            drawnow;
            toolbarHandle = findall(obj.hFigure,'Type','uitoolbar');
            delete(findall(obj.hFigure,'TooltipString','Help'))
            path = fileparts(which('headModel.m'));
            path = fullfile(path,'+vis','icons');
            prevTrial  = imresize(imread([path filesep 'Gnome-media-skip-backward.svg.png']),[28 28]);
            nextTrial  = imresize(imread([path filesep 'Gnome-media-skip-forward.svg.png']),[28 28]);
            helpIcon = imresize(imread([path filesep 'Gnome-help-browser.svg.png']),[28 28]);
            uitoggletool(toolbarHandle,'CData',prevTrial,'Separator','on','HandleVisibility','off','TooltipString','Previous trial',...
                'onCallback',@obj.prevTrial, 'offCallback',@obj.prevTrial);
            uitoggletool(toolbarHandle,'CData',nextTrial,'Separator','on','HandleVisibility','off','TooltipString','Next trial',...
                'onCallback',@obj.nextTrial,'offCallback',@obj.nextTrial);
            uitoggletool(toolbarHandle,'CData',helpIcon,'Separator','on','HandleVisibility','off','TooltipString','Help','State','off',...
                'onCallback','web(''https://github.com/aojeda/headModel#headmodel-toolbox-for-matlabeeglab'')','offCallback','web(''https://github.com/aojeda/headModel#headmodel-toolbox-for-matlabeeglab'')');
            title(obj.hAxes2,['Trial: ' num2str(obj.trial) '/' num2str(obj.EEG.trials)]);
        end
        
        %%
        function prevTrial(obj,src,evnt)
            obj.trial = obj.trial - 1;
            obj.trial(obj.trial<1) = 1;
            obj.changeTrial;
        end
        function nextTrial(obj,src,evnt)
            obj.trial = obj.trial +1;
            obj.trial(obj.trial>obj.EEG.trials) = obj.EEG.trials;
            obj.changeTrial;
        end
        function changeTrial(obj)
            obj.hFigure.Pointer = 'watch';
            drawnow
            obj.setJ(obj.source.get_source_trial(obj.trial))
            obj.setV(obj.EEG.data(:,:,obj.trial));
            for k=1:obj.EEG.nbchan
                set(obj.hEEG(k),'YData',obj.scale*obj.EEG.data(k,:,obj.trial) + obj.hAxes2.YTick(obj.EEG.nbchan-k+1));
            end
            obj.plot();
            title(obj.hAxes2,['Trial: ' num2str(obj.trial) '/' num2str(obj.EEG.trials)]);
            obj.hFigure.Pointer = 'arrow';
            drawnow
        end
        %%
        function plot(obj,~,~)
            plot@vis.currentSourceViewer(obj);
            set(obj.hTCursor,'XData',obj.time(obj.pointer)*[1 1]);
        end
        
    end
end

function onKeyPress(src,evnt)
obj = src.UserData;
switch evnt.Key
    case 'subtract'
        obj.scale = obj.scale/2;
    case 'add'
        obj.scale = obj.scale*2;
end
for k=1:obj.EEG.nbchan
    set(obj.hEEG(k),'YData',obj.scale*obj.EEG.data(k,:,obj.trial) + obj.hAxes2.YTick(obj.EEG.nbchan-k+1));
end

end