function varargout = Coregister(varargin)
% COREGISTER MATLAB code for Coregister.fig
%      COREGISTER, by itself, creates a new COREGISTER or raises the existing
%      singleton*.
%
%      H = COREGISTER returns the handle to a new COREGISTER or the handle to
%      the existing singleton*.
%
%      COREGISTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COREGISTER.M with the given input arguments.
%
%      COREGISTER('Property','Value',...) creates a new COREGISTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Coregister_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Coregister_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Coregister

% Last Modified by GUIDE v2.5 22-Jun-2017 00:46:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Coregister_OpeningFcn, ...
                   'gui_OutputFcn',  @Coregister_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Coregister is made visible.
function Coregister_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Coregister (see VARARGIN)

if length(varargin) < 3, varargin{3} = [];end
handles.hm = varargin{1};
handles.xyz = varargin{2};
handles.labels = varargin{3};
cla(handles.axes1);
skinColor = [1,.75,.65];
patch('vertices',handles.hm.scalp.vertices,'faces',handles.hm.scalp.faces,'facecolor',skinColor,...
                'facelighting','phong','LineStyle','none','FaceAlpha',1,'Parent',handles.axes1);
view(handles.axes1,[90 0]);
hold(handles.axes1,'on');
handles.sensors = scatter3(handles.xyz(:,1),handles.xyz(:,2),handles.xyz(:,3),'filled','MarkerEdgeColor','k','MarkerFaceColor','y','Parent',handles.axes1);
n = length(handles.labels);
handles.hLabels = [];
for it=1:n, handles.hLabels(it) = text('Position',handles.xyz(it,:),'String',handles.labels{it},'Parent',handles.axes1);end

mx = max(handles.hm.channelSpace);
k = 1.2;
line([0 k*mx(1)],[0 0],[0 0],'LineStyle','-.','Color','b','LineWidth',2)
line([0 0],[0 k*mx(2)],[0 0],'LineStyle','-.','Color','g','LineWidth',2)
line([0 0],[0 0],[0 k*mx(3)],'LineStyle','-.','Color','r','LineWidth',2)
text('Position',[k*mx(1) 0 0],'String','X','FontSize',12,'FontWeight','bold','Color','b')
text('Position',[0 k*mx(2) 0],'String','Y','FontSize',12,'FontWeight','bold','Color','g')
text('Position',[0 0 k*mx(3)],'String','Z','FontSize',12,'FontWeight','bold','Color','r')

hold(handles.axes1,'off');
axis(handles.axes1,'equal','vis3d','on');
camlight(0,180)
camlight(0,0)
rotate3d

% Choose default command line output for Coregister
handles.output = handles.coregister;

% Update handles structure
guidata(hObject, handles);
uiwait(handles.coregister);
% UIWAIT makes Coregister wait for user response (see UIRESUME)
% uiwait(handles.coregister);


% --- Outputs from this function are returned to the command line.
function varargout = Coregister_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if ~isempty(handles)
    varargout{1} = handles.output;
else
    varargout{1} = [];
    return;
end
try
    set(findjobj(handles.t_minus_x),'MouseWheelMovedCallback',{@t_minus_x_Callback,handles})
    set(findjobj(handles.t_minus_y),'MouseWheelMovedCallback',{@t_minus_y_Callback,handles})
    set(findjobj(handles.t_minus_z),'MouseWheelMovedCallback',{@t_minus_z_Callback,handles})
    set(findjobj(handles.t_plus_x),'MouseWheelMovedCallback',{@t_plus_x_Callback,handles})
    set(findjobj(handles.t_plus_y),'MouseWheelMovedCallback',{@t_plus_y_Callback,handles})
    set(findjobj(handles.t_plus_z),'MouseWheelMovedCallback',{@t_plus_z_Callback,handles})
    set(findjobj(handles.s_minus_x),'MouseWheelMovedCallback',{@s_minus_x_Callback,handles})
    set(findjobj(handles.s_minus_y),'MouseWheelMovedCallback',{@s_minus_y_Callback,handles})
    set(findjobj(handles.s_minus_z),'MouseWheelMovedCallback',{@s_minus_z_Callback,handles})
    set(findjobj(handles.s_plus_x),'MouseWheelMovedCallback',{@s_plus_x_Callback,handles})
    set(findjobj(handles.s_plus_y),'MouseWheelMovedCallback',{@s_plus_y_Callback,handles})
    set(findjobj(handles.s_plus_z),'MouseWheelMovedCallback',{@s_plus_z_Callback,handles})
    set(findjobj(handles.r_minus_x),'MouseWheelMovedCallback',{@r_minus_x_Callback,handles})
    set(findjobj(handles.r_minus_y),'MouseWheelMovedCallback',{@r_minus_y_Callback,handles})
    set(findjobj(handles.r_minus_z),'MouseWheelMovedCallback',{@r_minus_z_Callback,handles})
    set(findjobj(handles.r_plus_x),'MouseWheelMovedCallback',{@r_plus_x_Callback,handles})
    set(findjobj(handles.r_plus_y),'MouseWheelMovedCallback',{@r_plus_y_Callback,handles})
    set(findjobj(handles.r_plus_z),'MouseWheelMovedCallback',{@r_plus_z_Callback,handles})
