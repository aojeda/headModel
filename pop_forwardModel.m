function EEG = pop_forwardModel(EEG)
if isempty(EEG.chanlocs)
    error('Empty EEG.chanlocs, you must load your electrode positions first.');
end
% Select template
resources = fullfile(fileparts(which('headModel.m')),'resources');
[FileName,PathName,FilterIndex] = uigetfile({'*.mat'},'Select template',resources);
if ~FilterIndex, return;end

% Launch Corregister
hm = headModel.loadFromFile(fullfile(PathName,FileName));
labels = {EEG.chanlocs.labels};
elec = [[EEG.chanlocs.X]' [EEG.chanlocs.Y]' [EEG.chanlocs.Z]'];
hm.coregister(elec,labels);

% Save the forward model
[p,n] = fileparts(fullfile(EEG.filepath,EEG.filename));
hmfile = fullfile(p,[n 'hm.mat']);
hm.saveToFile(hmfile);
EEG.etc.src.hmfile = hmfile;
disp('The forward model was saved in EEG.etc.src')