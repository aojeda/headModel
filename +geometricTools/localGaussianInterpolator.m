function W = localGaussianInterpolator(X,Xi,h,normalize)
if nargin < 3, h = 0.1*sqrt(mean(sum(X.^2)));end
if nargin < 4, normalize = false;end
if isempty(h), h = 0.1*sqrt(mean(sum(X.^2)));end
N = size(Xi,1);
M = size(X,1);
W = zeros(N,M);
for it=1:N
    d = sum(bsxfun(@minus,X,Xi(it,:)).^2,2);
    W(it,:) = exp(-d/(2*h^2));
end
if normalize, W = bsxfun(@rdivide,W,sum(W,2)+eps);end
end
