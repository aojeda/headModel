function EEG = pop_inverseSolution(EEG, windowSize, saveFull, solverType)
if nargin < 1, error('Not enough input arguments.');end
if nargin < 4
    answer = inputdlg({'Input window size','Save full PCD', 'Input solver type'},'pop_inverseSolution',1,{'16','true', 'loreta'});
    if isempty(answer)
        error('Not enough input arguments.');
    else
        windowSize = str2double(answer{1});
        if isempty(windowSize)
            disp('Invalid input for windowSize parameter, we will use the default value.')
            windowSize= 16;
        end
        saveFull = str2num(answer{2}); %#ok
        if isempty(saveFull)
            disp('Invalid input for saveFull parameter, we will use the default value.')
            saveFull= true;
        end
        solverType = answer{3};
    end
end
windowSize=max([1,windowSize]);
smoothing = hann(windowSize);
if windowSize > 1
    windowSize = 2*round(windowSize/2);
    smoothing = smoothing(1:windowSize/2)';
end

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
Ndipoles = size(hm.cortex.vertices,1);
Nx = size(hm.K,2);
if strcmpi(solverType,'loreta')
    solver = invSol.loreta(hm);
else
    % Search plugins folder
    files = dir(fullfile(fileparts(which('headModel.m')),'plugins'));
    plugins = {files.name};
    isdir = [files.isdir];
    plugins = plugins(~isdir);
    for k=1:length(plugins)
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
    X = zeros(Nx, EEG.pnts, EEG.trials);
catch ME
    disp(ME.message)
    disp('Using a LargeTensor object...')
    try
        X = invSol.LargeTensor([Nx, EEG.pnts, EEG.trials]);
    catch
        disp('Not enough disk space to save src data on your tmp/ directory, we will try your home/ instead.');
        [~,fname] = fileparts(tempname);
        if ispc
            homeDir = getenv('USERPROFILE');
        else
            homeDir = getenv('HOME');
        end
        filename = fullfile(homeDir,fname);
        X = invSol.LargeTensor([Nx, EEG.pnts, EEG.trials], filename);
    end
end
X_roi = zeros(Nroi, EEG.pnts, EEG.trials);

% Construct the average ROI operator
P = hm.indices4Structure(hm.atlas.label);
P = double(P);
P = bsxfun(@rdivide,P, sum(P))';

% Check if we need to integrate over Jx, Jy, Jz components
if Nx == Ndipoles*3
    P = [P P P];
end

% Perform source estimation
fprintf('%s source estimation...\n',upper(solverType));

halfWindow = ceil(windowSize/2);

prc_5 = round(linspace(1,EEG.pnts,30));
iterations = 1:halfWindow:EEG.pnts-windowSize;
prc_10 = iterations(round(linspace(1,length(iterations),10)));

for trial=1:EEG.trials
    fprintf('Processing trial %i of %i...',trial, EEG.trials);
    for k=1:halfWindow:EEG.pnts
        loc = k:k+windowSize-1;
        loc(loc>EEG.pnts) = [];
        if isempty(loc), break;end
        if length(loc) < windowSize
            X(:,loc,trial) = solver.update(EEG.data(:,loc,trial));
            X_roi(:,loc,trial) = P*X(:,loc,trial);
            break;
        end
        
        % Source estimation
        Xtmp = solver.update(EEG.data(:,loc,trial));
        
        % Stitch windows
        if k>1 && windowSize > 1
            X(:,loc(1:end/2),trial) = bsxfun(@times, Xtmp(:,1:end/2), smoothing) + bsxfun(@times,X(:,loc(1:end/2),trial), 1-smoothing);
            X(:,loc(end/2+1:end),trial) = Xtmp(:,end/2+1:end);
        else
            X(:,loc,trial) = Xtmp;
        end
        
        % Compute average ROI time series
        X_roi(:,loc,trial) = P*X(:,loc,trial);
        
        % Progress indicatior
        [~,ind] = intersect(loc(1:windowSize),prc_5);
        if ~isempty(ind), fprintf('.');end
        prc = find(prc_10==k);
        if ~isempty(prc), fprintf('%i%%',prc*10);end
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