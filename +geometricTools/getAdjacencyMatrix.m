function A = getAdjacencyMatrix(vertices,faces)
Nv = size(vertices,1);
n = sum((vertices(faces(:,[1 2 3]),:)-vertices(faces(:,[2 3 1]),:)).^2,2);
A = sparse(faces(:,[1 2 3]),faces(:,[2 3 1]),n,Nv,Nv);
end