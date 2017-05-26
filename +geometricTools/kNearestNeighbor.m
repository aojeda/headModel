function neighbors = kNearestNeighbor(S,T,K)
if nargin < 3, K = 3;end
neighbors = zeros(size(S,1),3,K);
for k=1:size(S,1)
    dk = sqrt(sum((bsxfun(@minus,S(k,:),T)).^2,2));
    [~,locs] = sort(dk);
    neighbors(k,:,:) = T(locs(1:K),:)';
end
end