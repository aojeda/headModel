function plotMaxView(hm, x)
r = 100;

dx = 1*[min(hm.cortex.vertices(:,1)) max(hm.cortex.vertices(:,1))];
dy = 1*[min(hm.cortex.vertices(:,2)) max(hm.cortex.vertices(:,2))];
dz = 1*[min(hm.cortex.vertices(:,3)) max(hm.cortex.vertices(:,3))];
[X,Y,Z] = ndgrid(linspace(dx(1),dx(2),r),linspace(dy(1),dy(2),r),linspace(dz(1),dz(2),r));

Fb = scatteredInterpolant(hm.cortex.vertices(:,1), hm.cortex.vertices(:,2), hm.cortex.vertices(:,3), ones(size(hm.cortex.vertices,1),1),'nearest','none');
Bg = Fb(X(:),Y(:),Z(:));
Bg = reshape(Bg,size(X));
Bg(isnan(Bg)) = 0;

F = scatteredInterpolant(hm.cortex.vertices(:,1), hm.cortex.vertices(:,2), hm.cortex.vertices(:,3), x, 'natural','none');
I = F(X(:),Y(:),Z(:));
I = reshape(I,size(X));
I(isnan(I)) = 0;
mx = max(abs(I(:)));

fig = figure;
fig.Position(3:4) = [882 318];
cmap = bipolar(256,0.65);

% axial
ax = subplot(131);
bg = squeeze(sum(Bg,3));
img = squeeze(max(I,[],3));
bg(bg~=0) = 1;
imagesc(img,'AlphaData',bg);axis vis3d
title('Axial')
ax.YTick = [];
ax.XTick = ax.XTick([1 end-1]);
ax.XTickLabel = {'R','L'};
view(-180,90);
colormap(cmap)

% sagittal
ax = subplot(132);
bg = squeeze(sum(Bg,2));
img = squeeze(max(I,[],2));
bg(bg~=0) = 1;
imagesc(img,'AlphaData',bg);axis vis3d
title(sprintf('Maximal Projection Views\nSagittal'))
ax.XTick = [];
ax.YTick = ax.YTick([1 end-1]);
ax.YTickLabel = {'P','A'};
view(-90,90);
colormap(cmap)

% coronal
ax = subplot(133);
bg = squeeze(sum(Bg,1));
img = squeeze(max(I,[],1));
bg(bg~=0) = 1;
imagesc(img,'AlphaData',bg);axis vis3d
title('Coronal')
ax.XTick = [];
ax.YTick = ax.YTick([1 end-1]);
ax.YTickLabel = {'R','L'};
view(90,-90);
colormap(cmap)

set(findobj(fig,'Type','axes'),'CLim',[-mx mx])
colorbar(ax, 'Position',[0.9352    0.2201    0.0161    0.595],'TickLabels',{'Min' '0' 'Max'},'Ticks',[-0.9*mx  0  0.9*mx]);
end
