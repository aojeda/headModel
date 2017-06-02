# headModel toolbox for MATLAB/EEGLAB

The headModel  toolbox for MATLAB/[EEGLAB](https://sccn.ucsd.edu/eeglab/) is a collection of routines, encapsulated in the `headModel` class, that are commonly used for solving the forward and inverse problems of the EEG.

Note: I am adding documentation as my time allows, feel free to ask me questions.

### Why another forward/inverse problem toolbox?
The `headModel` toolbox was built out of frustration. With some exceptions, it is often cumbersome to get up and running with distributed source analysis of EEG data in MATLAB. 

To estimate images form EEG data (see [EEG source imaging](https://www.ncbi.nlm.nih.gov/pubmed/15351361)) we need a model of the head to link cortical EEG sources to the sensors where the data are collected. Towards that end, here is a summary of the items that we often need (requirements for specific use cases can vary): 

* Template or individual MRI.
* Standard or digitized EEG sensor positions.
* Segment the MRI into gray, white, bone, scalp tissue. 
* Extract surfaces out of the segmented MRIs (for surface-based inverse problem).
* Coregister the EEG sensors with the MRI or surface-based head model.
* Find an EEG forward solver that works well with your MRI-derived data.

Working out solutions for each point listed above is not trivial for many, and often a limiting factor for doing EEG (distributed) source imaging (ESI) analysis. The pourpuse of the `headModel` toolbox is to provide an *out-of-the-box* solution, in MATLAB for maximum flexibility, that can get us quickly from scalp EEG data to distributed cortical source estimates sidestepping the above complications.
 
### Batteries are included
* We provide pre-built and curated surface-based head models in the following variants:
	* Colins27 2003 vertices (cortical sources), 65 channels superset of the 10/20 standard montage
	* Colins27 5003 vertices (cortical sources), 65 channels superset of  the 10/20 standard montage
	* Colins27 5003 vertices (cortical sources), 339 channels superset of  the 10/20 standard montage
* We build high-level interfaces to EEGLAB and OpenMEEG toolboxes.
* We provide several out-of-the box visualization tools.


### What this toolbox can be used for?
* Affine and nonlinear coregistration between a surface-based head model template and a set of sensor locations, both manually through a GUI and automatically. We can apply the coregistration  from the space of the template to the space of the subject's sensors (for computing an individualized head model) or coregister in the opposite direction so that the same head model can be used for all subjects in a study.
* Computation of the lead field matrix using the [Boundary Element Method ](https://en.wikipedia.org/wiki/Boundary_element_method), for which we interface the [OpenMEEG](https://openmeeg.github.io/) toolbox. 
* Estimation of cortical sources using Low Resolution Electrical Tomography ([LORETA](http://www.uzh.ch/keyinst/loreta.htm)). We use our own implementation in MATLAB for greater flexibility.

### What this toolbox doesn't do?
* We cannot segment, normalize, label or extract surfaces from MRI data, for that you can use [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/).
* We cannot solve the forward problem of the EEG using Finite Element method (FEM), for that you can use the [NFT](https://sccn.ucsd.edu/nft/index.html) toolbox, which is part of the EEGLAB plug-in suite.