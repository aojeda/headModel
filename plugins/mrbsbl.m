function obj = mrbsbl(hm)
if ~exist('MultiResolutionBSBL','class')
    disp('MultiResolutionBSBL is not installed, we will fallback to LORETA.');
    obj = invSol.loreta(hm);
else   
    % Create solver object
    obj = MultiResolutionBSBL(R*hm.K, PriorCov,sqrtPriorCov,blocks, options);
end
end