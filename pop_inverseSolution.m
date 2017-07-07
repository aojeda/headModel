function EEG = pop_inverseSolution(EEG, windowSize, saveFull, solverType)
if nargin < 2, windowSize= 16;end
if nargin < 3, saveFull = true;end
if nargin < 4, solverType = 'loreta';end
windowSize=max([1,windowSize]);
smoothing = hann(windowSize);
if windowSize > 1, smoothing = smoothing(1:windowSize/2)';end

% Load the head model
try
    hm = headModel.loadFromFile(EEG.etc.src.hmfile);
catch
    h = errordlg('EEG.etc.src.hmfile seems to be corrupted or missing, to set it right next we will run >> EEG = pop_forwardModel(EEG)');
    waitfor(h);
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

% Initialize the inverse solver
sc = 1;
if strcmpi(solverType,'loreta')
    solver = invSol.loreta(hm);
else
    % Search plugins folder
    files = dir(fullfile(fileparts(which('headModel.m')),'plugins'));
    plugins = {files.name};
    isdir = [files.isdir];
    plugins = plugins(~isdir);
    for k=1:length(plugins),
        loc = strfind(plugins{k},'.m');
        if ~isempty(loc), plugins{k} = plugins{k}(1:loc-1);end
    end
    ind = ismember(plugins,solverType);
    if any(ind)
        solver = feval(solverType,hm);
        sc = max(abs(EEG.data(:)))/1000;
        EEG.data = EEG.data/sc;
    else
        solver = invSol.loreta(hm);
    end
end

Nroi = length(hm.atlas.label);
try
    X = zeros(solver.Nx, EEG.pnts, EEG.trials);
catch ME
    disp(ME.message)
    disp('Using a LargeTensor object...')
    X = invSol.LargeTensor([solver.Nx, EEG.pnts, EEG.trials]);
end
X_roi = zeros(Nroi, EEG.pnts, EEG.trials);

% Construct the average ROI operator
P = hm.indices4Structure(hm.atlas.label);
P = double(P);
P = bsxfun(@rdivide,P, sum(P))';

% Check if we need to integrate over Jx, Jy, Jz components
if solver.Nx == size(hm.cortex.vertices,1)*3
    P = [P P P];
end

% Perform source estimation
fprintf('%s source estimation...\n',upper(solverType));

if windowSize > 1
    prc_5 = round(linspace(1,EEG.pnts,30));
    iterations = 1:windowSize/2:EEG.pnts-windowSize;
    prc_10 = iterations(round(linspace(1,length(iterations),10)));
end

for trial=1:EEG.trials
    fprintf('Processing trial %i of %i: ',trial, EEG.trials);
    if windowSize > 1
        for k=1:windowSize/2:EEG.pnts
            loc = k:k+windowSize-1;
            loc(loc>EEG.pnts) = [];
            if isempty(loc), break;end
            if length(loc) < windowSize,
                X(:,loc,trial) = solver.update(EEG.data(:,loc,trial));
                X_roi(:,loc,trial) = P*X(:,loc,trial);
                break;
            end
            
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
            
        end
        if ~isempty(prc), fprintf('%i%%',prc*10);end
    else
        X(:,:,trial) = solver.update(EEG.data(:,:,trial));
        X_roi(:,:,trial) = P*X(:,:,trial);
    end
    fprintf('\n');
end
fprintf('Done!\n');
EEG.etc.src.act = X_roi;
EEG.etc.src.roi = hm.atlas.label;
EEG.data = EEG.data*sc;
EEG.etc.src.act = EEG.etc.src.act*sc;
if saveFull
    EEG.etc.src.actFull = X*sc;
else
    EEG.etc.src.actFull = [];
end
EEG.history = char(EEG.history,'EEG = pop_inverseSolution(EEG, windowSize, saveFull);');
disp('The source estimates were saved in EEG.etc.src');
end