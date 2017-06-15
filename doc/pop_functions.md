## Command-line interfaces for EEGLAB
Below we describe the two pop functions that can work with EEGLAB's `EEG` structure.

#### `pop_forwardModel`
Use this function to: 
1. Coregister the sensor positions in the `EEG` structure with a template.
2. Compute the lead field matrix.

```matlab
EEG = pop_forwardModel(EEG, hmfile, conductivity, orientation);
```
Input arguments:

* `EEG`: EEGLAB's structure with nonempty `EEG.chanlocs` structure.
* `hmfile`: file path to the template head model on disk.
* `conductivity`: conductivity of each layer of tissue, scalp, skull, brain. The default value is: `[0.33, 0.022, 0.33]` in S/m units, which is based on [this](http://www.sciencedirect.com/science/article/pii/S016502700900497X) paper.
* `orientation`: if true, computes the orientation free lead field, otherwise it constrain the dipoles to be normal to the cortical surface.

Output:
`EEG`: EEGLAB's structure where `EEG.etc.src.hmfile` points to the saved head model file (usually located next to the *.set* file) containing the computed forward model.

This function may or maynot pop up a GUI depending on whether the coregistration process is needed. Learn more about coregistration [here]((https://github.com/aojeda/headModel/blob/master/doc/coregistration.md)).

#### `pop_inverseSolution`
Use this function for performing the distributed source estimation of non-overlaping and consecutive segments of EEG data, trial by trial using the LORETA inverse method. See more abot LORETA in its official documentation page [here](http://www.uzh.ch/keyinst/loreta.htm) and also check out our page [here](https://github.com/aojeda/headModel/blob/master/doc/loreta.md).

```matlab
EEG = pop_inverseSolution(EEG, windowSize, saveFull);
```

Input arguments:

* `EEG`: EEGLAB's structure with a valid `EEG.etc.src.hmfile` field, otherwise we call `pop_forwardModel` to compute the forward model,
* `windowSize`: number of consecutive samples used to estimate a chunk of source time series. Every `windowSize` samples, we update LORETA's regularization parameter `lambda`. Choosing wisely this parameter can be critical as the estimation of `lambda` may be unstable for data chunks of a few samples, while if it is too large it may deprive the method of adaptation to fluctuations in signal to noise ratio, which can occur due to for instance, subject's sweating, EM artifacts, as well changes in EEG amplitude induced by a physiological state. The default is 64.
* `saveFull`: if true, saves the full inverse solution tensor, otherwise it only saves the tensor collapsed within ROIs (regions of interest). Th edefault is true.

Output arguments:

* `EEG.etc.src.actFull`: a tensor of number of sources by `EEG.pnts` by `EEG.trials` that contains the source time series,
* `EEG.etc.src.act`: same as `EEG.etc.src.actFull` but the first dimension is colapsed within ROIs that correspond to the atlas in the head model, resulting in a tensor of number of ROI by `EEG.pnts` by `EEG.trials`,
* `EEG.etc.src.roi`: cell array of ROI labels. 

[Back](https://github.com/aojeda/headModel/blob/master/doc/Documentation.md)