function [neighbors,D,loc] = nearestNeighbor(S,T,K)
if nargin < 3, K=size(S,1);end
D = zeros(size(S,1),1);
loc = zeros(size(S,1),1);
for k=1:size(S,1)
    dk = sqrt(sum((bsxfun(@minus,S(k,:),T)).^2,2));
    [D(k),loc(k)] = min(dk);
end
neighbors = T(loc(1:K),:);
end
