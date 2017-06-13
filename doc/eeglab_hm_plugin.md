## GUI interface for EEGLAB
We can use the `headModel` toolbox as a plug-in for [EEGLAB](https://sccn.ucsd.edu/eeglab/) by cloning or downloading this repo to the `eeglab/plugins/` folder in your local machine. Once EEGLAB's GUI pops up, we can access the `headModel` menu item in the tools menu as shown in the figure below
![eeglab_hm_plugin](https://github.com/aojeda/headModel/blob/master/doc/assets/eeglab_hm_plugin.png)

### Surface-based (BEM)forward modeling
This option allows us to perform a semi-automatic coregistration between our channel positions and a selected head model template. After we are done with the coregistration we can proceed to compute the lead field model for our montage and selected head model using the Boundary Element Method as implemented by the [OpenMEEG](https://openmeeg.github.io/) toolbox. Learn more in the page for [Coregistration](https://github.com/aojeda/headModel/blob/master/doc/coregistration.md).

### Inverse source estimation (LORETA)