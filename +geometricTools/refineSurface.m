function [rVertices,rFaces] = refineSurface(vertices,faces,decimationRate,maxIter)
if nargin < 3, decimationRate = 0.5;end
if nargin < 4, maxIter = 3;end
if isempty(which('meshresample')), error('This function uses Iso2Mesh toolbox, you can download it for free fom: http://iso2mesh.sourceforge.net');end

tmpVertices = vertices;
tmpFaces = faces;
for it=1:maxIter
    [tmpVertices,tmpFaces] = geometricTools.resampleSurface(tmpVertices,tmpFaces,decimationRate);
    tmpVertices = geometricTools.smoothSurface(tmpVertices,tmpFaces);
    disp(it)
end
rVertices = tmpVertices;
rFaces = tmpFaces;
end
