function Yi = scatterInterpolator(X,Y,Xi)
n = size(Y,2);
if exist('TriScatteredInterp','class')
    interpfunct = @TriScatteredInterp;
else
    interpfunct = @scatteredInterpolant;
end
if n==1
    F = interpfunct(X(:,1),X(:,2),X(:,3),Y,'nearest');
    Yi = F(Xi(:,1),Xi(:,2),Xi(:,3));
else
    Yi = zeros(size(Xi,1),n);
    for it=1:n
        F = interpfunct(X(:,1),X(:,2),X(:,3),Y(:,it),'nearest');
        Yi(:,it) = F(Xi(:,1),Xi(:,2),Xi(:,3));
    end
end
end
