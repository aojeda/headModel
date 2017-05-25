function EEG = pop_inverseSolution(EEG, solver, windowSize)
if nargin < 3, windowSize=min([64,round(EEG.srate/8)]);end
windowSize=min([64,windowSize]);
dim = size(EEG.data);
reshape(EEG.data, dim(1), []);
n = size(EEG.data,2);

smoothing = hann(windowSize);
smoothing = smoothing(1:windowSize/2)';

X = zeros(solver.Nx,n);
for k=1:windowSize/2:n
    loc = k:k+windowSize-1;
    loc(loc>n) = [];
    if isempty(loc), break;end
    if length(loc) < windowSize, break;end
    Xtmp = solver.update(EEG.data(:,loc));
    
    % Stitch windows
    if k>1
        X(:,loc(1:end/2)) = bsxfun(@times, Xtmp(:,1:end/2), smoothing) + bsxfun(@times,X(:,loc(1:end/2)), 1-smoothing);
        X(:,loc(end/2+1:end)) = Xtmp(:,end/2+1:end);
    else
        X(:,loc) = Xtmp;
    end
end
fprintf('\n');

% Compute average ROI time series
P = solver.hm.indices4Structure(solver.hm.atlas.label);
P = double(P);
P = bsxfun(@rdivide,P, sum(P))';
EEG.etc.src.act = P*X;
EEG.etc.src.roi = solver.hm.atlas.label;

% %% Bandpass
% Fs = EEG.srate;             % Sampling Frequency
% Fstop1 = 0.5;             % Stopband Frequency
% Fpass1 = 1;               % Passband Frequency
% Fpass2 = EEG.srate/2-2;
% Fstop2 = EEG.srate/2-1;
% Dstop = 0.0001;          % Stopband Attenuation
% Dpass = 0.057501127785;  % Passband Ripple
% flag  = 'scale';         % Sampling Flag
% 
% % Calculate the order from the parameters using KAISERORD.
% [N,Wn,BETA,TYPE] = kaiserord([Fstop1 Fpass1 Fpass2 Fstop2]/(Fs/2), [0 1 0], [Dpass Dstop Dpass]);
% 
% % Calculate the coefficients using the FIR1 function.
% bp  = fir1(N, Wn, TYPE, kaiser(N+1, BETA), flag);
% EEG.etc.src.act = filtfilt(bp,1,EEG.etc.src.act')';