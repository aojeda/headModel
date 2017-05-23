function [vertices,faces] = repareSurface(vertices,faces)
[vertices,faces] = removedupnodes(vertices,faces);
faces = removedupelem(faces);
[vertices,faces]=removeisolatednode(vertices,faces);
end