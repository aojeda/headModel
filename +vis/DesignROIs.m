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
fig.hAxes.Position = [0.2865    0.2147    0.9199    0.7730];
pn = uipanel(fig.hFigure, 'BorderType','none', 'Position',[0.0197    0.0577    0.4784    0.9358]);
 
uicontrol(pn,'Style','tex','String','Face alpha','units','normalized','Position',[0.08    0.0858    0.3724    0.0379]);
uicontrol(pn,'Style','tex','String','ROI area','units','normalized','Position',[0.08    0.1975    0.3855    0.0504]);

sl1 = uicontrol(pn,'Style', 'slider','Min',0,'Max',1,'Value',1,'Units','normalized',...
    'Position',[0.0163    0.0330    0.5    0.0401],'Value',1,'Callback',@setCortexAlpha,'TooltipString','Face alpha');
sl2 = uicontrol(pn,'Style', 'slider','Min',0,'Max',50,'Value',0,'Units','normalized',...
    'Position',[0.0163    0.1584    0.5    0.0401],'Value',0.5,'Callback',@updateSlider,...
    'TooltipString','ROI area','UserData',[],'tag','sliderArea');
addlistener(sl1,'ContinuousValueChange',@setCortexAlpha);
addlistener(sl2,'ContinuousValueChange',@updateSlider);

uicontrol(pn,'Style','edit','units','normalized','Position',[0.5176    0.1605    0.0802    0.0412],'tag','editArea','callback',@updateEdit);

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

bg = uibuttongroup(pn,'Title','Select atlas', 'SelectionChangedFcn',@selectAtlas,'Position',[0.6349    0.0277    0.3457    0.2179]);
uicontrol(bg,'Style','radiobutton','String','Destrieux (148 ROI)','TooltipString','Select atlas','Position',[7    55   150    20]);
uicontrol(bg,'Style','radiobutton','String','DK (68 ROI)','TooltipString','Select atlas','Position',[7    20   150    20]);
end

function selectAtlas(src, evnt)
hmViewer = src.Parent.Parent.UserData;
switch src.SelectedObject.String
    case 'Destrieux (148 ROI)'
        hmViewer.hmObj = headModel.loadFromFile(which('head_modelColin27_10003_Standard-10-5-Cap339-Destrieux148.mat'));
    case 'DK (68 ROI)'
        hmViewer.hmObj = headModel.loadFromFile(which('head_modelColin27_8003_Standard-10-5-Cap339.mat'));
end
hmObj = hmViewer.hmObj;
hmObj.transform2MNI();
if isempty(hmObj.leftH)
    [hmObj.fvLeft,hmObj.fvRight, hmObj.leftH, hmObj.rightH] = geometricTools.splitBrainHemispheres(hmObj.cortex);
end
set(hmViewer.hCortexL,'vertices',hmObj.fvLeft.vertices,'faces',hmObj.fvLeft.faces,'FaceVertexCData',repmat([1,.75,.65],size(hmObj.fvLeft.vertices,1),1))
set(hmViewer.hCortexR,'vertices',hmObj.fvRight.vertices,'faces',hmObj.fvRight.faces,'FaceVertexCData',repmat([1,.75,.65],size(hmObj.fvRight.vertices,1),1))
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
roi = {};
seed = [];
k = 1;
while k < length(txt) 
    loc(isempty(loc)) = length(txt);
    tmp = deblank(txt(k:loc(1)-1));
    if ~isempty(tmp)
        if isempty(str2num(tmp))
            roi{end+1,1} = tmp;
        else
            seed = [seed; str2num(deblank(txt(k:loc(1))))];
        end
    end
    k = loc(1)+1;
    loc(1) = [];
end
if isempty(seed)
    errordlg('To copy from clipboard, the format needs to be a table of ROI name and seed values.');
    return;
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
uniqueNet = unique(net, 'stable');
color = flipud(parula(length(uniqueNet)));

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
sel = false(size(Data,1),1);
for k=1:size(Data,1)
    if ~isempty(Data{k,1})
        sel(k) = Data{k,1};
    end
end
Data(sel,:) = [];
Data(end+1:end+sum(sel),:) = repmat({[false], [],[],[],[]},sum(sel),1);
set(hTable,'Data',Data);
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
setArea();
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
sel = false(size(Data,1),1);
for k=1:size(Data,1)
    if ~isempty(Data{k,1})
        sel(k) = Data{k,1};
    end
end
hm = fig.hmObj;
hmDefault = headModel.loadDefault;
ROIs = Data(sel,4);
seeds = Data(sel,3);
uniqueROIs = unique(ROIs,'stable');
network = repmat(struct('name','','ROI',[],'mask',[]),length(uniqueROIs),1);

for k=1:length(uniqueROIs)
    nNeighbor = 5;
    net_k = find(ismember(ROIs,uniqueROIs{k}));
    network(k).name = uniqueROIs{k};
    for r=1:length(net_k)
        c_r = str2num(seeds{net_k(r),:});
        if c_r(1)==0
            [~,~,midlineIndL] = geometricTools.nearestNeighbor(c_r,hm.fvLeft.vertices,nNeighbor);
            [~,~,midlineIndR] = geometricTools.nearestNeighbor(c_r,hm.fvRight.vertices,nNeighbor);
            ind_c_r = [midlineIndL(:);midlineIndR(:)];
        else
            [~,~,ind_c_r] = geometricTools.nearestNeighbor(c_r,hm.cortex.vertices,nNeighbor);
        end
        colorTable_nz = nonzeros(hm.atlas.colorTable(ind_c_r));
        if isempty(colorTable_nz)
            if c_r(1)==0
                [~,~,midlineIndL] = geometricTools.nearestNeighbor(c_r,hm.fvLeft.vertices,20);
                [~,~,midlineIndR] = geometricTools.nearestNeighbor(c_r,hm.fvRight.vertices,20);
                ind_c_r = [midlineIndL(:);midlineIndR(:)];
            else
                [~,~,ind_c_r] = geometricTools.nearestNeighbor(c_r,hm.cortex.vertices,20);
            end
            colorTable_nz = nonzeros(hm.atlas.colorTable(ind_c_r));
        end
        
        [counts, centers] = hist(colorTable_nz,length(ind_c_r));
        [~,ind] = max(counts);
        [~,ind] = min(colorTable_nz - centers(ind));
        % ind = find(hm.atlas.colorTable(ind_c_r));
        network(k).ROI{r} = hm.atlas.label{colorTable_nz(ind(1))};
    end
    network(k).mask = any(hm.indices4Structure(network(k).ROI),2);
end
fig.hAxes.UserData = network;
drawAreas(fig, network);
end


function drawAreas(fig, network)
skinColor = [1,.75,.65];
hm = fig.hmObj;
color = repmat(skinColor,size(hm.cortex.vertices,1),1);
fig.hCortexL.FaceVertexCData = color(hm.leftH,:);
fig.hCortexR.FaceVertexCData = color(hm.rightH,:);
c = flipud(parula(length(network)));
for k=1:length(network)
    ind = find(any(hm.indices4Structure(network(k).ROI),2));
    color(ind,:) = ones(length(ind),1)*c(k,:);
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