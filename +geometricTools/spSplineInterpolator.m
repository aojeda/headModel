function [Yi,W] = spSplineInterpolator(X,Y,Xi,plotFlag)
% Computes the spherical spline interpolator based on Perrin, F.,
% Pernier, J., Bertrand, O., Echallier, J.F. (1990). Corrigenda
% EEG 02274. Electroencephalography and Clinical Neurophysiology, 76, 565.

if nargin < 4, plotFlag = false;end
%X0 = mean(X);
%X  = bsxfun(@minus,X,X0);
%Xi  = bsxfun(@minus,Xi,X0);
X  = geometricTools.projectOntoUnitarySphere(X);
Xi = geometricTools.projectOntoUnitarySphere(Xi);
%X  = bsxfun(@rdivide,X,sqrt(sum(X.^2,2)));
%Xi = bsxfun(@rdivide,Xi,sqrt(sum(Xi.^2,2)));

%--
M = size(X,1);
One = ones(size(Xi,1),1);
%--

% Solving eq. 4 of Perrin et al. (1989)
COS_X  = geometricTools.cosines(X,X);
COS_Xi = geometricTools.cosines(Xi,X);

% Solving eq. 3 of Perrin et al. (1989)
Gx  = geometricTools.sphericalSpline(COS_X);
Gxi = geometricTools.sphericalSpline(COS_Xi);

% Solving eq. 2 Perrin et al. (1989)
[C,~,~,T] = ridgeGCV([Y;0],[Gx ones(M,1);ones(1,M) 0],eye(M+1));

% Interpolating with the spherical harmonics
Yi = [Gxi One]* C;

W = [Gxi One]* T(:,1:end-1);

% Plot the input & projected electrode positions on a sphere
if plotFlag
    geometricTools.plot_on_sphere(X,Y,Xi,Yi);
end
end
