function plot_on_sphere(X,Y,Xi,Yi)
[~,X(:,1), X(:,2), X(:,3)]  = geometricTools.projectOnSphere(X(:,1), X(:,2), X(:,3));
[~,Xi(:,1),Xi(:,2),Xi(:,3)] = geometricTools.projectOnSphere(Xi(:,1),Xi(:,2),Xi(:,3));
X  = bsxfun(@rdivide,X,sqrt(sum(X.^2,2)));
Xi = bsxfun(@rdivide,Xi,sqrt(sum(Xi.^2,2)));

Xt = [X;Xi];
Yt = [Y;Yi];
Xt = bsxfun(@rdivide,Xt,sqrt(sum(Xt.^2,2)));
Xi = bsxfun(@rdivide,Xi,sqrt(sum(Xi.^2,2)));
Ne = size(X,1);
Nf = 72;
[Xs,Ys,Zs]=sphere(Nf);
Xsp = [Xs(:) Ys(:) Zs(:)];
Fsp = geometricTools.localGaussianInterpolator(Xt,Xsp,0.2);


%[J,lambdaOpt,~,iFsp] = ridgeGCV(Yt,Fsp',eye(size(Xsp,1)),100,1);
%J = iFsp*Yt;
Ysp = Fsp*Yt;
figure('NumberTitle','off','Name','Electrode Placements');
set(gca,'Projection','perspective','DataAspectRatio',[1 1 1]); hold on
%plot3(x,y,z,'b.');
plot3(X(:,1),X(:,2),X(:,3),'ro');
plot3(Xi(:,1),Xi(:,2),Xi(:,3),'k.')
legend('input xyz','projected head','Location','BestOutside');
surf(Xs,Ys,Zs,reshape(Ysp,[Nf Nf]+1),'specularstrength',0.1,'facealpha',0.9,'linestyle','none');
camlight
camlight headlight
view(2); rotate3d;
axis vis3d
end