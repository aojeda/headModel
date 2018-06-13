function obj = bsbl(hm)
if ~exist('BSBL2S','class')
    disp('BSBL2S is not installed, we will fallback to LORETA.');
    obj = invSol.loreta(hm);
else
    % Create BSBL solver object
    options = BSBL2S.initOptions();
    options.stage1.verbose = false;
    options.stage2.verbose = false;
    options.stage1.maxIter = 20;
    options.stage2.maxIter = 20;
    
    % Std lead field
    norm_K = norm(hm.K);
    hm.K = hm.K/norm_K;
    hm.L = hm.L/norm_K;
    hm.K = bsxfun(@rdivide,hm.K,std(hm.K,[],1));
    
    % Get covariance components
    [PriorCov,sqrtPriorCov,blocks] = BSBL2S.hm2cc(hm);

    % Create peb object
    obj = BSBL2S(hm.K, PriorCov,sqrtPriorCov,blocks, options);
end
end
