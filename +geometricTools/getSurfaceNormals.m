function [normals,faces] = getSurfaceNormals(vertices,faces,normalsIn)
if nargin < 3, normalsIn = true;end
normals = geometricTools.get_normals(vertices,faces);
area1 = geometricTools.getSurfaceArea(vertices,faces);
area2 = geometricTools.getSurfaceArea(vertices+normals,faces);
if area2 < area1% && normalsIn
    faces = fliplr(faces);
    normals = geometricTools.get_normals(vertices,faces);
end
if normalsIn
    faces = fliplr(faces);
    normals = geometricTools.get_normals(vertices,faces);
end
end
