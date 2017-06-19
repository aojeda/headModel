## Command-line interface to EEGLAB
In this section, we describe the two pop functions that can work with EEGLAB's `EEG` structure. First, we say a word about pre-processing.

#### Pre-processing
As with any signal processing method, the pre-processing we do before computing the forward and inverse solutions is critical and can make the difference between estimating source maps with physiologic relevance or implausible ones. We do not set in stone THE pre-processing pipeline that you should use, as that may be application and data dependent, rather we give guidelines on what transformations your `EEG` structure should go through before using `pop_forwardModel` or `pop_inverseSolution`:

* Remove DC component from each channel, this can be accomplished by applying a low-pass filter, removing the mean, or detrending the data.
* Remove bad channels.
* Remove non-EEG channels such as EOG or EMG (on the face or neck) as these may have significantly higher amplitude than EEG channels and may bias LORETA towards solutions that explain eye or muscle activity rather than brain.
* Identifying eye blinks and other artifactual components with ICA and projecting those out of the EEG data usually works well before LORETA. 
* Remove the average reference i.e. `EEG = pop_reref( EEG, [])`. This should be one of your last pre-processing steps as, internally, `pop_inverseSolution` removes the average reference from the lead field matrix and we need the lead field and the data to be referenced in the same way for the forward model to be valid. 

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

This function may or may not pop up a GUI depending on whether the co-registration process is needed. Learn more about co-registration [here](https://github.com/aojeda/headModel/blob/master/doc/coregistration.md).

#### `pop_inverseSolution`
Use this function for performing the distributed source estimation of non-overlapping and consecutive segments of EEG data, trial by trial using the LORETA inverse method. We have validated this approach, in the context of BCI applications, in [this](https://www.ncbi.nlm.nih.gov/pubmed/26415149) paper. See more about LORETA in its official documentation page [here](http://www.uzh.ch/keyinst/loreta.htm).

```matlab
EEG = pop_inverseSolution(EEG, windowSize, saveFull);
```

Input arguments:

* `EEG`: EEGLAB's structure with a valid `EEG.etc.src.hmfile` field, otherwise we call `pop_forwardModel` to compute the forward model,
* `windowSize`: number of consecutive samples used to estimate a chunk of source time series. Every `windowSize` samples, we update LORETA's regularization parameter `lambda`. Choosing wisely this parameter can be critical as the estimation of `lambda` may be unstable for data chunks of a few samples, while if it is too large it may deprive the method of adaptation to fluctuations in signal to noise ratio, which can occur due to e.g., subject's sweating, EM artifacts, or changes in EEG amplitude induced by a physiological state. The default is 64.
* `saveFull`: if true, saves the full inverse solution tensor, otherwise it only saves the tensor collapsed within ROIs (regions of interest). The default is true.

Output arguments:

* `EEG.etc.src.actFull`: a tensor of number of sources by `EEG.pnts` by `EEG.trials` that contains the source time series,
* `EEG.etc.src.act`: same as `EEG.etc.src.actFull` but the first dimension is colapsed within ROIs that correspond to the atlas in the head model, resulting in a tensor of number of ROI by `EEG.pnts` by `EEG.trials`,
* `EEG.etc.src.roi`: cell array of ROI labels. 

See [these](https://github.com/aojeda/headModel/blob/master/doc/visualization.md) hacks for how to visualize the source estimates.

[Back](https://github.com/aojeda/headModel/blob/master/doc/Documentation.md)