%% Brainstorm2headModel
%
% This script demonstrates how a headModel object can be constructed using
% curated MRI templates shiped with the BrainStorm toolbox. Before you run
% this script, you should agree to BrainStorm license and download it.

% Download a template anatomy from: http://neuroimage.usc.edu/bst/download.php
% and decompress it. For this example, we assume that the decompressed folder 
% is located in $home/Colin27_2016, where $home points to the used's home directory.

%%
clear

% Find user's home directory
import java.lang.*;
home = char(System.getProperty('user.home'));

% Set filenames
filename_skin = fullfile(home,'Colin27_2016','tess_head.mat');
filename_outskull = fullfile(home,'Colin27_2016','tess_outerskull.mat');
filename_inskull = fullfile(home,'Colin27_2016','tess_innerskull.mat');
filename_cortex = fullfile(home,'Colin27_2016','tess_cortex_pial_low.mat');
filename_montage = fullfile(fileparts(which('brainstorm')),'defaults','eeg','Colin27/channel_10-10_65.mat');

load(filename_skin,'Vertices','Faces'); 
scalp = struct('vertices',Vertices,'faces',Faces);
load(filename_outskull,'Vertices','Faces');
outskull = struct('vertices',Vertices,'faces',Faces);
load(filename_inskull,'Vertices','Faces');
inskull = struct('vertices',Vertices,'faces',Faces);
load(filename_cortex,'Vertices','Faces','Atlas');
cortex = struct('vertices',Vertices,'faces',Faces);
montage = load(filename_montage);

% Find D&K atlas
ind = find(strcmp({Atlas.Name},'Desikan-Killiany'));

% Build the atlas structure
atlas = struct('colorTable',zeros(size(cortex.vertices,1),1),'label',[]);
atlas.label = {Atlas(ind).Scouts.Label};
for roi=1:length(atlas.label)
    atlas.colorTable(Atlas(ind).Scouts(roi).Vertices) = roi;
end

%% Build the head model
% Add the headModel toolbox to the path
addpath(genpath('headModel'))
hm = headModel('channelSpace',[montage.Channel.Loc]','label',{montage.Channel.Name},...
    'scalp',scalp,'outskull',outskull,'inskull',inskull,'cortex',cortex,'atlas',atlas);
hm.plot;
hm.computeLeadFieldBEM();