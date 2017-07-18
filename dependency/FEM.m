function [A,C] = FEM(surf)
%
%function [A C] = FEM(surf)
%
% Performs the finite element method (FEM) on a surface
% and computes A and C matrices.
%
% surf is a given as the default MATLAB surface mesh format 
% A, C are sparse matrices. See references [1]-[3] for the definition of
% matrices and how they are mathematicallhy defined. If you use the code,
% please reference one of the references. 
%
%    
%
%(C) Florian Bachmann (removed for-loop, 2011)
%    Institut f?r Geophysik und Geoinformatik
%    TU Bergakademie Freiberg
%    
%    Seong Ho Seo (fixed the bug in the original code, 2010)
%    Department of Brain and Cognitive Sciences
%    Seoul National University
%
%    Moo K. Chung (original code, 2009) mkchung@wisc.edu 
%    Department of Biostatistics and Medical Informatics
%    University of Wisconsin-Madison
%
%
% The code is downloaded from
% http://brainimaging.waisman.wisc.edu/~chung/lb/

% Reference
% [1] Chung, M.K. 2001. Statistical Morphometry in Neuroanatomy, 
%     PhD Thesis, McGill University.
%     http://www.stat.wisc.edu/~mchung/papers/thesis.pdf
%
% [2] Chung, M.K., Taylor, J. 2004. Diffusion Smoothing on Brain 
%     Surface via Finite Element Method,  IEEE International Symposium 
%     on Biomedical Imaging (ISBI). 432-435.
% 
% [3] Seo, S., Chung, M.K., Vorperian, H. K. 2010. Heat kernel smoothing 
%     using Laplace-Beltrami eigenfunctions,
%     Medical Image Computing and Computer-Assisted Intervention (MICCAI) 
%     2010, Lecture Notes in Computer Science (LNCS). 6363:505-512.
%     http://www.stat.wisc.edu/~mchung/papers/miccai.2010.seo.pdf
%
%
% Update history 
% Feb 1, 2009; Apr 23, 2010; Oct 1, 2010; Jun 26, 2011; July 16, 2011
%
% Bug report: mkchung@wisc.edu 


tri   = surf.faces;
coord = surf.vertices;
n = size(coord,1);

% OLD CODE
% It requires FINDnbr.m and FINDincidence.m
%
% n_vertex=max(max(tri));
% n_tri=size(tri,1);
% A=sparse(n_vertex,n_vertex); 
% C=sparse(n_vertex,n_vertex);  
% [nbr, degree] = FINDnbr(tri);
% inc = FINDincidence(tri);
% [I J] =find(inc);


%------------------------------
% Adjacency matrix
% The incidence matrix in the old code is the adjaency matrix

Adj = sparse(tri(:,[1 2 3]),tri(:,[2 3 1]),1,n,n);
Adj = double(Adj|Adj'); % adjacent nodes
[i,j] = find(Adj);  
[ei,ej] = find(Adj(:,i) & Adj(:,j)); % common adjacent triangle-edge
e1 = find([1; diff(ej)]); % 1:2:end  % ->ignors singularities
e2 = e1+1;                % 2:2:end

%------------------------------
% coordiantes of adjacent nodes and of common adjacent triangle-edge
pi = coord(i,:);
pj = coord(j,:);
qi = coord(ei(e1),:); % qi = coord(ei(1:2:end),:);
qj = coord(ei(e2),:); % qj = coord(ei(2:2:end),:);

% distances
dii = pi-qi; dij = pi-qj;
dji = pj-qi; djj = pj-qj;

norm = @(x) sqrt(sum(x.^2,2)); % norm of a vector

%------------------------------
% A matrix - area matrix
area = @(vi,vj) norm(cross(vi,vj))./2;
A = sparse(i,j,(area(dii,dji) + area(dij,djj))./12,n,n);
A = A + diag(sum(A,2));

% Old code:
%
% for i=1:length(I)
%     a= I(i);
%     b =J(i);
%     pi=coord(a,:);
%     pj=coord(b,:);
%     inter=intersect(nbr(a,1:degree(a)) , nbr(b,1:degree(b)));
% 
%     q1=coord(inter(1),:);
%     q2=coord(inter(2),:);
% 
%     p1 = pi-q1;
%     p2 = pj-q1;
%     q = cross(p1,p2);
%     Tminus=sqrt(q*q')/2;
% 
%     p1 = pi-q2;
%     p2 = pj-q2;
%     q = cross(p1,p2);
%     Tplus=sqrt(q*q')/2;
%     A(a,b)=(Tminus + Tplus)/12;
% end;
% for i=1:n_vertex
%     A(i,i)=sum(A(i,nbr(i,1:degree(i))));
% end;

%------------------------------
% C matrix - cotangent matrix
cotan = @(vi,vj) cot( acos(dot(vi,vj,2)./((norm(vi).*norm(vj))+eps)) );
C = sparse(i,j,-(cotan(dii,dji) + cotan(dij,djj))./2,n,n);
C = C - diag(sum(C,2));

% Old code
% for i=1:length(I)
%     a= I(i);
%     b =J(i);
%     pi=coord(a,:);
%     pj=coord(b,:);
%     inter=intersect(nbr(a,1:degree(a)) , nbr(b,1:degree(b)));
% 
%     q1=coord(inter(1),:);
%     q2=coord(inter(2),:);
% 
%     p1 = pi-q1;
%     p2 = pj-q1;
%     q = dot(p1,p2);
%     %theta= acos(q/(sum(sqrt(p1.^2))*sum(sqrt(p2.^2)))); %old incorrect code
%     theta = acos(q/(sqrt(sum(p1.^2))*sqrt(sum(p2.^2))));
%     
%     p1 = pi-q2;
%     p2 = pj-q2;
%     q = dot(p1,p2);
%     %phi= acos(q/(sum(sqrt(p1.^2))*sum(sqrt(p2.^2)))); %old incorrect code
%     phi = acos(q/(sqrt(sum(p1.^2))*sqrt(sum(p2.^2))));
%     
%     C(a,b)=-(1/tan(theta)+ 1/tan(phi))/2;
% end;
% 
% for i=1:n_vertex
%     C(i,i)=-sum(C(i,nbr(i,1:degree(i))));
% end;


