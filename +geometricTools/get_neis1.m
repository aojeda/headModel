function [Nei_faces,Nei_vertices] = get_neis1(P)
n = size(P.vertices,1);
Nei_faces = cell(n,1);
Nei_vertices = cell(n,1);
hbar = waitbar(0,'calculating neigs...');
for i = 1:n
    [r,c] = find(P.faces == i); %#ok
    tmp = P.faces(r,:)';
    tmp(tmp == i) = [];
    m = length(tmp)/2;
    Nei_faces{i} = reshape(tmp,2,m)';
    for j = 1:m
        Nei_vertices{i}{j} = P.vertices(Nei_faces{i}(j,:),:);
    end
    waitbar(i/n,hbar);
end
close(hbar);
end