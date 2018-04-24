function obj = bsbl(hm)
if ~exist('BSBL2S','class')
    disp('BSBL2S is not installed, we will fallback to LORETA.');
    obj = invSol.loreta(hm);
else
    % Create BSBL solver object
    options = BSBL2S.initOptions();
    options.stage1.verbose = false;
    options.stage2.verbose = false;
    options.stage1.maxIter = 10;
    options.stage2.maxIter = 20;
    
    % Get covariance components
    [PriorCov,sqrtPriorCov,blocks] = BSBL2S.hm2cc(hm);
    
    % Create peb object
    obj = BSBL2S(hm.K, PriorCov,sqrtPriorCov,blocks, options);
end
end
