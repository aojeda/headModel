function Cos = cosines(A,B)
Na = size(A,1);
Nb = size(B,1);
One1 = ones(1,Nb);
One2 = ones(Na,1);
Xe = A(:,1)*One1;
Ye = A(:,2)*One1;
Ze = A(:,3)*One1;
Xf = One2*B(:,1)';
Yf = One2*B(:,2)';
Zf = One2*B(:,3)';
Cos = (Xe-Xf).^2 + (Ye-Yf).^2 + (Ze-Zf).^2;
Cos = 1-Cos/2;
Cos(Cos > 1) = 1-eps;
Cos(Cos < -1) = -1+eps;
end
