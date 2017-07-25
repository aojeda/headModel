function EEG_roi = pop_roiEpoch(EEG, events, lim, varargin)
EEG_roi = EEG;
EEG_roi.data = EEG.etc.src.act;
EEG_roi.etc = rmfield(EEG_roi.etc,'src');
EEG_roi.nbchan = size(EEG_roi.data,1);
EEG_roi.chanlocs = struct('labels',[],'X',[],'Y',[],'Z',[]);
hm = headModel.loadFromFile(EEG.etc.src.hmfile);
xyz = hm.getCentroidROI(hm.atlas.label);
for r=1:EEG_roi.nbchan
    EEG_roi.chanlocs(r) = struct('labels',hm.atlas.label{r},'X',xyz(r,1),'Y',xyz(r,2),'Z',xyz(r,3));
end
if nargin < 3
    EEG_roi = pop_epoch(EEG_roi);
else
    EEG_roi = pop_epoch( EEG_roi, events, lim, varargin{:});
end