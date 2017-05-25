close all
clear all
clc

% Add this folder and dependencies to the path
addpath(genpath('pwd'))

%%
hm = headModel.loadFromFile('resources/head_modelColin27_5003_xyz_Standard-10-5-Cap339.mat');
hm.plot();
%%
snr = 10;                           % Signal to noise ratio
Nx = size(hm.cortex.vertices,1);    % Number of sources
Nt = 100;                           % Number of simulated samples
x0 = hm.cortex.vertices(unidrnd(Nx, Nt,1),:);   % Center of simulated sources

% Open the surface by the Corpus Callosum (unlabeled vertices)
rmIndices = find(hm.atlas.colorTable==0);

% Get SVD decomposition of Kstd/L. 
% Kstd is the LF standardized by source to reduce depth bias.
[Ut, s2,iLV, Kstd,ind,K,L] = hm.svd4sourceLoc({},{rmIndices});

Jall = [];
err = zeros(Nt,1);
I = zeros(Nx,3);
I(ind,:) = 1;
I = find(I(:));
for k=1:Nt
    
    % Generate Gaussian patch centered on a random location
    J = geometricTools.simulateGaussianSource(hm.cortex.vertices,x0(k,:),0.01);
    
    % Simulate xyz components
    J = [J;J;J];
    
    % Simulate EEG
    y = Kstd*J(I);
    
    % Simulate noisy trials to be able to compute a t-score as in sLoreta
    % for ERPs
    y = y*ones(1,100);
    y = awgn(y,snr,'measured');
    
    % Calculate inverse solution
    [tmp,lambdaOpt] = ridgeSVD(y,Ut, s2,iLV,100,0);
    
    % Compute t-score and store
    Jhat = 0*J;
    Jhat(I) = median(tmp,2)./(std(tmp,[],2)+eps);
       
    % Compute localization error
    [~,loc1] = max(sum(reshape(J,[],3).^2,2));
    [~,loc2] = max(sum(reshape(Jhat,[],3).^2,2));
    err(k) = norm(hm.cortex.vertices(loc1,:)-hm.cortex.vertices(loc2,:));
    
    % Collect solutions for visualization
    Jall = [Jall J Jhat];
end
% 100x to convert to cm
err = 100*err;
%%
yall = Kstd*Jall(I,:);
hm.plotOnModel(Jall,yall,'',true);
figure;
subplot(121);plot(err);ylabel('Localization error (cm)'); xlabel('')
subplot(122);hist(err,20); xlabel('Localization error (cm)')
[median(err) mean(err) std(err)]

