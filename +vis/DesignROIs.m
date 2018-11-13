function fig = DesignROIs(hm, transform2MNI)
fig = findall(0,'Tag','NetworkDesigner');
if ~isempty(fig)
    figure(fig);
    fig = fig.UserData;
    return;
end
if nargin < 1
    template = which('head_modelColin27_10003_Standard-10-5-Cap339-Destrieux148.mat');
    hm = headModel.loadFromFile(template);
    % hm = headModel.loadDefault;
end
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
fig.hFigure.Position(3) = 956;
set(fig.hFigure,'Name','Network Designer','NumberTitle','off','Tag','NetworkDesigner');


axis(fig.hAxes,'tight');
fig.hAxes.Position = [0.2284    0.2147    0.9199    0.7730];
pn = uipanel(fig.hFigure, 'BorderType','none', 'Position',[0.0197    0.0577    0.4784    0.9358]);
 
uicontrol(pn,'Style','tex','String','Face alpha','units','normalized','Position',[0.1689    0.0858    0.3724    0.0379]);
uicontrol(pn,'Style','tex','String','ROI area','units','normalized','Position',[0.1698    0.1975    0.3855    0.0504]);

sl1 = uicontrol(pn,'Style', 'slider','Min',0,'Max',1,'Value',1,'Units','normalized',...
    'Position',[0.0163    0.0330    0.7451    0.0401],'Value',1,'Callback',@setCortexAlpha,'TooltipString','Face alpha');
sl2 = uicontrol(pn,'Style', 'slider','Min',0,'Max',50,'Value',0,'Units','normalized',...
    'Position',[0.0163    0.1584    0.7451    0.0401],'Value',0.5,'Callback',@updateSlider,...
    'TooltipString','ROI area','UserData',[],'tag','sliderArea');
addlistener(sl1,'ContinuousValueChange',@setCortexAlpha);
addlistener(sl2,'ContinuousValueChange',@updateSlider);

uicontrol(pn,'Style','edit','units','normalized','Position',[0.7889    0.1605    0.1751    0.0412],'tag','editArea','callback',@updateEdit);

fig.hCortexL.FaceVertexCData = repmat(skinColor,size(fig.hCortexL.FaceVertexCData,1),1);
fig.hCortexR.FaceVertexCData = repmat(skinColor,size(fig.hCortexR.FaceVertexCData,1),1);

uicontrol(pn,'Style','text','String','Enter seeds (one by line)','units','normalized','Position',[0.0156    0.9304    0.9584    0.0504]);
Data = cell(500,5);
for k=1:500, Data{k,1} = false;end
uitable(pn,'Tag','seeds','ColumnEditable',true,'ColumnName',{'Select','ROI','Seeds','Network','Area'},...
    'units','normalized','Position',[0.02 0.28 0.97 0.7133],'Data',Data,'ButtonDownFcn',@buttonDown);
%'ColumnWidth',ColumnWidth,...

% uicontrol(pn,'Style','edit','units','normalized','Position',[0.0678    0.3904    0.8646    0.5365],...
%     'tag','seeds','max',5000,'HorizontalAlignment','left');

imgSet = imread(fullfile(fileparts(which('headModel')),'+vis','icons','Dialog-apply.svg.png'));
imgSelectAll = imread(fullfile(fileparts(which('headModel')),'+vis','icons','Gnome-colors-fusion-icon.svg.png'));
imgPaste = imread(fullfile(fileparts(which('headModel')),'+vis','icons','Gnome-edit-paste.svg.png'));
imgMerge = imread(fullfile(fileparts(which('headModel')),'+vis','icons','Gnome-x-office-drawing.svg.png'));
imgClear = imread(fullfile(fileparts(which('headModel')),'+vis','icons','Gnome-edit-clear.svg.png'));
imgSave = imread(fullfile(fileparts(which('headModel')),'+vis','icons','Gnome-document-save-as.svg.png'));
imgHelp = imread(fullfile(fileparts(which('headModel')),'+vis','icons','Gnome-help-browser.svg.png'));
btnSize = [0.1175, 0.7674];

