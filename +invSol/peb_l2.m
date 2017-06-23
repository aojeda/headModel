function obj = peb_l2(hm)
if ~exist('ParametricEmpiricalBayes','class')
    disp('ParametricEmpiricalBayes is not installed, we will fallback to LORETA.');
    obj = invSol.loreta(hm);
else
    % Remove the average reference
    Ny = size(hm.K,1);
    R = eye(Ny)-ones(Ny)/Ny;
    hm.K = R*hm.K;
    model = ParametricEmpiricalBayes.makeObservationModel();
    model.options.peb.maxIter = 0;
    model.options.lb.verbose = false;
    model.options.peb.verbose = false;
    model.options.peb.useGPU = false;
    model.hm = hm;
    obj = ParametricEmpiricalBayes(model);
end
end
