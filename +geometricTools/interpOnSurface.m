function yi = interpOnSurface(vertices,faces,elec,y,method)
if nargin < 5, method = 'spline';end
switch method
    case 'ridge'
        yi = geometricTools.ridgeInterpolation(vertices,faces,elec,y);
    case 'linear'
        W = geometricTools.localGaussianInterpolator(elec,vertices,32);
        yi = W*y;
    case 'spline'
        yi = geometricTools.spSplineInterpolator(elec,y,vertices);
    otherwise
        yi = geometricTools.spSplineInterpolator(elec,y,vertices);
end
end
