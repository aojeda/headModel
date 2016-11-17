%%
S = headModel.loadFromFile('/home/ale/Downloads/head_modelColin27_4825_Standard-10-5-Cap339.mat');
filenames = pickfiles('/home/ale/Projects/online-source-connectivity/dependency/headModel/resources',{'10-5-Cap346.mat'});
results = '/home/ale/Projects/online-source-connectivity/dependency/headModel/resources/new';
options = struct('Verbose',true,'MaxRef',2);

%%
for k=1:size(filenames)
    T = headModel.loadFromFile(deblank(filenames(k,:)));

    [Aff,Sn] = geometricTools.affineMapping(S.scalp.vertices,T.scalp.vertices);
    T.channelSpace = geometricTools.applyAffineMapping(S.channelSpace,Aff);
    channelSpace = geometricTools.nearestNeighbor(T.channelSpace,T.scalp.vertices);
    [Def,spacing,offset] = geometricTools.bSplineMapping(T.channelSpace,channelSpace,T.scalp.vertices,options);
    T.channelSpace = geometricTools.applyBSplineMapping(Def,spacing,offset,T.channelSpace);
    
    [newno,newfc]=remeshsurf(T.scalp.vertices,T.scalp.faces,0.0025);
    newno = bsxfun(@plus,newno,max(T.scalp.vertices)-max(newno));
    T.channelSpace = geometricTools.nearestNeighbor(T.channelSpace,newno);
    T.labels = S.labels;
    
    T.computeLeadFieldBEM([0.33 0.022 0.33],false);
    n = sqrt(sum(T.K.^2))'; % figure;hist(n,500);T.plotOnModel(n)
    th = median(n)-prctile(n,30);
    if sum(n<th) > 0 && sum(n<th) < 100
        indices_interp = find(n<th);
        indices = setdiff(1:length(n),indices_interp);
        T.K(:,indices_interp) = geometricTools.scatterInterpolator(T.cortex.vertices(indices,:),...
            T.K(:,indices)',T.cortex.vertices(indices_interp,:))';
        do_repare = true;
    else
        do_repare = false;
    end
    T.saveToFile(fullfile(results,['head_modelColin27_' num2str(size(T.cortex.vertices,1)) '_Standard-10-5-Cap' num2str(size(T.channelSpace,1)) '.mat']))
    
    T.computeLeadFieldBEM([0.33 0.022 0.33],true);
    n = sqrt(sum(T.K.^2))'; % figure;hist(n,500);T.plotOnModel(n)
    th = median(n)-prctile(n,30);
    if do_repare
        dim = size(T.K);
        K = reshape(T.K,[dim(1) size(T.cortex.vertices,1),3]);
        for c=1:3
            K(:,indices_interp,c) = geometricTools.scatterInterpolator(T.cortex.vertices(indices,:),...
                K(:,indices,c)',T.cortex.vertices(indices_interp,:))';
        end
        T.K = reshape(K,dim);
    end
    T.saveToFile(fullfile(results,['head_modelColin27_' num2str(size(T.cortex.vertices,1)) '_xyz_Standard-10-5-Cap' num2str(size(T.channelSpace,1)) '.mat']))
end
%%
clear all
results = '/home/ale/Projects/online-source-connectivity/dependency/headModel/resources/new';
filenames = pickfiles(results,'.mat');
for k=1:size(filenames,1)
    hm = headModel.loadFromFile(deblank(filenames(k,:)));
    n = sqrt(sum(hm.K.^2))'; 
    h = figure;hist(n,500);
    hm.plotOnModel(n);
    waitfor(h);
end