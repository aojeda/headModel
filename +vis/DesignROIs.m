function fig = DesignROIs(hm, transform2MNI)
if nargin < 1, hm = headModel.loadDefault;end
if nargin < 2, transform2MNI = true;end
if transform2MNI
    hm.transform2MNI();
end
skinColor = [1,.75,.65];
fig = hm.plot;
fig.hScalp.Visible = 'off';
fig.hSensors.Visible = 'off';
fig.hSkull.Visible = 'off';
set(fig.hLabels,'Visible','off');
fig.hScalp.Visible = 'off';

fig.hAxes.Position = [-0.0851    0.1215    0.7365    0.7933];
pn = uipanel(fig.hFigure, 'Position',[0.5228    0.0393    0.4605    0.9358]);

uicontrol(pn,'Style','tex','String','Face alpha','units','normalized','Position',[0.1689    0.0618    0.3724    0.0379]);
uicontrol(pn,'Style', 'slider','Min',0,'Max',1,'Value',1,'Units','normalized',...
    'Position',[0.0163    0.0090    0.7451    0.0401],'Value',1,'Callback',@setCortexAlpha,'TooltipString','Face alpha');

%axis(fig.hAxes,'tight');

uicontrol(pn,'Style','tex','String','ROI area','units','normalized','Position',[0.1698    0.1387    0.3855    0.0504]);
uicontrol(pn,'Style', 'slider','Min',0,'Max',50,'Value',0,'Units','normalized',...
    'Position',[0.0163    0.1126    0.7451    0.0401],'Value',0.5,'Callback',@updateSlider,...
    'TooltipString','ROI area','UserData',[],'tag','sliderArea');       

uicontrol(pn,'Style','edit','units','normalized','Position',[0.8171    0.1126    0.1751    0.0412],'tag','editArea','callback',@updateEdit);

fig.hCortexL.FaceVertexCData = repmat(skinColor,size(fig.hCortexL.FaceVertexCData,1),1);
fig.hCortexR.FaceVertexCData = repmat(skinColor,size(fig.hCortexR.FaceVertexCData,1),1);

uicontrol(pn,'Style','text','String','Enter seeds (one by line)','units','normalized','Position',[0.0156    0.9304    0.9584    0.0504]);
Data = cell(500,3);
for k=1:500, Data{k,1} = false;end
uitable(pn,'Tag','seeds','ColumnEditable',true,'ColumnName',{'Select','Network','Seeds'},...
    'units','normalized','Position',[0.02 0.28 0.97 0.6593],'Data',Data);
%'ColumnWidth',ColumnWidth,...

% uicontrol(pn,'Style','edit','units','normalized','Position',[0.0678    0.3904    0.8646    0.5365],...
%     'tag','seeds','max',5000,'HorizontalAlignment','left');

uicontrol(pn,'Style','pushbutton','String','Set','callback',@setSeeds,'units','normalized','Position',[0.5    0.22    0.2041    0.0440]);
uicontrol(pn,'Style','pushbutton','String','Clear','callback',@cleanSeeds,'units','normalized','Position',[0.7721   0.22    0.2041    0.0440]);
uicontrol(pn,'Style','pushbutton','String','Save','callback',@saveAs,'units','normalized','Position',[0.23   0.22    0.2041    0.0440]);

end

function setSeeds(src, evnt)
cleanSeeds(src, evnt);
fig = src.Parent.Parent.UserData;
in = get(findobj(src.Parent.Children,'tag','seeds'),'Data');
n = size(in,1);
sel = false(n,1);
net = cell(n,1);
seeds = zeros(n,3);
hold(fig.hAxes,'on');
rmthis = [];

for k=1:n
    try
        sel(k) = in{k,1};
        net{k} = in{k,2};
        seeds(k,:) = str2num(in{k,3}); %#ok
    catch
        rmthis = [k rmthis];
    end
end
sel(rmthis) = [];
net(rmthis) = [];
seeds(rmthis,:) = [];

net(~sel) = [];
seeds(~sel,:) = [];

uniqueNet = unique(net);
color = parula(length(uniqueNet));

