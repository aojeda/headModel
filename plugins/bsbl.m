function obj = bsbl(hm)
if ~exist('BSBL','class')
    disp('BSBL is not installed, we will fallback to LORETA.');
    obj = invSol.loreta(hm);
else
    % Create BSBL solver object
    obj = BSBL(hm);
end
end
