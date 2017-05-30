function EEG = pop_forwardModel(EEG, hmfile)
if isempty(EEG.chanlocs)
    error('Empty EEG.chanlocs, you must load your electrode positions first.');
end

% Select template if not provided
resources = fullfile(fileparts(which('headModel.m')),'resources');
if nargin < 2
    [FileName,PathName,FilterIndex] = uigetfile({'*.mat'},'Select template',resources);
    if ~FilterIndex, return;end
    hmfile = fullfile(PathName,FileName);
elseif ~exist(hmfile,'file')
    [FileName,PathName,FilterIndex] = uigetfile({'*.mat'},'Select template',resources);
    if ~FilterIndex, return;end
    hmfile = fullfile(PathName,FileName);
end

% Launch Corregister
hm = headModel.loadFromFile(hmfile);
labels = {EEG.chanlocs.labels};
elec = [[EEG.chanlocs.X]' [EEG.chanlocs.Y]' [EEG.chanlocs.Z]'];
hm.coregister(elec,labels);

% Save the forward model
if ~isempty(hm.channelSpace)
    [p,n] = fileparts(fullfile(EEG.filepath,EEG.filename));
    hmfile = fullfile(p,[n '_hm.mat']);
    hm.saveToFile(hmfile);
    EEG.etc.src.hmfile = hmfile;
    disp('The forward model was saved in EEG.etc.src')
end