pn2 = uipanel(fig.hFigure, 'BorderType','none', 'Position',[0.4933    0.0577    0.4900    0.1431]);
uicontrol(pn2,'Style','pushbutton','TooltipString','Select all','CData',imgSelectAll,'callback',@selectAll,'units','normalized',  'Position',[0.0800    0.0751    btnSize]);
uicontrol(pn2,'Style','pushbutton','TooltipString','Remove ROI','CData',imgClear,'callback',@removeROI,'units','normalized','Position',[0.08+1.1*1*btnSize(1)    0.0751    btnSize]);
uicontrol(pn2,'Style','pushbutton','TooltipString','Set','CData',imgSet,'callback',@setSeeds,'units','normalized',                'Position',[0.08+1.1*2*btnSize(1)    0.0751    btnSize]);
uicontrol(pn2,'Style','pushbutton','TooltipString','Paste from clipboard','CData',imgPaste,'callback',@paste,'units','normalized','Position',[0.08+1.1*3*btnSize(1)    0.0751    btnSize]);
uicontrol(pn2,'Style','pushbutton','TooltipString','Merge ROIs','CData',imgMerge,'callback',@merge,'units','normalized',          'Position',[0.08+1.1*4*btnSize(1)    0.0751    btnSize]);
uicontrol(pn2,'Style','pushbutton','TooltipString','Save','CData',imgSave,'callback',@saveAs,'units','normalized',                'Position',[0.08+1.1*5*btnSize(1)    0.0751    btnSize]);
uicontrol(pn2,'Style','pushbutton','TooltipString','Help','CData',imgHelp,'callback',@help,'units','normalized',                  'Position',[0.08+1.1*6*btnSize(1)    0.0751    btnSize]);
end

function selectAll(src, evnt)
state = get(src,'UserData');
if isempty(state), state=true;end
hTable = findobj(src.Parent.Parent,'tag','seeds');
Data = get(hTable,'Data');
ind = ~cellfun(@isempty,Data(:,2));
if any(ind)
    Data(ind,1) = {state};
    set(hTable,'Data',Data);
    set(src,'UserData',~state)
end
end

function paste(src, evnt)
txt = deblank(clipboard('paste'));
loc = strfind(txt,newline);
%loc([end]) = [];
roi = {};
seed = [];
for k=1:length(loc)
    if k<length(loc)
        tmp = str2num(deblank(txt(loc(k)+1:loc(k+1)-1)));
    else
        tmp = str2num(deblank(txt(loc(k)+1:end)));
    end
    if isempty(tmp)
        roi{end+1,1} = deblank(txt(loc(k)+1:loc(k+1)-1));
    else
        seed = [seed; tmp];
    end
end
hTable = findobj(src.Parent.Parent,'tag','seeds');
Data = get(hTable,'Data');
ind = find(cellfun(@isempty,Data(:,2)),1);
n = length(roi);
loc = (0:n-1)+ind;
Data(loc,2) = roi;
for k=1:n
    Data{loc(k),3} = num2str(seed(k,:));
end
set(hTable,'Data',Data);
end

function merge(src, evnt)
hTable = findobj(src.Parent.Parent,'tag','seeds');
Data = get(hTable,'Data');
sel = find(cell2mat(Data(:,1)));
if length(sel) < 2
    msgbox('Only one ROI is selected, so there is nothing to merge.')
    return;
end
roi = inputdlg('Enter the name of the new ROI');
if isempty(roi)
    return;
end
n = length(sel);
xyz = zeros(n,3);
for k=1:n
    xyz(k,:) = str2num(cell2mat(Data(sel(k),3)));
end
Data(sel(1),2) = roi;
Data(sel(1),3) = {num2str(mean(xyz,1))};
Data(sel(2:end),:) = [];
for k=1:n-1
    Data(end+k,:) = {false, [],[],[],[]};
