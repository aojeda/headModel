function [rVertices,rFaces] = resampleSurface(vertices,faces,decimationPercent)
if nargin < 2, error('Not enough input arguments.');end
if nargin < 3, decimationPercent = 0.1;end
if isempty(which('meshresample')), error('This function uses Iso2Mesh toolbox, you can download it for free fom: http://iso2mesh.sourceforge.net');end
[rVertices,rFaces]=meshresample(vertices,faces,decimationPercent);
end
