function [neighbors,neigd] = kNearestNeighbor(S,T,K)
if nargin < 3, K = 3;end
n = size(S,1);
neighbors = zeros(n,3,K);
neigd = zeros(n,K);
for k=1:n
    dk = sqrt(sum((bsxfun(@minus,T,S(k,:))).^2,2));
    [dks,locs] = sort(dk);
    locs(dks==0) = [];
    neigd(k,:) = dk(locs(1:K));
    neighbors(k,:,:) = T(locs(1:K),:)';
end
end