function D = isInConvexHull(X,Xi)

X = geometricTools.correctOrigin(X);
X = bsxfun(@rdivide,X,sqrt(sum(X.^2,2)));

[x,y,z] = sphere(64);

figure;
surf(x,y,z,'FaceColor','g','FaceAlpha',0.7,'EdgeColor','none');
set(gca,'Projection','perspective','DataAspectRatio',[1 1 1]); hold on;axis tight;camlight

plot3(X(:,1),X(:,2),X(:,3),'.')

X = geometricTools.correctOrigin(X);
X = bsxfun(@rdivide,X,sqrt(sum(X.^2,2)));


N = size(Xi,1);
M = size(X,1);
D = zeros(M,N);
for it=1:N
    d = bsxfun(@minus,X,Xi(it,:));
    D(:,it) = sqrt(sum(( d ).^2,2));
end
end
