function J = simulateGaussianSource(X,X0,h)
if nargin < 3, h = 0.1;end
J = geometricTools.localGaussianInterpolator(X,X0,h)';
end
