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

function eegplugin_headModel(fig,try_strings, catch_strings)
p = fileparts(which('eeglab'));
p = fullfile(p, 'plugins', 'headModel');
addpath(genpath(p));

h = findobj(gcf, 'tag', 'tools');
hmMenu = uimenu( h, 'label', 'headModel');
uimenu( hmMenu, 'label', 'Surface-based (BEM) forward modeling','callback','EEG = pop_forwardModel(EEG);');
uimenu( hmMenu, 'label', 'Inverse source estimation (LORETA)','callback','EEG = pop_inverseSolution(EEG);');
