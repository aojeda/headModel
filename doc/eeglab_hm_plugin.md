## GUI interface for EEGLAB
Before you use the toolbox, please check out the pre-processing guidelines [here](https://github.com/aojeda/headModel/blob/master/doc/pop_functions.md#pre-processing).

We can use the `headModel` toolbox as a plug-in for [EEGLAB](https://sccn.ucsd.edu/eeglab/) by cloning or downloading this repo to the `eeglab/plugins/` folder in your local machine. Once EEGLAB's GUI pops up, we can access the `headModel` menu item in the tools menu as shown in the figure below

![eeglab_hm_plugin](https://github.com/aojeda/headModel/blob/master/doc/assets/eeglab_hm_plugin.png)

### Surface-based (BEM) forward modeling
This option allows us to perform a semi-automatic coregistration between our channel positions and a selected head model template. After we are done with the co-registration we can proceed to compute the lead field model for our montage and selected head model using the Boundary Element Method as implemented by the [OpenMEEG](https://openmeeg.github.io/) toolbox. The resulting forward model is stored in a `headModel` object, usually saved next to the *.set* file, a pointer to it is saved in `EEG.etc.src.hmfile`.

Learn more in the page for [Coregistration](https://github.com/aojeda/headModel/blob/master/doc/coregistration.md).
See the documentation for `pop_forwardModel` [here](https://github.com/aojeda/headModel/blob/master/doc/pop_functions.md#pop_forwardmodel).

### Inverse source estimation (LORETA)
This option calls the `pop_inverseSolution` function for performing source reconstruction using LORETA (see LORETA's official documentation [here](http://www.uzh.ch/keyinst/loreta.htm)).

Source estimation is performed on non-overlaping and consecutive segments of data, trial by trial, resulting on a tensor of number of sources (vertices in the cortical surface of the head model) by time points by trials. This approach was validated, in the context of BCI applications, in [this](https://www.ncbi.nlm.nih.gov/pubmed/26415149) paper. The results are stored in the `EEG.etc.src`, which contains the following fields:

* `actFull`: a tensor of number of sources by `EEG.pnts` by `EEG.trials` that contains the source time series,
* `act`: same as `actFull` but the first dimension is collapsed within ROIs (regions of interest) that correspond to the atlas in the head model, resulting in a tensor of number of ROI by `EEG.pnts` by `EEG.trials` that contains the source time series per ROI,
* `roi`: cell array of ROI labels.

See the documentation for `pop_inverseSolution` [here](https://github.com/aojeda/headModel/blob/master/doc/pop_functions.md#pop_inversesolution).

### Move ROI source estimates to EEG.data
This option calls `moveSource2DataField` to create an `EEG` structure where the `EEG.data` field holds the ROI source data compute by `pop_inverseSolution`. The resulting `EEG` structure will be added to `ALLEEG` and shown in the main gui. This option is particularly handy because it allows the use of all the functions in EEGLAB (epoching, filtering, erpimage, etc.) with our source estimates.


[Back](https://github.com/aojeda/headModel/blob/master/doc/Documentation.md)
