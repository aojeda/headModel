function sVertices = smoothSurface(vertices,faces,lambda,method)
if nargin < 2, error('Not enough input arguments.');end
if nargin < 3, lambda = 0.2;end
if nargin < 4, method = 'lowpass';end

maxIter = 20;
N = size(vertices,1);

if isempty(which('meshresample'))
    warning('MoBILAB:noIso2Mesh','This function uses Iso2Mesh toolbox if is installed, you can download it for free fom: http://iso2mesh.sourceforge.net');
    sVertices = vertices;
    for it=1:N
        ind = any(faces==it,2);
        indices = faces(ind,:);
        indices = indices(:);
        indices(indices==it) = [];
        W = geometricTools.localGaussianInterpolator(vertices(indices,:),vertices(it,:),lambda);
        sVertices(it,:) = sum((1./W)*vertices(indices,:),1)./sum(1./W);
    end
    return;
end
conn = neighborelem(faces,size(vertices,1));
for it=1:N
    tmp = faces(conn{it},:);
    conn{it} = unique(tmp(:)');
end
sVertices = smoothsurf(vertices,[],conn,maxIter,lambda,method);
end
