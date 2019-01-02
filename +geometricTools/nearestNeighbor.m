function [neighbors,D,loc] = nearestNeighbor(S,T,K)
if nargin < 3, K=size(S,1);end
D = zeros(size(S,1),K);
loc = zeros(size(S,1),K);
for k=1:size(S,1)
    dk = sqrt(sum((bsxfun(@minus,S(k,:),T)).^2,2));
    [dtmp,ltmp] = sort(dk);
    if dtmp(1)==0
        D(k,:) = dtmp(2:K+1);
        loc(k,:) = ltmp(2:K+1);
    else
        D(k,:) = dtmp(1:K);
        loc(k,:) = ltmp(1:K);
    end
end
neighbors = T(loc(1:K),:);
end