for k=1:size(seeds,1)
    ind = find(ismember(uniqueNet, net{k}));
    [sx,sy,sz] = ellipsoid(seeds(k,1),seeds(k,2),seeds(k,3),2,2,2);
    surf(fig.hAxes,sx,sy,sz,'LineStyle','none','FaceColor',color(ind,:),'tag','SeedSurf');
end
set(findobj(fig.hFigure,'tag','sliderArea'),'UserData',seeds);
hold(fig.hAxes,'off');

val = get(findobj(fig.hFigure,'tag','sliderArea'),'Value');
setArea(val);
end

function cleanSeeds(src, evnt)
fig = src.Parent.Parent.UserData;
delete(findall(fig.hAxes,'tag','SeedSurf'));
skinColor = [1,.75,.65];
fig.hCortexL.FaceVertexCData = repmat(skinColor,size(fig.hCortexL.FaceVertexCData,1),1);
fig.hCortexR.FaceVertexCData = repmat(skinColor,size(fig.hCortexR.FaceVertexCData,1),1);
end

function setCortexAlpha(src, evnt)
fig = src.Parent.Parent.UserData;
fig.hCortexL.FaceAlpha = src.Value;
fig.hCortexR.FaceAlpha = src.Value;
end

function updateEdit(src, evnt)
fig = src.Parent.Parent.UserData;
val = str2double(src.String);
set(findobj(fig.hFigure,'tag','sliderArea'),'Value',val);
setArea(val);
end


function updateSlider(src, evnt)
fig = src.Parent.Parent.UserData;
val = src.Value;
set(findobj(fig.hFigure,'tag','editArea'),'String',num2str(val));
setArea(val);
end

function setArea(val)
skinColor = [1,.75,.65];
fig = get(gcf,'UserData');
hm = fig.hmObj;
color = repmat(skinColor,size(hm.cortex.vertices,1),1);
fig.hCortexL.FaceVertexCData = color(hm.leftH,:);
fig.hCortexR.FaceVertexCData = color(hm.rightH,:);

hSlider = findobj(fig.hFigure,'tag','sliderArea');
seeds = hSlider.UserData;
if isempty(seeds)
    return;
end
[~,~,seedIndices] = geometricTools.nearestNeighbor(seeds,hm.cortex.vertices);
n = length(seedIndices);
roiIndices = cell(n,1);
for k=1:n
    roiIndices{k} = seedIndices(k);
end
a = zeros(n,1);

while any(a/100 < val)
    for k=1:n
        IND = [];
        for i=1:length(roiIndices{k})
            ind_i = find(any(hm.cortex.faces == roiIndices{k}(i),2));
            IND = [IND;ind_i];
        end
        roiIndices{k} = [roiIndices{k};  unique(hm.cortex.faces(IND,:))];
        a(k) = geometricTools.getSurfaceArea(hm.cortex.vertices,hm.cortex.faces(roiIndices{k},:));
        
    end
end
hSurf = flipud(findall(fig.hFigure,'tag','SeedSurf'));
indNoGM = find(hm.atlas.colorTable==0);
for k=1:n
    [~,loc1,loc2] = intersect(roiIndices{k},indNoGM);
    roiIndices{k}(loc1) = [];
    color(roiIndices{k},:) = ones(length(roiIndices{k}),1)*hSurf(k).FaceColor;
end
color(indNoGM,:) = repmat(skinColor,length(indNoGM),1);
fig.hCortexL.FaceVertexCData = color(hm.leftH,:);
fig.hCortexR.FaceVertexCData = color(hm.rightH,:);
set(findobj(fig.hFigure, 'tag','seeds'),'UserData',roiIndices);
end


function saveAs(src,evnt)
fig = src.Parent.Parent.UserData;
roiIndices = get(findobj(fig.hFigure, 'tag','seeds'),'UserData');
data = get(findobj(fig.hFigure, 'tag','seeds'),'Data');

[FileName,PathName,FilterIndex] = uiputfile('.mat','Save as');
if FilterIndex
    save(fullfile(PathName,FileName),'roiIndices','data');
end
end