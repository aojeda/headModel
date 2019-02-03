# headModel toolbox for MATLAB/EEGLAB
**Note:** I am moving this repo [elsewere](https://github.com/aojeda/dsi) to consolidate the forward and inverse problem solvers into a single toolbox. If you are still interested in the headModel toolbox please download it from [EEGLAB's extention page](https://sccn.ucsd.edu/wiki/EEGLAB_Extensions).
![headModel.plot()](https://github.com/aojeda/headModel/blob/master/doc/assets/hm.png)

The headModel  toolbox for MATLAB/[EEGLAB](https://sccn.ucsd.edu/eeglab/) is a collection of routines, encapsulated in the `headModel` class, that are commonly used for solving the forward and inverse problems of the EEG.

### Why another forward/inverse problem toolbox?
The `headModel` toolbox was built out of frustration. With some exceptions, it is often cumbersome to get up and running with distributed source analysis of EEG data in MATLAB.

To estimate EEG source images (see [EEG source imaging](https://www.ncbi.nlm.nih.gov/pubmed/15351361)) we need an electric and geometric model of the head to link cortical EEG sources distributed inside the brain to the sensors where the data are collected. Towards that end, below is a summary of the items that we often need to construct such model (requirements for specific use cases can vary): 

* Template or individual MRI.
* Standard or digitized EEG sensor positions.
* Segment the MRI into gray, white, bone, and scalp tissue. 
* Extract surfaces from of the segmented MRIs (for surface-based inverse problem).
* Co-register the EEG sensors with the MRI or surface-based head model.
* Find an EEG forward solver that works well with your MRI-derived data.

Finding solutions for each point listed above is highly nontrivial for many researchers and engineers, and often a limiting factor for doing EEG (distributed) source imaging (ESI) analysis. **The pourpuse of the `headModel` toolbox is to provide an *out-of-the-box* solution in MATLAB/EEGLAB that can get us quickly from scalp EEG data to distributed cortical source estimates** sidestepping the complications listed above.
 
### Batteries are included
* We provide pre-built and curated surface-based head models in the following variants:
	* Colins27 template with 2003 cortical sources (vertices) and 339 scalp sensors superset of the 10/20 standard montage.
	* Colins27 template with 5003 cortical sources and Biosemi 256 standard montage.
	* Colins27 template with 5003 cortical sources and 339 scalp sensors superset of  the 10/20 standard montage.
* All templates come with the 68 structures [Desikan & Killiany](https://www.ncbi.nlm.nih.gov/pubmed/16530430) anatomical atlas. 
* We provide high-level interfaces to EEGLAB and OpenMEEG toolboxes.
* We provide several out-of-the box visualization tools.


### What this toolbox can be used for?
* Affine and nonlinear co-registration between a surface-based head model template and a set of sensor locations, both manually through a (painless) GUI and unsupervised at script level. We can apply the co-registration from the space of the template to the space of the subject's sensors (for computing an individualized head model) or in the opposite direction so that the same head model can be used for all subjects in a study.
* Computation of the lead field matrix using the [Boundary Element Method](https://en.wikipedia.org/wiki/Boundary_element_method), for which we interface the [OpenMEEG](https://openmeeg.github.io/) toolbox. 
* Estimation of cortical sources using Low Resolution Electrical Tomography ([LORETA](http://www.uzh.ch/keyinst/loreta.htm)). We use our own implementation in MATLAB for greater flexibility.

### What this toolbox is not for?
* We do not support volume-based head models.
* We cannot segment, normalize, label or extract surfaces from MRI data, for that you can use [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/).
* We cannot solve the forward problem of the EEG using Finite Element method (FEM), for that you can use the [NFT](https://sccn.ucsd.edu/nft/index.html) toolbox, which is part of the EEGLAB plug-in suite.


### [Documentation](https://github.com/aojeda/headModel/blob/master/doc/Documentation.md)
