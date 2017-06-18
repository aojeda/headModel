## Visualization & Interpretation
In this section, we describe how to visualize EEG source estimates computed by LORETA. First, we want to point out that **caution must be exercised** when interpreting LORETA source maps, specially on single-trials, because this method tends to over-estimate the spatial extent of the sources (sometimes too spatially smooth), as it does not incorporates any sparsity constraint. These issues are well documented in the neuroimaging literature and are not discussed further here. To ease the interpretation of this type of source maps, we recommend the use of `t-test` images, which can be straightforwardly computed from the single trial estimates. Then, you can use a multiple comparison method to calculate a significance threshold and discard the non-significant sources.

For users accustomed to working with ICA, note that LORETA estimates generaly reflect, in a single cortical map, the contribution of several sources to the scalp EEG, as LORETA **is not** a source separation method. Although we provide ROI-collapsed source time series in `EEG.etc.src.act`, these should be considered an approximation and no independence can be claimed. See [here](https://www.ncbi.nlm.nih.gov/pubmed/19378278) a more sophisticated method that can deal with source estimation subject to smoothness and independence constraints.

#### Use `pop_erpimage` to visualize ROI source data
Suppose that you have used `pop_inverseSolution` to estimate the distributed cortical sources of epoched EEG data. In addition, suppose that you are interested in an ERP that may be around the Supplementary Motor Area (SMA) and want to show a panel with the cortical map that corresponds to the point of maximum negativity, within the first 100 ms, of the source ERP in the SMA. We can use `pop_erpimage` as follows:
```matlab
% Load the headModel object
hm = headModel.loadFromFile(EEG.etc.src.hmfile);

% Create a new EEG structure
EEG1 = EEG;

% Overwrite the data field with the source data
EEG1.data = EEG.etc.src.act;

% Update nbchan 
EEG1.nbchan = length(hm.atlas.label);

% Construct a minimal chanlocs structure with ROI locations and labels
EEG1.chanlocs = repmat(struct('labels',[],'X',[],'Y',[],'Z',[]),EEG1.nbchan);
xyz = hm.getCentroidROI(hm.atlas.label);
for k=1:EEG1.nbchan
    EEG1.chanlocs(k) = struct('labels',hm.atlas.label{k},'X',xyz(k,1),'Y',xyz(k,2),'Z',xyz(k,3));
end

% Find the ROI that may correspond to the SMA (in this atlas that may be the Paracentral Gyrus)
paracentral = find(ismember(hm.atlas.label,'paracentral L'));

% Visualize single-trial source estimates
fig = figure;
pop_erpimage(EEG1,1, paracentral,[],hm.atlas.label{paracentral},10,1,{},[],'latency' ,'yerplabel','nA/mm^2','erp','on','cbar','on');
``` 

Now, we plot the cortical map as follows:
```matlab
% Compute the source ERP (collapsed within ROIs)
ERP_src_roi = mean(EEG.etc.src.act,3);

% Compute the source ERP on the whole cortical space
ERP_src_cortex = mean(EEG.etc.src.actFull, 3);

% Find the indices of the first 100 ms
ind_100ms = find(EEG1.times>0 & EEG1.times<100);

% Find the index of the maximum negativity within the first 100 ms for the ROI that is relevant to us
[~,ind_mn] = min(ERP_src_roi(paracentral,ind_100ms));

% Get the handle to the axes where we will plot the source image
ax = fig.Children(1);

% Plot the cortical map
patch(...
    'vertices', hm.cortex.vertices,...
    'faces', hm.cortex.faces,...
    'FaceVertexCData', ERP_src_cortex(:,ind_100ms(ind_mn)),...
    'FaceColor','interp',...
    'FaceLighting','phong',...
    'LineStyle','none',...
    'FaceAlpha',1,...
    'SpecularColorReflectance',0,...
    'SpecularExponent',25,...
    'SpecularStrength',0.25,...
    'parent',ax);
axis tight vis3d equal
set(ax,'Position',[0.1690, 0.6, 0.1673, 0.2471]);
view(ax, [-90 90])
camlight(0,180)
camlight(0,0)
title(ax,['t=' num2str(EEG1.times(ind_100ms(ind_mn))) 'ms'])
```
which results in the following figure:

![src_erpimage](https://github.com/aojeda/headModel/blob/master/doc/assets/src_erpimage_2.png)

#### Interactive continuous visualization of source estimates
We can also visualize the source estimates on a cortical surface for the whole epoch. Using the variables defined in the examples above we have:
```matlab
% Compute channel-space ERP
ERP = mean(EEG.data,3);

% Set figure title
ftitle = 'My source estimates';

% Set autoscale (if false a colorbar based on the whole data will be used)
autoscale = false;

% Set frames per second used to make a movie (optional)
fps = 30;

% Set a time line
time_line = EEG1.times;

% Plot on the head model
hm.plotOnModel(ERP_src_cortex, ERP, ftitle, autoscale, fps, time_line);
```
Use the custom toolbar section on the right to interact with the figure
![src_map](https://github.com/aojeda/headModel/blob/master/doc/assets/src_map.png)

Click on the `topography` icon to switch the visualization to the topography
![topo_map](https://github.com/aojeda/headModel/blob/master/doc/assets/topo_map.png)

Use the `+`/`-`  keys on your keyboard to tune the extrapolation of the sensor data on the head.

[Back](https://github.com/aojeda/headModel/blob/master/doc/Documentation.md)

