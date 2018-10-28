function fig = pop_eegbrowserx(EEG)
fig = [];
if ~isfield(EEG,'etc')
    disp('Cannot find src data structure, run pop_inverseSolution first.')
    return
end
if ~isfield(EEG.etc,'src')
    disp('Cannot find src data structure, run pop_inverseSolution first.')
    return
end
if ~isfield(EEG.etc.src,'actFull')
    disp('Cannot find src data structure, run pop_inverseSolution first.')
    return
end
fig = vis.EEGBrowserX(EEG);
end