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
    errordlg('EEG.etc.src.hmfile seems to be corrupted or missing, to set it right next we will run >> EEG = pop_forwardModel(EEG)');
    EEG = pop_forwardModel(EEG);
    try
        hm = headModel.loadFromFile(EEG.etc.src.hmfile);
    catch
        errordlg('For the second time EEG.etc.src.hmfile seems to be corrupted or missing, try the command >> EEG = pop_forwardModel(EEG);');
        return;
    end
end

% Select channels
labels_eeg = {EEG.chanlocs.labels};
[~,loc] = intersect(lower(labels_eeg), lower(hm.labels),'stable');
EEG = pop_select(EEG,'channel',loc);
                    
% Initialize the LORETA solver
solver = WMNInverseSolver(hm);

Nroi = length(hm.atlas.label);
try
    X = zeros(solver.Nx, EEG.pnts, EEG.trials);
catch ME
    disp(ME.message)
    disp('Using a LargeTensor object...')
    X = LargeTensor([solver.Nx, EEG.pnts, EEG.trials]);
end             
X_roi = zeros(Nroi, EEG.pnts, EEG.trials);

% Construct the average ROI operator
P = solver.hm.indices4Structure(solver.hm.atlas.label);
P = double(P);
P = bsxfun(@rdivide,P, sum(P))';

% Perform source estimation
disp('LORETA source estimation...')

prc_5 = round(linspace(1,EEG.pnts,30));
iterations = 1:windowSize/2:EEG.pnts-windowSize;
prc_10 = iterations(round(linspace(1,length(iterations),10)));

for trial=1:EEG.trials
    fprintf('\nProcessing trial %i of %i: ',trial, EEG.trials);
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
        
        % Compute average ROI time series
        X_roi(:,loc,trial) = P*X(:,loc,trial);
        
        % Progress indicatior
        [~,ind] = intersect(loc(end-windowSize/2:end),prc_5);
        if ~isempty(ind), fprintf('.');end
        prc = find(prc_10==k);
        if ~isempty(prc), fprintf('%i%%',prc*10);end
    end
end
fprintf(' done!\n');
EEG.etc.src.act = X_roi;
EEG.etc.src.roi = hm.atlas.label;
if saveFull
    EEG.etc.src.actFull = X;
else
    EEG.etc.src.actFull = [];
end
end