end
DataTmp = Data;
DataTmp(~cellfun(@isempty,Data(:,2)),1) = {true};
set(hTable,'Data',DataTmp);
Indices = get(findobj(src.Parent.Parent, 'tag','seeds'),'UserData');
Indices(sel(1)) = {cell2mat(Indices(sel))};
Indices(sel(2:end)) = [];
set(findobj(src.Parent.Parent, 'tag','seeds'),'UserData',Indices);
setSeeds(src, evnt);
set(hTable,'Data',Data);
end


function help(src, evnt)
web('http://neatlabs.ucsd.edu/index.html','-browser');
end


function setSeeds(src, evnt)
fig = src.Parent.Parent.UserData;
delete(findall(fig.hFigure,'tag','SeedSurf'));
hTable = findobj(src.Parent.Parent,'tag','seeds');
Data = get(hTable,'Data');
n = size(Data,1);
sel = false(n,1);
net = cell(n,1);
seeds = zeros(n,3);
hold(fig.hAxes,'on');
rmthis = [];

for k=1:n
    try
        sel(k) = Data{k,1};
        net{k} = Data{k,4};
        seeds(k,:) = str2num(Data{k,3}); %#ok
    catch
        rmthis = [k rmthis];
    end
end
sel(rmthis) = [];
net(rmthis) = [];
seeds(rmthis,:) = [];

net(~sel) = [];
seeds(~sel,:) = [];
if any(cellfun(@isempty,net))
    errordlg('The column Network needs to be specified!');
    return
end
uniqueNet = unique(net);
color = parula(length(uniqueNet));

for k=1:size(seeds,1)
    ind = ismember(uniqueNet, net{k});
    [sx,sy,sz] = ellipsoid(seeds(k,1),seeds(k,2),seeds(k,3),2,2,2);
    surf(fig.hAxes,sx,sy,sz,'LineStyle','none','FaceColor',color(ind,:),'tag','SeedSurf','UserData',net{k});
end
set(findobj(fig.hFigure,'tag','sliderArea'),'UserData',seeds);
hold(fig.hAxes,'off');
sel = ~cellfun(@isempty,Data(:,2));
val = get(findobj(fig.hFigure,'tag','sliderArea'),'Value');
Data(cellfun(@isempty,Data(sel,5)),5) = {val};
set(hTable,'Data', Data);

hLegend = findobj(src.Parent.Parent,'tag','legend');
if isempty(hLegend)
    hLegend = axes(src.Parent.Parent,'position',[0.9074    0.4040    0.0269    0.4718],'tag','legend');
end
cla(hLegend);
n = length(uniqueNet);
for k=1:n
    rectangle(hLegend,'Position',[0 k 1 1],'FaceColor',color(k,:));
end
xlim('auto');
ylim('auto');
set(hLegend,'YTick',(1:n)+0.5,'YTickLabel',uniqueNet,'XTickLabel',[])
setArea;
end


function removeROI(src, evnt)
fig = src.Parent.Parent.UserData;
hTable = findobj(src.Parent.Parent,'tag','seeds');
Data = get(hTable,'Data');
sel = cell2mat(Data(:,1));
sel = find(sel & ~cellfun(@isempty,Data(:,2)));
Data(sel,:) = [];
for k=1:length(sel)
    Data(end+k,:) = {false, [],[],[],[]};
end
set(hTable,'Data',Data);
Indices = get(findobj(src.Parent.Parent, 'tag','seeds'),'UserData');
Indices(sel) = [];
set(findobj(src.Parent.Parent, 'tag','seeds'),'UserData', Indices);
hSurf = findall(fig.hAxes,'tag','SeedSurf');
if isempty(hSurf)
    return
