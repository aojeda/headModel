function Xcentered = correctOrigin(X)
[m,n] = size(X);
K = ones(m,n);
B = pinv(K'*K)*K'*X;
X0 = K*B;
Aff = eye(4);
Aff([1 2],4) = X0(1,[1 2])';
Xcentered = Aff\[X ones(m,1)]';
Xcentered = Xcentered(1:3,:)';
end
