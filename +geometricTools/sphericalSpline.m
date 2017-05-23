function Gx = sphericalSpline(x)
% sphericalSpline solves eq. 3 of Perrin et al. (1989)
% g(COS) = 1/4pi * sum[n=1:inf] (( (2*n+1)/( n^m * (n+1)^m ) ) * Pn(COS));

m = 4;
N = 16;    % gives accuracy of 10^-6

P = cat(3, ones(size(x)), x);
Gx = 3 / 2 ^ m * P(:, :, 2);
for n = 2:N
    P(:, :, 3) = ((2 * n - 1) * x .* P(:, :, 2) - (n - 1) * P(:, :, 1)) / n;
    P = P(:,:,[2 3 1]);
    Gx = Gx + (2 * n + 1) / (n ^ m * (n + 1) ^ m) * P(:, :, 2);
end
Gx = Gx / (4 * pi);
end
