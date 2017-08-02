function obj = mnsgt(hm)
if ~exist('MNSGT','class')
    disp('MNSGT is not installed, we will fallback to LORETA.');
    obj = invSol.loreta(hm);
else
    % Create BSBL solver object
    obj = MNSGT(hm);
end
end