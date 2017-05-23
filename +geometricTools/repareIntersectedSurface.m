function verticesExt = repareIntersectedSurface(surfInt,surfOut,dmax)
if nargin < 3, dmax = 8;end
verticesInt = surfInt.vertices;
verticesExt = surfOut.vertices;
[nVerticesInt,d] = geometricTools.nearestNeighbor(verticesExt,verticesInt);
I = d < dmax;
while any(I)
    I2 = ismember(verticesExt,nVerticesInt(I,:),'rows');
    verticesExt(I2,:) = 1.005*verticesExt(I2,:);
    [nVerticesInt,d] = geometricTools.nearestNeighbor(verticesExt,verticesInt);
    I = d < dmax;
end
if any(verticesExt(:) ~= surfOut.vertices(:))
    verticesExt = geometricTools.smoothSurface(verticesExt,surfOut.faces);
end
end
