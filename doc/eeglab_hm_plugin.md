## GUI interface for EEGLAB
Before you use the toolbox, please check out the pre-processing guidelines [here](https://github.com/aojeda/headModel/blob/master/doc/pop_functions.md#pre-processing).

We can use the `headModel` toolbox as a plug-in for [EEGLAB](https://sccn.ucsd.edu/eeglab/) by cloning or downloading this repository to the `eeglab/plugins/` folder in your local machine. Once EEGLAB's GUI pops up, we can access the `headModel` menu item in the tools menu as shown in the figure below

![eeglab_hm_plugin](https://github.com/aojeda/headModel/blob/master/doc/assets/eeglab_hm_plugin.png)

### Surface-based (BEM) forward modeling
This option allows us to perform a semi-automatic co-registration between our channel positions and a selected head model template. After we are done with the co-registration we can proceed to compute the lead field model for our montage and selected head model using the Boundary Element Method as implemented by the [OpenMEEG](https://openmeeg.github.io/) toolbox. The resulting forward model is stored in a `headModel` object, usually saved next to the *.set* file, a pointer to it is saved in `EEG.etc.src.hmfile`.

Learn more in the page for [Coregistration](https://github.com/aojeda/headModel/blob/master/doc/coregistration.md).
See the documentation for `pop_forwardModel` [here](https://github.com/aojeda/headModel/blob/master/doc/pop_functions.md#pop_forwardmodel).

### Inverse source estimation
This option calls the `pop_inverseSolution` function for performing source reconstruction using LORETA (see LORETA's official documentation [here](http://www.uzh.ch/keyinst/loreta.htm)). Other methods may be added latter as plugins.

In contrast to traditional ERP-based source localization approaches, where multiple trials time-locked to an event of interest are used to estimate a source statistical parametric map (SPM) at a relevant ERP latency, our method is more oriented towards continuous (single trial) source estimation. Source SPMs can always be computed post hoc from ensembles of source data using standard `EEGLAB` tools. Source estimation is performed on non-overlapping and consecutive segments of data, trial by trial, resulting on a tensor of number of sources (vertices in the cortical surface of the head model) by time points by trials. This approach was validated, in the context of a BCI application, in [this](https://www.ncbi.nlm.nih.gov/pubmed/26415149) paper. The results are stored in the `EEG.etc.src`, which contains the following fields:

* `actFull`: a tensor of number of sources by `EEG.pnts` by `EEG.trials` that contains the source time series,
* `act`: same as `actFull` but the first dimension is collapsed within ROIs (regions of interest) that correspond to the atlas in the head model, resulting in a tensor of number of ROI by `EEG.pnts` by `EEG.trials` that contains the source time series per ROI,
* `roi`: cell array of ROI labels.

See the documentation for `pop_inverseSolution` [here](https://github.com/aojeda/headModel/blob/master/doc/pop_functions.md#pop_inversesolution).

### Move ROI source estimates to EEG.data
Where do we go after computing source estimates? This option calls the helper function `moveSource2DataField` to create a new `EEG` structure where the `EEG.data` field holds the ROI source data computed by `pop_inverseSolution` and `EEG.chanlocs` is populated with ROI labels and centroid locations. The resulting `EEG` structure is added to `ALLEEG` and shown in the main GUI. This *hack* is particularly handy because it allows us to use `EEGLAB` functions for signal processing, statistical analysis, and visualization of source estimates.

See more documentation about `moveSource2DataField`  [here](https://github.com/aojeda/headModel/blob/master/doc/pop_functions.md#movesource2datafield-hack-eeglab-to-work-with-source-data-as-it-was-eeg).


[Back](https://github.com/aojeda/headModel/blob/master/doc/Documentation.md)
