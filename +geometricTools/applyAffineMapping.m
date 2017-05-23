function T = applyAffineMapping(S,Aff)
T = [S ones(size(S,1),1)]*Aff';
T(:,4) = [];
end