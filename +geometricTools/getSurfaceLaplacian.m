function [lap,edge] = getSurfaceLaplacian(vertices,faces)
% LAPLACES Calculates a Discrete Surface Laplacian Matrix
%          for a triangulated surface
%
% Wrapper to Darren Weber's mesh_laplacian.
[lap,edge] = geometricTools.mesh_laplacian(vertices,faces);
end