function obj = peb_l2(hm)
if ~exist('ParametricEmpiricalBayes','class')
    disp('ParametricEmpiricalBayes is not installed, we will fallback to LORETA.');
    obj = invSol.loreta(hm);
else
    % Remove the average reference
    Ny = size(hm.K,1);
    R = eye(Ny)-ones(Ny)/Ny;
    hm.K = R*hm.K;
    options = ParametricEmpiricalBayes.initOptions();
    options.lb.maxTol = 1e-2;
    options.peb.maxIter = 0;
    options.lb.verbose = false;
    options.peb.verbose = false;
    options.peb.useGPU = false;
    [PriorCov,sqrtPriorCov,blocks] = hm2cc(hm);
    obj = ParametricEmpiricalBayes(hm, PriorCov,sqrtPriorCov,blocks, options);
end
end
