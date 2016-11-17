addpath(genpath('/home/ale/Projects/online-source-connectivity'))

cortex_high = '/home/ale/Projects/online-source-connectivity/results/tess_cortex_pial_high_warped.mat';
content = load(cortex_high);
resources = '/home/ale/Projects/online-source-connectivity/dependency/headModel/resources';
files = pickfiles(resources,'head_model');

for f=1:size(files,1);
    hm = headModel.loadFromFile(deblank(files(f,:)));
    
    ind = [];
    colorTable = [];
    label = {};
    region = [];
    for k=1:length(content.Atlas(11).Scouts)
        ind = [ind content.Atlas(11).Scouts(k).Vertices];
        colorTable = [colorTable k*ones(1,length(content.Atlas(11).Scouts(k).Vertices))];
        label{end+1} = content.Atlas(11).Scouts(k).Label;
        region{end+1} = content.Atlas(11).Scouts(k).Region;
    end
    
    F = scatteredInterpolant(content.Vertices(ind,:),colorTable','nearest');
    ct = F(hm.cortex.vertices);
    atlas = hm.atlas;
    atlas.colorTable = ct;
    atlas.label = label';
    atlas.region = region';
    atlas.name = content.Atlas(11).Name;
    % plot(hm)
    [fpath,fname] = fileparts(files(f,:));
    save(fullfile(fpath,[fname '_Atlas_' content.Atlas(11).Name '.mat']),'atlas');
end