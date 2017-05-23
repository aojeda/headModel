function [fv1,fv2, ind1, ind2] = splitBrainHemispheres(fv)
n = size(fv.vertices,1);
ind1 = 1;
nei = fv.faces;
while true
    sz = size(ind1,1);
    i1 = ismember(nei(:,1),ind1);
    i2 = ismember(nei(:,2),ind1);
    i3 = ismember(nei(:,3),ind1);
    loc = any([i1,i2,i3],2);
    nei_i = nei(loc,:);
    ind1 = unique(nei_i(:));
    if sz == size(ind1,1)
        break
    end
end
ind2 = setdiff(1:n,ind1)';
fv1 = struct('vertices',fv.vertices(ind1,:),'faces',[]);
fv2 = struct('vertices',fv.vertices(ind2,:),'faces',[]);
faces = [];
for k=1:length(ind1)
    loc = any(nei==ind1(k),2);
    if ~any(loc)
        break
    end
    nei_k = nei(loc,:);
    for t=1:size(nei_k,1)
        [~,~,loc_t] = intersect(nei_k(t,:),ind1,'stable');
        faces = [faces;loc_t'];
    end
end
fv1.faces = unique(faces,'rows');
faces = [];
for k=1:length(ind2)
    loc = any(nei==ind2(k),2);
    if ~any(loc)
        break
    end
    nei_k = nei(loc,:);
    for t=1:size(nei_k,1)
        [~,~,loc_t] = intersect(nei_k(t,:),ind2,'stable');
        faces = [faces;loc_t'];
    end
end
fv2.faces = unique(faces,'rows');
end
