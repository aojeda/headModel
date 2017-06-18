## Co-registration
The `Coregister` GUI can be launched in three different ways:

* Using the high-level `pop_forwardModel` function:
```matlab
EEG = pop_forwardModel(EEG);
```
A call to `pop_forwardModel` without arguments will launch the following dialog window that allows you to select the template head model

![select_template](https://github.com/aojeda/headModel/blob/master/doc/assets/select_template.png)

After loading the `headModel` template, the function uses `EEG.chanlocs.labels` to find a common set of channels between your `EEG` structure and the selected head model. Then, three things can happen:
1. If a common set is found and the template has a pre-computed lead field (which is the case for all the templates that we provide), we skip the co-registration procedure and create a new `headModel` object containing only channel positions, labels, and the lead field rows that correspond to the common set. Be mindful of the fact that the resulting `EEG` structure may have fewer channels than the original, as we keep only the channels that are in the common set.
2. A common set is found but the lead field is empty, as it may be the case for a head model built from the subject's own MRI (using tools from elsewhere), in which case we proceed to compute the lead field.
3. A common set is not found, which could happen for instance when using a Biosemi cap, whose channel labels do not conform to the 10/20 standard, in which case the `Coregister` GUI is launched.

Once the function returns, you can find a pointer to the resulting `headModel` in `EEG.etc.src.hmfile`, which is usually saved next to the *.set* file.

* Using a `headModel` object (low-level):
```matlab
% Extract channel positions and labels from the EEG structure
elec = [[EEG.chanlocs.X]', [EEG.chanlocs.Y]', [EEG.chanlocs.Z]'];
labels = {EEG.chanlocs.labels};

% Load a template
hm = headModel.loadFromFile(fullfile(my_eeglab_folder,'plugins','headModel','resources','head_modelColin27_5003_Standard-10-5-Cap339.mat'));

% Launch GUI
hm.coregister(elec, labels);

% Plot the co-registered head model
hm.plot();
```
When this option is used, prior to launching the `Coregister` GUI, the `headModel` interface method `coregister` (note the lowercase in the method's name) performs an automatic affine co-registration so that only minimal manual adjustments may  be required on the GUI side.

* Calling the `Coregister` function directly (ultra low-level). Using the data from the example above we have:
```matlab
Coregister(hm, elec, labels);
```
This option is provided for maximum flexibility. After the GUI returns, the results will be stored in the object `hm`,  which can then be saved to disk or used in any other way that suits the user. See mode about loading/saving head models [here](https://github.com/aojeda/headModel/blob/master/doc/data_structure.md).

The figure below shows the `Coregster` GUI, we can see that some manual adjustments are needed to properly place our sensors on the head of the template.

![coregister_1](https://github.com/aojeda/headModel/blob/master/doc/assets/coregister_1.png)

To adjust the channel positions we use the following controls:

* Translation: shift the `x`, `y`, or `z` coordinates independently pressing the `+`/`-` buttons.
* Scale: scale the `x`, `y`, or `z` coordinates independently pressing the `+`/`-` buttons.
* Rotation: rotate around the `x`, `y`, or `z`-axis pressing the `+`/`-` buttons.
* Center: center all the sensors towards the coordinate origin.
* Autoscale: scales all the sensors by a constant so that the resulting montage is in the same units than the template.
* Project onto (the head): projects the sensors to the nearest point in the template's head. The nearest points are found by calculating the orthogonal projection of the sensors down to planes that are locally tangent to the template's head. This option is especially useful for providing the last touch to the co-registration process so that we make sure that all the sensors are making good contact with the layer of skin.

Use the `Start over` button to discard all the steps done previously and start the manual co-registration process again. Once we are done, the coregistered montage should look approximately as follows

![coregister_2](https://github.com/aojeda/headModel/blob/master/doc/assets/coregister_2.png)

Use the `Run BEM` button to compute the lead field matrix using the BEM method, as implemented in the [OpenMEEG](https://openmeeg.github.io/) toolbox. To use `OpenMEEG`, its binaries need to be installed on your system, on Unix/Linux this can be usually accomplished issuing `apt-get` commands (consult your local Linux guru/admin for help) or you can compile the project from source as shown [here](https://github.com/openmeeg/openmeeg/). 

*Note: I have noticed that `OpenMEEG` appears to crash in some systems even after building it from source, if you are one of those lucky people to have such experience, you can contact the maintainers of that toolbox and, if you don't mind, please let me know if a new  patch is issued so that I can update this tutorial. 

[Back](https://github.com/aojeda/headModel/blob/master/doc/Documentation.md)