end


% --- Executes on button press in Project.
function Project_Callback(hObject, eventdata, handles)
% hObject    handle to Project (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
x = get(handles.sensors,'xdata');
y = get(handles.sensors,'ydata');
z = get(handles.sensors,'zdata');
xyz = geometricTools.kNearestNeighbor([x(:) y(:) z(:)],handles.hm.scalp.vertices);
xyz = mean(xyz,3);
[azimuth,elevation] = cart2sph(x,y,z);
[~,~,r] = cart2sph(xyz(:,1),xyz(:,2),xyz(:,3));
[x,y,z] = sph2cart(azimuth(:),elevation(:),1.01*r(:));
set(handles.sensors,'xdata',x);
set(handles.sensors,'ydata',y);
set(handles.sensors,'zdata',z);
for it=1:length(handles.hLabels)
    set(handles.hLabels(it),'Position',1.1*[x(it) y(it) z(it)]);
end

function R = rotx(a)
R = zeros(3);
R(1,1) = 1;
R(2,2) = cos(a);
R(3,3) = cos(a);
R(2,3) = -sin(a);
R(3,2) = sin(a);

function R = roty(a)
R = zeros(3);
R(1,1) = cos(a);
R(1,3) = sin(a);
R(2,2) = 1;
R(3,1) = -sin(a);
R(3,3) = cos(a);


function R = rotz(a)
R = zeros(3);
R(1,1) = cos(a);
R(1,2) = -sin(a);
R(2,1) = sin(a);
R(2,2) = cos(a);
R(3,3) = 1;


% --- Executes on button press in t_plus_x.
function t_plus_x_Callback(hObject, eventdata, handles)
% hObject    handle to plus_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
s = get(handles.sensors,'xdata');
s = s+norm([get(handles.sensors,'xdata')' get(handles.sensors,'ydata')' get(handles.sensors,'zdata')'])/400;
set(handles.sensors,'xdata',s);
for it=1:length(handles.hLabels), 
    pos = get(handles.hLabels(it),'Position');
    pos(1) = s(it);
    set(handles.hLabels(it),'Position',pos);
end


% --- Executes on button press in t_plus_y.
function t_plus_y_Callback(hObject, eventdata, handles)
s = get(handles.sensors,'ydata');
s = s+norm([get(handles.sensors,'xdata')' get(handles.sensors,'ydata')' get(handles.sensors,'zdata')'])/400;
set(handles.sensors,'ydata',s);
for it=1:length(handles.hLabels), 
    pos = get(handles.hLabels(it),'Position');
    pos(2) = s(it);
    set(handles.hLabels(it),'Position',pos);
end

% --- Executes on button press in t_plus_z.
function t_plus_z_Callback(hObject, eventdata, handles)
% hObject    handle to t_plus_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
s = get(handles.sensors,'zdata');
s = s+norm([get(handles.sensors,'xdata')' get(handles.sensors,'ydata')' get(handles.sensors,'zdata')'])/400;
set(handles.sensors,'zdata',s);
for it=1:length(handles.hLabels), 
    pos = get(handles.hLabels(it),'Position');
    pos(3) = s(it);
    set(handles.hLabels(it),'Position',pos);
end

% --- Executes on button press in t_minus_x.
function t_minus_x_Callback(hObject, eventdata, handles)
% hObject    handle to t_minus_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
s = get(handles.sensors,'xdata');
s = s-norm([get(handles.sensors,'xdata')' get(handles.sensors,'ydata')' get(handles.sensors,'zdata')'])/400;
set(handles.sensors,'xdata',s);
for it=1:length(handles.hLabels), 
    pos = get(handles.hLabels(it),'Position');
    pos(1) = s(it);
    set(handles.hLabels(it),'Position',pos);
end

% --- Executes on button press in t_minus_y.
function t_minus_y_Callback(hObject, eventdata, handles)
% hObject    handle to t_minus_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
s = get(handles.sensors,'ydata');
s = s-norm([get(handles.sensors,'xdata')' get(handles.sensors,'ydata')' get(handles.sensors,'zdata')'])/400;
set(handles.sensors,'ydata',s);
for it=1:length(handles.hLabels), 
    pos = get(handles.hLabels(it),'Position');
    pos(2) = s(it);
    set(handles.hLabels(it),'Position',pos);
end

% --- Executes on button press in t_minus_z.
function t_minus_z_Callback(hObject, eventdata, handles)
% hObject    handle to t_minus_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
s = get(handles.sensors,'zdata');
s = s-norm([get(handles.sensors,'xdata')' get(handles.sensors,'ydata')' get(handles.sensors,'zdata')'])/400;
set(handles.sensors,'zdata',s);
for it=1:length(handles.hLabels), 
    pos = get(handles.hLabels(it),'Position');
    pos(3) = s(it);
    set(handles.hLabels(it),'Position',pos);
end

% --- Executes on button press in r_plus_x.
function r_plus_x_Callback(hObject, eventdata, handles)
% hObject    handle to r_plus_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
x = get(handles.sensors,'xdata');
y = get(handles.sensors,'ydata');
z = get(handles.sensors,'zdata');
R = rotx(pi/180);
xyz = [x(:) y(:) z(:)]*R';
set(handles.sensors,'xdata',xyz(:,1));
set(handles.sensors,'ydata',xyz(:,2));
set(handles.sensors,'zdata',xyz(:,3));
for it=1:length(handles.hLabels),
    set(handles.hLabels(it),'Position',xyz(it,:));
end


% --- Executes on button press in r_plus_y.
function r_plus_y_Callback(hObject, eventdata, handles)
% hObject    handle to r_plus_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
x = get(handles.sensors,'xdata');
y = get(handles.sensors,'ydata');
z = get(handles.sensors,'zdata');
R = roty(pi/180);
xyz = [x(:) y(:) z(:)]*R';
set(handles.sensors,'xdata',xyz(:,1));
set(handles.sensors,'ydata',xyz(:,2));
set(handles.sensors,'zdata',xyz(:,3));
for it=1:length(handles.hLabels),
    set(handles.hLabels(it),'Position',xyz(it,:));
end


% --- Executes on button press in r_plus_z.
function r_plus_z_Callback(hObject, eventdata, handles)
% hObject    handle to r_plus_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
x = get(handles.sensors,'xdata');
y = get(handles.sensors,'ydata');
z = get(handles.sensors,'zdata');
R = rotz(pi/180);
xyz = [x(:) y(:) z(:)]*R';
set(handles.sensors,'xdata',xyz(:,1));
set(handles.sensors,'ydata',xyz(:,2));
set(handles.sensors,'zdata',xyz(:,3));
for it=1:length(handles.hLabels),
    set(handles.hLabels(it),'Position',xyz(it,:));
end


% --- Executes on button press in r_minus_x.
function r_minus_x_Callback(hObject, eventdata, handles)
% hObject    handle to r_minus_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
x = get(handles.sensors,'xdata');
y = get(handles.sensors,'ydata');
z = get(handles.sensors,'zdata');
R = rotx(-pi/180);
xyz = [x(:) y(:) z(:)]*R';
set(handles.sensors,'xdata',xyz(:,1));
set(handles.sensors,'ydata',xyz(:,2));
set(handles.sensors,'zdata',xyz(:,3));
for it=1:length(handles.hLabels),
    set(handles.hLabels(it),'Position',xyz(it,:));
end

% --- Executes on button press in r_minus_y.
function r_minus_y_Callback(hObject, eventdata, handles)
% hObject    handle to r_minus_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
x = get(handles.sensors,'xdata');
y = get(handles.sensors,'ydata');
z = get(handles.sensors,'zdata');
R = roty(-pi/180);
xyz = [x(:) y(:) z(:)]*R';
set(handles.sensors,'xdata',xyz(:,1));
set(handles.sensors,'ydata',xyz(:,2));
set(handles.sensors,'zdata',xyz(:,3));
for it=1:length(handles.hLabels), 
    set(handles.hLabels(it),'Position',xyz(it,:));
end


% --- Executes on button press in r_minus_z.
function r_minus_z_Callback(hObject, eventdata, handles)
% hObject    handle to r_minus_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
x = get(handles.sensors,'xdata');
y = get(handles.sensors,'ydata');
z = get(handles.sensors,'zdata');
R = rotz(-pi/180);
xyz = [x(:) y(:) z(:)]*R';
set(handles.sensors,'xdata',xyz(:,1));
set(handles.sensors,'ydata',xyz(:,2));
set(handles.sensors,'zdata',xyz(:,3));
for it=1:length(handles.hLabels),
    set(handles.hLabels(it),'Position',xyz(it,:));
end


% --- Executes on button press in s_plus_x.
function s_plus_x_Callback(hObject, eventdata, handles)
% hObject    handle to s_plus_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
s = get(handles.sensors,'xdata')*1.01;
set(handles.sensors,'xdata',s);
for it=1:length(handles.hLabels), 
    pos = get(handles.hLabels(it),'Position');
    pos(1) = s(it);
    set(handles.hLabels(it),'Position',pos);
end

% --- Executes on button press in s_plus_y.
function s_plus_y_Callback(hObject, eventdata, handles)
% hObject    handle to s_plus_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
s = get(handles.sensors,'ydata')*1.01;
set(handles.sensors,'ydata',s);
for it=1:length(handles.hLabels), 
    pos = get(handles.hLabels(it),'Position');
    pos(2) = s(it);
    set(handles.hLabels(it),'Position',pos);
end

% --- Executes on button press in s_plus_z.
function s_plus_z_Callback(hObject, eventdata, handles)
% hObject    handle to s_plus_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
s = get(handles.sensors,'zdata')*1.01;
set(handles.sensors,'zdata',s);
for it=1:length(handles.hLabels), 
    pos = get(handles.hLabels(it),'Position');
    pos(3) = s(it);
    set(handles.hLabels(it),'Position',pos);
end

% --- Executes on button press in s_minus_x.
function s_minus_x_Callback(hObject, eventdata, handles)
% hObject    handle to s_minus_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
s = get(handles.sensors,'xdata')/1.01;
set(handles.sensors,'xdata',s);
for it=1:length(handles.hLabels), 
    pos = get(handles.hLabels(it),'Position');
    pos(1) = s(it);
    set(handles.hLabels(it),'Position',pos);
end

% --- Executes on button press in s_minus_y.
function s_minus_y_Callback(hObject, eventdata, handles)
% hObject    handle to s_minus_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
s = get(handles.sensors,'ydata')/1.01;
set(handles.sensors,'ydata',s);
for it=1:length(handles.hLabels), 
    pos = get(handles.hLabels(it),'Position');
    pos(2) = s(it);
    set(handles.hLabels(it),'Position',pos);
end

% --- Executes on button press in s_minus_z.
function s_minus_z_Callback(hObject, eventdata, handles)
% hObject    handle to s_minus_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
s = get(handles.sensors,'zdata')/1.01;
set(handles.sensors,'zdata',s);
for it=1:length(handles.hLabels), 
    pos = get(handles.hLabels(it),'Position');
    pos(3) = s(it);
    set(handles.hLabels(it),'Position',pos);
end

% --- Executes on button press in restart.
function restart_Callback(hObject, eventdata, handles)
% hObject    handle to restart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.sensors,'xdata',handles.xyz(:,1));
set(handles.sensors,'ydata',handles.xyz(:,2));
set(handles.sensors,'zdata',handles.xyz(:,3));
for it=1:length(handles.hLabels), 
    set(handles.hLabels(it),'Position',handles.xyz(it,:));
end

% --- Executes when user attempts to close coregister.
function coregister_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to coregister (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
xyz = [handles.sensors.XData(:) handles.sensors.YData(:) handles.sensors.ZData(:)];
if isempty(handles.labels)
    xyz1 = get(handles.sensors,'userData');
    if isempty(xyz1) || any(xyz(:)~=xyz1(:))
        save_Callback(hObject, eventdata, handles);
    end
else
    handles.hm.channelSpace = xyz;
    handles.hm.labels = handles.labels;
    handles.hm.K = [];
end
delete(hObject);



% --- Executes on button press in bem.
function save_Callback(hObject, eventdata, handles)
% hObject    handle to bem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
xyz = [handles.sensors.XData(:) handles.sensors.YData(:) handles.sensors.ZData(:)];
if isempty(handles.labels)
    answer = inputdlg('Variable name','Save',1,{'xyz'});
    if ~isempty(answer)
        set(handles.sensors,'userData',xyz);
        assignin('base', answer{1}, xyz);
    end
else
    handles.hm.channelSpace = xyz;
    handles.hm.labels = handles.labels;
    handles.hm.K = [];
end


% --- Executes on button press in autoscale.
function autoscale_Callback(hObject, eventdata, handles)
% hObject    handle to autoscale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
xyz = [handles.sensors.XData(:) handles.sensors.YData(:) handles.sensors.ZData(:)];
xyz = xyz/norm(xyz)*norm(handles.hm.channelSpace);
set(handles.sensors,'xdata',xyz(:,1));
set(handles.sensors,'ydata',xyz(:,2));
set(handles.sensors,'zdata',xyz(:,3));
for it=1:length(handles.hLabels), set(handles.hLabels(it),'Position',1.1*xyz(it,:));end

% --- Executes on button press in center.
function center_Callback(hObject, eventdata, handles)
% hObject    handle to center (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
xyz = [handles.sensors.XData(:) handles.sensors.YData(:) handles.sensors.ZData(:)];
xyz = bsxfun(@minus,xyz,mean((xyz)));
xyz = bsxfun(@plus,xyz,mean((handles.hm.channelSpace)));
set(handles.sensors,'xdata',xyz(:,1));
set(handles.sensors,'ydata',xyz(:,2));
set(handles.sensors,'zdata',xyz(:,3));
for it=1:length(handles.hLabels), set(handles.hLabels(it),'Position',1.1*xyz(it,:));end


% --- Executes on button press in bem.
function bem_Callback(hObject, eventdata, handles)
handles.hm.channelSpace = [handles.sensors.XData(:) handles.sensors.YData(:) handles.sensors.ZData(:)];
handles.hm.labels = handles.labels;
prompt = {'Skalp','Skull','Brain','Orientation'};
dlg_title = 'Conductivity';
num_lines = 1;
defaultans = {'0.33','0.022','0.33','off'};
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
if isempty(answer), return;end
cond = cellfun(@str2double,answer(1:3));
orientation = ~strcmpi(answer{4},'off');
try
    set(handles.coregister, 'pointer', 'watch');
    drawnow;
    handles.hm.computeLeadFieldBEM(cond,orientation);
    set(handles.coregister, 'pointer', 'arrow');
    drawnow;
    delete(handles.coregister);
catch ME
    handles.hm.labels = ME;
    set(handles.coregister, 'pointer', 'arrow');
    drawnow;
    delete(handles.coregister);
end

% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hm.removeSensor(handles.hm.labels);
delete(handles.coregister);


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1
if get(hObject,'Value')
    for it=1:length(handles.hLabels), set(handles.hLabels(it),'Visible','on');end
else
    for it=1:length(handles.hLabels), set(handles.hLabels(it),'Visible','off');end
end


% --- Executes on button press in checkbox2.
function checkbox2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox2
if get(hObject,'Value')
    axis(handles.axes1,'on');
else
    axis(handles.axes1,'off');
end


% --- Executes on button press in help.
function help_Callback(hObject, eventdata, handles)
% hObject    handle to help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
web('https://github.com/aojeda/headModel/blob/master/doc/coregistration.md', '-browser')


% --- Executes on scroll wheel click while the figure is in focus.
function coregister_WindowScrollWheelFcn(hObject, eventdata, handles)
% hObject    handle to coregister (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	VerticalScrollCount: signed integer indicating direction and number of clicks
%	VerticalScrollAmount: number of lines scrolled for each click
% handles    structure with handles and user data (see GUIDATA)
