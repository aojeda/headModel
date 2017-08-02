function obj = loreta_peb(hm)
if ~exist('LORETA_PEB','class')
    disp('LORETA_PEB is not installed, we will fallback to LORETA.');
    obj = invSol.loreta(hm);
else
    % Create LORETA_PEB solver object
    obj = LORETA_PEB(hm);
end
end