end
delete(hSurf(sel));
skinColor = [1,.75,.65];
fig.hCortexL.FaceVertexCData = repmat(skinColor,size(fig.hCortexL.FaceVertexCData,1),1);
fig.hCortexR.FaceVertexCData = repmat(skinColor,size(fig.hCortexR.FaceVertexCData,1),1);
setSeeds(src, evnt);
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
hTable = findobj(fig.hFigure,'tag','seeds');
Data = get(hTable,'Data');
sel = cell2mat(Data(:,1));
sel = sel & ~cellfun(@isempty,Data(:,2));
Data(sel,5) = {val};
set(hTable,'Data',Data);
setArea();
end


function setArea()
fig = get(gcf,'UserData');
hTable = findobj(fig.hFigure,'tag','seeds');
Data = get(hTable,'Data');
sel = cell2mat(Data(:,1));
sel = find(sel & ~cellfun(@isempty,Data(:,2)));
A = cell2mat(Data(:,5));
set(hTable,'Data',Data);

hSlider = findobj(fig.hFigure,'tag','sliderArea');
seeds = hSlider.UserData;
if isempty(seeds)
    return;
elseif length(seeds) ~= max(sel)
    setSeeds(gco);
    seeds = hSlider.UserData;
end

hm = fig.hmObj;
midline = seeds(:,1)==0;
[~,~,midlineIndicesL] = geometricTools.nearestNeighbor(seeds(midline,:),hm.fvLeft.vertices);
[~,~,midlineIndicesR] = geometricTools.nearestNeighbor(seeds(midline,:),hm.fvRight.vertices);
[~,~,seedIndices] = geometricTools.nearestNeighbor(seeds(~midline,:),hm.cortex.vertices);
A = [A(midline)/2; A(midline)/2; A(~midline)];

seedIndices = [hm.leftH(midlineIndicesL);hm.rightH(midlineIndicesR);seedIndices];
n = length(seedIndices);
roiIndices = cell(n,1);
for k=1:n
    roiIndices{k} = seedIndices(k);
end
a = zeros(n,1);

for k=1:n
    while a(k)/100 < A(k)
        IND = [];
        for i=1:length(roiIndices{k})
            ind_i = find(any(hm.cortex.faces == roiIndices{k}(i),2));
            IND = [IND;ind_i];
        end
        roiIndices{k} = [roiIndices{k};  unique(hm.cortex.faces(IND,:))];
        a(k) = geometricTools.getSurfaceArea(hm.cortex.vertices,hm.cortex.faces(roiIndices{k},:));
    end
end

Indices = cell(size(seeds,1),1);
if any(midline)
    ind = [1:sum(midline)*2];
    ind = reshape(ind,sum(midline),[])';
    for k=1:size(ind,2)
        Indices{k} = cell2mat(roiIndices(ind(:,k)));
    end
    Indices(k+1:end) = roiIndices(setdiff(1:n,ind));
else
    Indices =  roiIndices;
end
n = length(Indices);
indNoGM = find(hm.atlas.colorTable==0);
for k=1:n
    [~,loc1] = intersect(Indices{k},indNoGM);
    Indices{k}(loc1) = [];
end
IndicesNew = get(findobj(fig.hFigure, 'tag','seeds'),'UserData');
if isempty(IndicesNew), IndicesNew = Indices;end
IndicesNew(sel) = Indices(sel);
drawAreas(fig, IndicesNew);
set(findobj(fig.hFigure, 'tag','seeds'),'UserData',IndicesNew);
end


function drawAreas(fig, Indices)
skinColor = [1,.75,.65];
hm = fig.hmObj;
color = repmat(skinColor,size(hm.cortex.vertices,1),1);
fig.hCortexL.FaceVertexCData = color(hm.leftH,:);
fig.hCortexR.FaceVertexCData = color(hm.rightH,:);
hSurf = flipud(findall(fig.hFigure,'tag','SeedSurf'));
for k=1:length(Indices)
    color(Indices{k},:) = ones(length(Indices{k}),1)*hSurf(k).FaceColor;
end
fig.hCortexL.FaceVertexCData = color(hm.leftH,:);
fig.hCortexR.FaceVertexCData = color(hm.rightH,:);
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