function [M,pE] = load_cmc_2017_and_priors()
%LOAD_CMC_2017_AND_PRIORS loads 'my_spm_fx_cmc_2017' model and priors

% number of regions
%--------------------------------------------------------------------------
Nc    = 1;                                       % number of channels
Ns    = 1;                                       % number of sources
options = struct();
options.spatial  = 'LFP';                        % level field potentials
options.model    = 'CMC';                        % canonical microcircuit
M.dipfit.model = options.model;
M.dipfit.type  = options.spatial;
M.dipfit.Nc    = Nc;
M.dipfit.Ns    = Ns;
M.pF.D         = [1 8];                          % change conduction delays
M.nodelay      = 0;

% get priors
%--------------------------------------------------------------------------
%pE    = spm_dcm_neural_priors(A,B,C,options.model);
pE    = spm_dcm_neural_priors({0 0 0},{},0,options.model);
pE    = spm_L_priors(M.dipfit,pE);
pE    = spm_ssr_priors(pE);
x     = spm_dcm_x_neural(pE,options.model);
 
% orders and model
%==========================================================================
 
% create forward model
%--------------------------------------------------------------------------
M.f   = 'my_spm_fx_cmc_2017';
M.g   = 'spm_gx_erp';
M.x   = x;
M.n   = length(spm_vec(x));
M.pE  = pE;
M.m   = Ns;
M.l   = Nc;
M.Hz  = 4:96;

% specify M.u - endogenous input (fluctuations) and intial states
%--------------------------------------------------------------------------
M.u   = sparse(Ns,1);
 
% solve for steady state
%--------------------------------------------------------------------------
M.x   = spm_dcm_neural_x(pE,M);
end

