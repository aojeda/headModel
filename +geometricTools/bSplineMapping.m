function [def,spacing,offset,SgridWarped] = bSplineMapping(S,T,Sgrid,options)
if nargin < 4, options = struct('Verbose',false,'MaxRef',5);end
mn = min(Sgrid);
Smn = bsxfun(@minus,S,mn);
dim = max(Sgrid) - mn;
Tmn = bsxfun(@minus,T,mn);
[def,spacing,SgridWarped] = point_registration(dim,Smn,Tmn,options);
offset = mn;
SgridWarped = bsxfun(@plus,SgridWarped,offset);
end