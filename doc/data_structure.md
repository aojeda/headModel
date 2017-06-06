# Data structure and file format
In this toolbox we make extensive use of [MATLAB's object oriented programming language](https://www.mathworks.com/discovery/object-oriented-programming.html), which allows us to encapsulate the data (properties) and functions that utilize that data (methods) into a single high-level  interface, the `headModel` class. We find this convenient as the user only needs to learn that one interface, abstracting away much of the complexity inherent to surface handling, coregistration, data curation, etc. The `headModel` class has the following proporties:

* `channelSpace`: matrix of number of sensors by (x,y,z) coordinates
* `labels`:  cell array of strings with the name of each sensor
* `cortex`, `inskull`, `outskull`, `scalp`: structures with the `vertices` and `faces` defining the different layers of tissue of the model
* `K`: lead field matrix of number of sensors by number of sources, tipically the number of sources is equal or less than the number of vertices in the `cortex`, it can be three times that number if dipole orientations are computed
* `L`: number of sources by number of sources sparse Laplacian operator defined on the whole cortical surface
* `atlas`: structure with the cell array `labels` containing the name of the ROIs defined in the head model and `colorTable`, a vector of the same length as dipoles in the head model with a number per dipole that indicates its index in the `label` array
* `fiducials`: structure containing the xyz coordinates of the fiducial landmarks `nassion`, `lpa`, `rpa`, `vertex`, and `inion`, it can be empty if no fiducials are marked