# Getting started tutorial
In this tutorial, we show a typical command-line pipeline for estimating EEG sources with the `headModel` toolbox. We assume that pre-processing such as artifacts cleaning, highpass filtering, etc. have been performed at an earlier stage (see pre-processing
guidelines [here](https://github.com/aojeda/headModel/blob/master/doc/pop_functions.md#pre-processing)).

Suppose that we have an `EEG` structure in the workspace, which has channel labels compatible
with the 10-20 system. The first thing that we need is to compute the lead field matrix for our
montage and head model template. We accomplish this as follows:

```matlab
eeglabFolder = '/path/to/eeglab'; % path to eeglab folder

% Choose a template from those in 'headModel/resources'
template = fullfile(eeglabFolder,'plugins','headModel','resources',...
'head_modelColin27_5003_Standard-10-5-Cap339.mat');

conductivity = [0.33 0.022 0.33]; % set scalp, skull, and brain conductivities
orientation = false;              % whether to calculate the orientation free
                                  % lead field (true) or constraint the dipoles
                                  % to be normal to the cortical surface (false)

% Build a new head model and compute lead field matrix
EEG = pop_forwardModel(EEG, template, conductivity, orientation);
```

where the resulting `EEG` structure will have the file path to the head model created in
`EEG.etc.src.hmfile`. If our montage has labels that are not in the 10-20 system the
the co-register window will pop up, from which we can manually proceed (see
[here](https://github.com/aojeda/headModel/blob/master/doc/coregistration.md) for details).

We can load and plot the computed head model as follows:

```matlab
hm = headModel.loadFromFile(EEG.etc.src.hmfile);
fig = hm.plot();
```

See more about `pop_forwardModel` [here](https://github.com/aojeda/headModel/blob/master/doc/pop_functions.md#pop_forwardmodel).

Next, we proceed to estimate the EEG sources with [pop_inverseSolution](https://github.com/aojeda/headModel/blob/master/doc/pop_functions.md#pop_inversesolution):

```matlab
windowSize = 16;  % set the number of consecutive samples used to estimate a chunk
                  % of source time series
saveFull = true;  % whether to return the estimated time series of each cortical
                  % dipole (true) or just the ROI reduced time series (false)
solverType = 'loreta';  % set the inverse solution method

% Estimate sources
EEG = pop_inverseSolution(EEG, windowSize, saveFull, solverType)
```
where the resulting `EEG` structure will have the sources stored in the `EEG.etc.src`
structure.

See the  [visualization](https://github.com/aojeda/headModel/blob/master/doc/visualization.md) page to learn how to plot your results.

That's all folks, enjoy!

[Back](https://github.com/aojeda/headModel/blob/master/doc/Documentation.md)
