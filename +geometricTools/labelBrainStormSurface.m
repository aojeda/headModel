function labels = labelBrainStormSurface(vertices,faces,atlasFileNii)
if ~exist('spm_vol','file')
    error('This function needs SPM (http://www.fil.ion.ucl.ac.uk/spm/software/spm12/)')
end
V = spm_vol(atlasFileNii);
mri = load('bs_mri.mat');
mri.Cube = spm_read_vols(V);
d = abs(diag(V.mat));
mri.Voxsize = d(1:3)';
vox = cs_convert(mri, 'scs', 'voxel', vertices);
[x,y,z] = ndgrid(1:V.dim(1),1:V.dim(2),1:V.dim(3));
xyz = [x(:) y(:) z(:)];
F = scatteredInterpolant(xyz,mri.Cube(:),'nearest');
labels = F(vox);
ind = find(labels==0);
coord = round(vox(ind,:));
hwait = waitbar(0,'Correcting mislabeled vertices...');
for k=1:length(ind)
    nei = any(faces == ind(k),2);
    nei = faces(nei,:);
    nei = setdiff(nei(:),ind(k));
    val = F(vox(nei,:));
    val = nonzeros(val);
    if ~isempty(val)
        nelem = hist(val,length(val));
        [~,loc] = max(nelem);
        labels(ind(k)) = val(loc);
    else
        for h=1:10
            nei = -h:h;
            val = mri.Cube(coord(k,1)+nei,coord(k,2)+nei,coord(k,3)+nei);
            val = nonzeros(val(:));
            if ~isempty(val)
                nelem = hist(val,length(val));
                [~,loc] = max(nelem);
                labels(ind(k)) = val(loc);
                break
            end
        end
    end
    waitbar(k/length(ind),hwait);
end
close(hwait);
end
