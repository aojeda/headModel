## Coregistration
The coregistration GUI can be launched in three different ways:

* Using the high-level `pop_forwardModel` function:
```matlab
EEG = pop_forwardModel(EEG);
```
A call to `pop_forwardModel` without arguments will launch the following dialog window to select the template head model

![select_template](https://github.com/aojeda/headModel/blob/master/doc/assets/select_template.png)

After loading the `headModel` template internally, the function uses the `EEG.chanlocs.labels` to find a common set of channels between our `EEG` structure and the selected head model. Then three things can happen:
1. If a common set is found and the template has a pre-computed lead field (which is the case for all the templates that we provide), we skip the coregistration procedure and create a new `headModel` object containing only channel positions, labels and lead field rows correspondent to the common set already available in the template.
2. A common set is found but the lead field is empty, as it may be the case for a head model built from the subject's own MRI (using tools from elsewhere), in which case we proceed to compute the lead field.
3. A common set is not found, which could happen for instance when using a Biosemi cap, which channel labels do not conform to the 10/20 standard, in which case the `Coregister` GUI is launched.

* Using a `headModel` object (low-level):
```MATLAB
% Extract channel positions and labels from the EEG structure
elec = [[EEG.chanlocs.X]', [EEG.chanlocs.Y]', [EEG.chanlocs.Z]'];
labels = {EEG.chanlocs.labels};

% Load a template
hm = headModel.loadFromFile(fullfile(my_eeglab_folder,'plugins','headModel','resources','head_modelColin27_5003_Standard-10-5-Cap339.mat'));

% Launch GUI
hm.coregister(elec, labels);
```
When this option is used, prior to launching the `Coregister` GUI, the `headModel` interface method `coregister` (note the lowercase in method's name) performs an automatic affine coregistration so that only minimal manual adjustments may  be required on the GUI side.

* Calling the `Coregister` function directly (ultra low-level). Using the data from the example above we have:
```matlab
Coregister(hm, elec, labels);
```

The figure below shows the `Coregster` GUI, we can see that some manual adjustments are needed to properly place our sensors on the head of the template.

![coregister_1](https://github.com/aojeda/headModel/blob/master/doc/assets/coregister_1.png)

To adjust the channel positions we use the following controls:

* Translation: shift the `x`, `y`, or `z` coordinates independently pressing the `+`/`-` buttons.
* Scale: scale the `x`, `y`, or `z` coordinates independently pressing the `+`/`-` buttons.
* Rotation: rotate around the `x`, `y`, or `z`-axis pressing the `+`/`-` buttons.
* Center: center the sensors towards the coordinate origin.
* Autoscale: scales all the sensors by a constant so that the resulting montage is in the same units than the template.
* Project onto (the head): projects the sensors to the nearest point in the template's head. The nearest points are found by calculating the orthogonal projection of the sensors down to planes that are locally tangent to the template's head. This option is especially useful for providing the last touch to the coregistration process so that we make sure that all the sensors are making good contact with the layer of skin.

Use the `Start over` button to discard all the steps done previously and start the manual coregistration process again. Once we are done, the coregistered montage should look roughly as follows

![coregister_2](https://github.com/aojeda/headModel/blob/master/doc/assets/coregister_2.png)

Use the `Run BEM` to compute the lead field matrix using the BEM method as implemented in the [OpenMEEG](https://openmeeg.github.io/) toolbox. To use `OpenMEEG`, its binaries need to be installed on your system, on Unix/Linux this can be usually accomplished issuing `apt-get` commands (consult your local Linux guru/admin for help) or you can compile the project from source as shown [here](https://github.com/openmeeg/openmeeg/). 

*Note: I have noticed that `OpenMEEG` appears to crash in some systems even after building it from source, if you are one of those lucky people to have such experience, you can contact the maintainers of that toolbox and, if you don't mind, please let me know if a new  patch is issued so that I can update this tutorial. 

[Back](https://github.com/aojeda/headModel/blob/master/doc/Content.md)