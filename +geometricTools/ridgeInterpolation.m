function Yi = ridgeInterpolation(vertices,faces,elec,Y)
L = geometricTools.getSurfaceLaplacian(vertices,faces);
K = geometricTools.localGaussianInterpolator(vertices,elec,1);
K = full(K);
Yi = ridgeGCV(Y,K,L,100,0);
end
