function obj = bsbl(hm)
if ~exist('ParametricEmpiricalBayes','class')
    disp('ParametricEmpiricalBayes is not installed, we will fallback to LORETA.');
    obj = invSol.loreta(hm);
else
    % Remove the average reference
    Ny = size(hm.K,1);
    R = eye(Ny)-ones(Ny)/Ny;
    hm.K = R*hm.K;    
    model = ParametricEmpiricalBayes.makeObservationModel();
    model.hm = hm;
    model.options.peb.useGPU = false;
    model.options.lb.verbose = false;
    model.options.peb.verbose = false;
    model.options.peb.maxIter = 50;
    obj = ParametricEmpiricalBayes(model);
end
end
