% Induced responses simulation script - Rick Adams

% NB to get this script to run, you need spm_induced_optimise_RA and to
% change 'spm_fx_cmc' to 'spm_fx_cmc_2017_constG' in spm_dcm_x_neural (line 79) 

% PARAMETERS AND WHERE THEY ARE STORED - CMC_2017: synaptic parameters
%   pE  = spm_dcm_neural_priors({0 0 0},{},1,options.model);
%   pE.T - synaptic time constants
%   pE.S - activation function parameters
%   pE.G - intrinsic connection strengths:
%       index   coupling    type  strength  
%       G(:,1)  ss -> ss (-ve self)  4      
%%%     G(:,2)  sp -> ss (-ve rec )  4      %%% removed
%       G(:,3)  ii -> ss (-ve rec )  4   
%       G(:,4)  ii -> ii (-ve self)  4      
%       G(:,5)  ss -> ii (+ve rec )  4      
%       G(:,6)  dp -> ii (+ve rec )  2      
%       G(:,7)  sp -> sp (-ve self)  4      
%       G(:,8)  ss -> sp (+ve rec )  4      
%       G(:,9)  ii -> dp (-ve rec )  2      
%       G(:,10) dp -> dp (-ve self)  1(2)   
%       G(:,11) sp -> ii (+ve rec)   4(2)   
%       G(:,12) ii -> sp (-ve rec)   4      
%       G(:,13) sp -> dp (+ve rec)   4      %%% added
%--------------------------------------------------------------------------
% CMC: connectivity parameters-
%    pE.A - extrinsic
%    pE.B - trial-dependent (driving)
%    pE.N - trial-dependent (modulatory)
%    pE.C - stimulus input
%    pE.D - delays
% CMC: stimulus and noise parameters
%    pE.R - onset and dispersion
% other models' parameters 
%    pE.H - synaptic densities (for NMN and MFM)
%    pE.U - endogenous activity
% pE  = spm_L_priors(M.dipfit,pE);
% pE  = spm_ssr_priors(pE);
%    pE.a - neuronal innovations         - amplitude and exponent
%    pE.b - channel noise (non-specific) - amplitude and exponent
%    pE.c - channel noise (specific)     - amplitude and exponent
%    pE.d - neuronal innovations         - basis set coefficients

clear
% close all
dbstop if error

% Rick iMac/Macbook paths
cmcpath = '/Users/rickadams/Dropbox/Rick/Academic/Anticevic/Final_MPRC_Code';
spmpath = '/Users/rickadams/Code/SPM/spm12_v7219'; % v7219
funpath = '/Users/rickadams/Dropbox/Downloaded_functions';
Dimpath = '/Users/rickadams/Dropbox/Rick/Academic/Anticevic/codeDimitrisSSAEP40_v2';

%addpath(cmcpath, spmpath)
%addpath(genpath(funpath))
% addpath(Dimpath)        % NB will simulate SSAEP40 i.e. stimulation at 40 Hz
% rmpath(Dimpath)           % will simulate resting state (normal SPM version)
spm('defaults', 'eeg');

%% Set up parameters and model to use for simulation

model          = 'CMC';   % CMC (for CMC_2014/2017, edit spm_dcm_x_neural), ERP 
                          % (others: SEP, LFP, NNM, MFM)
syn_chng_all   = 0;       % proportion of ALL synapses lost...
syn_chng_group = -0.3;    % +/-ve change in proportion of specific synapses... 
                          %%% (NB needs to be opposite sign if conceiving self-inh as 'gain') %%%
P              = {'G'};   % ...in intrinsic (G) connections 
Ns             = 1;       % number of sources 
Nc             = 1;       % number of channels
D              = [];      % initialise D

% PARAMETERS FROM SPM_FX_CMC_2017
% -------------------------------------------------------------------------

pF.G = [4 4 4 4 4 2 4 4 2 1 4 4 4]*200.*(1+syn_chng_all); % intrinsic conn

figure
for sim = 1:5 % 5 models: each 'j' refers to a microcircuit connection (see 
              % top of script), n zeros in G mean the first n connections 
              % in 'j' are altered
    switch sim
        case 1
            j = [12 9 11 6 3 5 8 13  4 7 10 1];     % all connections
            G = [0  0 0  0 0 0 0 0];                
        case 2 
            j = [11 6 12 9 3 5 8 13  4 7 10 1];     % ii inputs
            G = [0  0 ];
        case 3
            j = [4 11 6 12 9 3 5 8 13  7 10 1];     % ii disinhibition
            G = [0  ];
        case 4
            syn_chng_group = abs(syn_chng_group);   % ii 'gain'
        case 5
            j = [7 4 11 6 12 9 3 5 8 13  10 1];     % sp 'gain'
            G = [0  ];
    end

% OTHER CMC PARAMETERS - standard settings
% -------------------------------------------------------------------------
pF.D(1) = 1;                    % intrinsic delays (ms) 
pF.D(2) = 8;                    % extrinsic delays (ms)
 
% number of regions in coupled map lattice (only one for rsEEG simulation)
M.dipfit.Nc     = Nc;    % no of channels
M.dipfit.Ns     = Ns;    % no of sources
options.spatial = 'LFP';
options.model   = upper(model);
M.dipfit.model  = options.model;
M.dipfit.type   = options.spatial;

% within-trial effects: adjust onset relative to pst (standard settings)
M.ns = 64; M.ons = 64; M.dur = 16; U.dt = 1/256;

% specify network (connections)
if Ns > 1
    A{1}  = diag(ones(Ns - 1,1),-1);
    A{2}  = A{1}';
    A{3}  = sparse(Ns,Ns);
    B     = {};
    C     = sparse(1,1,1,Ns,1);
else
    A = {1 1 1};
    B     = {};
    C = 1;
end

% add standard priors for model
pE   = spm_dcm_neural_priors(A,B,C,options.model);
pE   = spm_L_priors(M.dipfit,pE);
pE   = spm_ssr_priors(pE);

pE.G = G; % correct number of intrinsic parameters to be modulated

%% Run model

spm_induced_optimise_RA(pE,M,U,pF,j,syn_chng_all,syn_chng_group,P,D,sim)

end