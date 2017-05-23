function [nVertices,nFaces] = openSurface(vertices,faces,rmIndices)
nVertices = vertices;
vertices(rmIndices,:) = [];
[~,rm_1] = ismember(faces(:,1),rmIndices);
[~,rm_2] = ismember(faces(:,2),rmIndices);
[~,rm_3] = ismember(faces(:,3),rmIndices);
rm_faces = rm_1 | rm_2 | rm_3;
faces(rm_faces,:) = [];
[~,J] = ismember(nVertices,vertices,'rows');
nFaces = J(faces);
nVertices = vertices;
end