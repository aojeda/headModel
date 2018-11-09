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
uimenu( hmMenu, 'label', 'Compute BEM forward model','callback','EEG = pop_forwardModel(EEG);');
uimenu( hmMenu, 'label', 'View head model','callback','hm=headModel.loadFromFile(EEG.etc.src.hmfile);hm.plot;');
uimenu( hmMenu, 'label', 'Documentation','callback','web(''https://github.com/aojeda/headModel'')');
