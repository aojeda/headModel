function f = fit2sphere(r, X, Y, Z, xo, yo, zo)
S = (X-xo).^2  +  (Y-yo).^2  +  (Z-zo).^2  -  r^2;
f = sum( S.^2 );
end