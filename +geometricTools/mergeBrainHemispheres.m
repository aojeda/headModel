function fv = mergeBrainHemispheres(fv1,fv2)
fv = struct('vertices',[fv1.vertices;fv2.vertices],'faces',...
    [fv1.faces;fv2.faces+size(fv1.vertices,1)]);
end