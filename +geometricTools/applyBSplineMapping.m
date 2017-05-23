function SgridWarped = applyBSplineMapping(def,spacing,offset,Sgrid)
Smn = bsxfun(@minus,Sgrid,offset);
SmnWarped = bspline_trans_points_double(def,spacing,Smn);
SgridWarped = bsxfun(@plus,SmnWarped,offset);
end