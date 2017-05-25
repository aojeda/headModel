function EEG = pop_inverseSolution(EEG, windowSize, saveFull)
if nargin < 2, windowSize=min([64,round(EEG.srate/8)]);end
if nargin < 3, saveFull = true;end
windowSize=min([64,windowSize]);
smoothing = hann(windowSize);
smoothing = smoothing(1:windowSize/2)';

% Load the head model
try
    hm = headModel.loadFromFile(EEG.etc.src.hmfile);
catch
    error('EEG.etc.src.hmfile seems to be corrupted or missing, to set it right run >> EEG = pop_forwardModel(EEG);')
end
% Initialize the LORETA solver
solver = WMNInverseSolver(hm);

Nroi = length(hm.atlas.label);
X = zeros(solver.Nx, EEG.pnts, EEG.trials);
X_roi = zeros(Nroi, EEG.pnts, EEG.trials);

% Construct the average ROI operator
P = solver.hm.indices4Structure(solver.hm.atlas.label);
P = double(P);
P = bsxfun(@rdivide,P, sum(P))';

% Perform source estimation
for trial=1:EEG.trials
    for k=1:windowSize/2:EEG.pnts
        loc = k:k+windowSize-1;
        loc(loc>EEG.pnts) = [];
        if isempty(loc), break;end
        if length(loc) < windowSize, break;end
        
        % Source estimation
        Xtmp = solver.update(EEG.data(:,loc,trial));
        
        % Stitch windows
        if k>1
            X(:,loc(1:end/2),trial) = bsxfun(@times, Xtmp(:,1:end/2), smoothing) + bsxfun(@times,X(:,loc(1:end/2),trial), 1-smoothing);
            X(:,loc(end/2+1:end),trial) = Xtmp(:,end/2+1:end);
        else
            X(:,loc,trial) = Xtmp;
        end
    end
    % Compute average ROI time series
    X_roi(:,:,trial) = P*X(:,:,trial);
end
EEG.etc.src.act = X_roi;
EEG.etc.src.roi = hm.atlas.label;
if saveFull
    EEG.etc.src.actFull = X;
else
    EEG.etc.src.actFull = [];
end