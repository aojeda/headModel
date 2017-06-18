## Data structure
In this toolbox we make extensive use of [MATLAB's object oriented programming language](https://www.mathworks.com/discovery/object-oriented-programming.html), which allows us to encapsulate the data (properties) and functions that utilize that data (methods) into a single high-level  interface, the `headModel` class. We find this convenient as the user only needs to learn that one interface, abstracting away much of the complexity inherent to surface handling, coregistration, and data curation. 

The `headModel` class iherits from MATLAB's [`handle`](https://www.mathworks.com/help/matlab/handle-classes.html) class, that means that by assigning an object of this class to a variable, you are assigning a pointer, as opposed to creating another object. Be careful because if you modify the content of the object, the change will affect other objects that may point to the same data. To prevent this from happening, you can simply construct (or load) as many `headModel` objects as you need (see example below).

The `headModel` class has the following proporties:

* `channelSpace`: matrix of number of sensors by (x,y,z) coordinates
* `labels`:  cell array of strings with the name of each sensor
* `cortex`, `inskull`, `outskull`, `scalp`: structures with the `vertices` and `faces` defining the different layers of tissue of the model
* `K`: lead field matrix of number of sensors by number of sources, tipically the number of sources is equal or less than the number of vertices in the `cortex`, it can be three times that number if dipole orientations are computed
* `L`: number of sources by number of sources sparse Laplacian operator defined on the whole cortical surface
* `atlas`: structure with the cell array `labels` containing the name of the ROIs defined in the head model and `colorTable`, a vector of the same length as dipoles in the head model with a number per dipole that indicates its index in the `label` array
* `fiducials`: structure containing the xyz coordinates of the fiducial landmarks `nassion`, `lpa`, `rpa`, `vertex`, and `inion`, it can be empty if no fiducials are marked

## Create, load, and save a `headModel` object
A `headModel` object can be created calling the method os the same name using a key/value pair input, as shown in the following example. 

```MATLAB
channelSpace = randn(4,3);
labels = {'Ch1', 'Ch2', 'Ch3', 'Ch4'};
hm = headModel('channelSpace', channelSpace, 'labels', labels);
```

Use the code snippet below to load and save the object, which includes all the information contained in it, i.e. skin , skul, and cortical surfaces, atlas, lead field, etc.
```MATLAB
% Load from file
headModelFilename = fullfile('resources','head_modelColin27_5003_Standard-10-5-Cap339.mat');
hm.loadFromFile(headModelFilename);

% Save to file
myHeadModelFilename = tempname;
hm.saveToFile(myHeadModelFilename);
```

[Back](https://github.com/aojeda/headModel/blob/master/doc/Documentation.md)
