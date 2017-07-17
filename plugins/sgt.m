function obj = sgt(hm, numberOfBasis)
Ny = size(hm.K,1);
if nargin < 2, numberOfBasis = max([100, Ny]);end
if ~exist('ParametricEmpiricalBayes','class')
    disp('ParametricEmpiricalBayes is not installed, we will fallback to SGT.');
    obj = invSol.sgt(hm, numberOfBasis);
else  
    
    % Remove the average reference from the lead field
    R = eye(Ny)-ones(Ny)/Ny;
    H = R*hm.K;
    
    % Compute the spectral decomposition of the Laplacian
    [A,C] = FEM(hm.cortex);
    [P,~] = eigs(C,A,numberOfBasis,'sm');
    B = -fliplr(P);
    
    obj = invSol.sgt(H, B);
end
end
