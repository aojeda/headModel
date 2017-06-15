## GUI interface for EEGLAB
We can use the `headModel` toolbox as a plug-in for [EEGLAB](https://sccn.ucsd.edu/eeglab/) by cloning or downloading this repo to the `eeglab/plugins/` folder in your local machine. Once EEGLAB's GUI pops up, we can access the `headModel` menu item in the tools menu as shown in the figure below 

![eeglab_hm_plugin](https://github.com/aojeda/headModel/blob/master/doc/assets/eeglab_hm_plugin.png)

### Surface-based (BEM)forward modeling
This option allows us to perform a semi-automatic coregistration between our channel positions and a selected head model template. After we are done with the coregistration we can proceed to compute the lead field model for our montage and selected head model using the Boundary Element Method as implemented by the [OpenMEEG](https://openmeeg.github.io/) toolbox. The resulting forward model is stored in a `headModel` object, usually saved next to the *.set* file, a pointer to it is saved in `EEG.etc.src.hmfile`.

Learn more in the page for [Coregistration](https://github.com/aojeda/headModel/blob/master/doc/coregistration.md).
See the documentation for `pop_forwardModel` [here](https://github.com/aojeda/headModel/blob/master/doc/pop_functions.md)

### Inverse source estimation (LORETA)
This option calls the `pop_inverseSolution` function for performing source reconstruction using the LORETA method (see more in the method's official documentation [here](http://www.uzh.ch/keyinst/loreta.htm) and also check out our page [here](https://github.com/aojeda/headModel/blob/master/doc/loreta.md)).

Source estimation is performed on non-overlaping and consecutive segments of data, trial by trial, thus resulting in a tensor of number of sources (vertices in the cortical surface of the head model) by time points by trials. The results are stored in the `EEG.etc.src`, which will contain the following fields:

* `actFull`: a tensor of number of sources by `EEG.pnts` by `EEG.trials` that contains the source time series,
* `act`: same as `actFull` but the first dimension is colapsed within ROIs (regions of interest) that correspond to the atlas in the head model, resulting in a tensor of number of ROI by `EEG.pnts` by `EEG.trials` that contains the source time series per ROI,
* `roi`: cell array of ROI labels. 

See the documentation for `pop_inverseSolution` [here](https://github.com/aojeda/headModel/blob/master/doc/pop_functions.md)



[Back](https://github.com/aojeda/headModel/blob/master/doc/Documentation.md)