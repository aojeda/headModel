function [nei,nei_tri] = get_neis(P)
% helper function for getSurfaceLaplacian
% Nelson Trujillo Barreto
% Pedro antonio Valdes Hernandez
% Cuban Neuroscience Center
n = size(P.vertices,1);
nei_tri = cell(n,1);
nei = cell(n,1);
for i = 1:n
    [r,c] = find(P.faces == i); %#ok
    nei_tri{i} = r;
    nei{i} = setdiff(unique(P.faces(r,:)),i);
end
end
