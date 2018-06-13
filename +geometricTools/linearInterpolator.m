function W = linearInterpolator(X,Xi)
X = X';
Xi = Xi';
W = invSol.ridgeGCV(Xi,X,speye(size(X,2)),100,0);
W = W';
end
