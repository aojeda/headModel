function [Aff,Sn, scale] = affineMapping(S,T)
% S: source space
% T: target space
scale = (norm(T)/norm(S))^2;
S(:,end+1) = 1;
T(:,end+1)=1;
Aff = (S'*S\S'*T)';
Sn = geometricTools.applyAffineMapping(S(:,1:3),Aff);
end
