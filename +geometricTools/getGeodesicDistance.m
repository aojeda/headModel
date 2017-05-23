function [d,points_path] = getGeodesicDistance(vertices,faces,a,b,verb)
if nargin < 5, verb = false;end
points_path = zeros(size(vertices));
Max_Iter = size(vertices,1);
A = geometricTools.getAdjacencyMatrix(vertices,faces);
point = a;
[d,loc] = min(sum(bsxfun(@minus,vertices,point).^2,2));
point = vertices(loc,:);
points_path(1,:) = point;
if all(point == b)
    points_path(2,:) = b;
    points_path = points_path(1:2,:);
    return
end
for it=2:Max_Iter
    neig = vertices(A(loc,:)>0,:);
    [mx,loc] = min(sum(bsxfun(@minus,neig,b).^2,2));
    delta_d = sqrt(sum((neig(loc,:)-point).^2,2));
    d = d+delta_d;
    if all(point == neig(loc,:)) || all(b == neig(loc,:))
        break
    end
    if verb, fprintf('%f\n',mx);end
    point = neig(loc,:);
    points_path(it,:) = point;
    [~,loc] = min(sum(bsxfun(@minus,vertices,point).^2,2));
end
points_path = points_path(1:it,:);
if verb, fprintf(' done\n');end
end