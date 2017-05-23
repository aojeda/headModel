function X = projectOntoUnitarySphere(X)
[~,X(:,1),X(:,2),X(:,3)] = geometricTools.projectOnSphere(X(:,1),X(:,2),X(:,3));
[azimuth,elevation,r] = cart2sph(X(:,1),X(:,2),X(:,3));
[X(:,1),X(:,2),X(:,3)] = sph2cart(azimuth,elevation,elevation*0+1);
end
