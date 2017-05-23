function [nVertices,nFaces] = getSurfaceROI(vertices,faces,roiIndices)
rmIndices = setdiff(1:size(vertices,1),roiIndices);
[nVertices,nFaces] = geometricTools.openSurface(vertices,faces,rmIndices);
end
