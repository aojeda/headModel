function obj = bsbl(hm)
if ~exist('ParametricEmpiricalBayes','class')
    disp('ParametricEmpiricalBayes is not installed, we will fallback to LORETA.');
    obj = invSol.loreta(hm);
else
    % Compute the average reference operator
    Ny = size(hm.K,1);
    R = eye(Ny)-ones(Ny)/Ny;
    
    % Configure algorithm options
    options = ParametricEmpiricalBayes.initOptions();
    options.lb.verbose = false;
    options.peb.verbose = false;
    options.peb.maxIter = 50;
    options.peb.useGPU = false;
    
    % Get covariance components
    [PriorCov,sqrtPriorCov,blocks] = hm2cc(hm);
    
    % Create peb object
    obj = ParametricEmpiricalBayes(R*hm.K, PriorCov,sqrtPriorCov,blocks, options);
end
end
