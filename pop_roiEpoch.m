function EEG_roi = pop_roiEpoch(EEG, events, lim, varargin)
EEG_roi = moveSource2DataField(EEG);
if nargin < 3
    [EEG_roi, indices] = pop_epoch(EEG_roi);
else
    [EEG_roi, indices] = pop_epoch( EEG_roi, events, lim, varargin{:});
end
if isempty(indices)
    EEG_roi = EEG;
end