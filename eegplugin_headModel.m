% eegplugin_headModel() - Head model plugin for surface-based forward and inverse source modelin of EEG data.
% Usage:
%   >> eegplugin_headModel(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer] eeglab figure.
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks.
%
% Author: Alejandro Ojeda, SCCN, INC, UCSD, 2013
%
% See also: eeglab()

function vers = eegplugin_headModel(fig,try_strings, catch_strings)
vers = 'headModel1.0.2';
p = fileparts(which('eegplugin_headModel'));
addpath(genpath(p));

h = findobj(gcf, 'tag', 'tools');
hmMenu = uimenu( h, 'label', 'headModel');
uimenu( hmMenu, 'label', 'Surface-based (BEM) forward modeling','callback','EEG = pop_forwardModel(EEG);');
uimenu( hmMenu, 'label', 'Inverse source estimation','callback','EEG = pop_inverseSolution(EEG);');
uimenu( hmMenu, 'label', 'Move ROI source estimates to EEG.data','callback','try,EEG = moveSource2DataField(EEG);[ALLEEG EEG CURRENTSET]=eeg_store(ALLEEG, EEG);eeglab redraw;catch e, errordlg(e.message);end');
uimenu( hmMenu, 'label', 'Documentation','callback','web(''https://github.com/aojeda/headModel'')');
