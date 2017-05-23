function atlas = labelSurface(Surf,imgAtlasfile, txtAtlasLabel,maxColorValue)
if nargin < 4, maxColorValue = 90;end
% Atlas
v =spm_vol(imgAtlasfile); % atlas
A = spm_read_vols(v);
A(A>maxColorValue) = 0;
indNonZero = A(:)~=0;
A(isnan(A(:))) = 0;
A(:,:,1) = 0;
A(:,1,:) = 0;
A(1,:,:) = 0;
colorTable = A(indNonZero);
[x,y,z] = ndgrid(1:v.dim(1),1:v.dim(2),1:v.dim(3));
M = v.mat;
X = [x(:) y(:) z(:) ones(numel(x),1)]*M';
X = X(indNonZero,1:3);
clear x y z
F = scatteredInterpolant(X,colorTable,'nearest');
n = size(Surf.vertices,1);
labelsValue = F(Surf.vertices);
colorTable = labelsValue;
hwait = waitbar(0,'Atlas correction...');
for it=1:n
    neigInd = any(Surf.faces == it,2);
    vertexInedex = Surf.faces(neigInd,:);
    vertexInedex = vertexInedex(:);
    [y,x] = hist(labelsValue(vertexInedex));
    [~,loc] = max(y);
    [~,loc] = min(abs(labelsValue(vertexInedex) - x(loc)));
    labelsValue(it) = colorTable(vertexInedex(loc));
    waitbar(it/n,hwait);
end
waitbar(1,hwait);
close(hwait);
atlas.colorTable = labelsValue;
if ~iscellstr(txtAtlasLabel)
    atlas.label = textfile2cell(txtAtlasLabel);
    atlas.label = atlas.label(1:max(atlas.colorTable));
    for it=1:length(atlas.label)
        ind = find(atlas.label{it} == ' ');
        atlas.label{it} = atlas.label{it}(ind(1)+1:ind(end)-1);
    end
else
    atlas.label = txtAtlasLabel;
end

end
