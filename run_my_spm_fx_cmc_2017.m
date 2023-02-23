% function run_my_spm_fx_cmc_2017
% Test run canonical microcircuit
%
% Code copied from run_spm_fx_cmc_2014 and then modified.

% Model specification
%==========================================================================
rng('default')
 
% number of regions
%--------------------------------------------------------------------------
Nc    = 1;%2;                                       % number of channels
Ns    = 1;%2;                                       % number of sources
ns    = 2*96;                                   % sampling frequency
dt    = 1/ns;                                    % time bins
Hz    = 1:(ns/2);                                % frequency
% p     = 16;                                      % autoregression order
options = struct();
options.spatial  = 'LFP';                        % level field potentials
options.model    = 'CMC';                        % canonical microcircuit
% options.analysis = 'CSD';                        % Cross spectral density
%M.dipfit.model = options.model;
%M.dipfit.type  = options.spatial;
%M.dipfit.Nc    = Nc;
%M.dipfit.Ns    = Ns;
M.pF.D         = [1 8]; %[1 4];                          % change conduction delays
 
% extrinsic connections (forward an backward)
%--------------------------------------------------------------------------
A{1} = 0; % [0 0; 0 0];
A{2} = 0; % [0 0; 0 0];
A{3} = 0; % [0 0; 0 0];
B    = {};
C    = sparse(1,0); % sparse(2,0);
 
% get priors
%--------------------------------------------------------------------------
pE    = spm_dcm_neural_priors(A,B,C,options.model);
pE    = spm_L_priors(M.dipfit,pE);
pE    = spm_ssr_priors(pE);
x     = spm_dcm_x_neural(pE,options.model);

% (log) connectivity parameters
%--------------------------------------------------------------------------
% pE.A{1}(2,1) = 2;                              % forward connections
% pE.A{3}(1,2) = 1;                              % backward connections
pE.S         = 1/8;

% (log) amplitude of fluctations and noise
%--------------------------------------------------------------------------
%pE.a(1,:) = -2;
%pE.b(1,:) = -8;
%pE.c(1,:) = -8;

 
% orders and model
%==========================================================================
nx    = length(spm_vec(x));
 
% create forward model
%--------------------------------------------------------------------------
M.f   = 'my_spm_fx_cmc_2017';
M.g   = 'spm_gx_erp';
M.x   = x;
M.n   = nx;
M.pE  = pE;
M.m   = Ns;
M.l   = Nc;
M.Hz  = Hz;
% M.Rft = 4;


% specify M.u - endogenous input (fluctuations) and intial states
%--------------------------------------------------------------------------
M.u   = sparse(Ns,1);
 
% solve for steady state
%--------------------------------------------------------------------------
M.x   = spm_dcm_neural_x(pE,M);


%==========================================================================
% my own plots
%==========================================================================
% spm_figure('GetWin','Figure 1'); clf
n_param_step = 10;
colors = colormap(jet(n_param_step));
k     = linspace(0,-0.36,n_param_step);  % e^-0.36 = 0.7 (30% decrease)
for j = 1:n_param_step
    for i_model = 1:5
        % amplitude of observation noise
        %----------------------------------------------------------------------
        P        = pE;

        switch(i_model)
            case 1
                P.G(1,1) = k(j);    % G12: ii->sp
                P.G(1,2) = k(j);    % G9:  ii->dp
                P.G(1,6) = k(j);    % G13: sp->dp
                P.G(1,7) = k(j);    % G3:  ii->ss
                P.G(1,8) = k(j);    % G5:  ss->ii
                P.G(1,9) = k(j);    % G6:  dp->ii
                P.G(1,10) = k(j);   % G8:  ss->sp
                P.G(1,12) = k(j);   % G11: sp->ii
            case 2        
                P.G(1,9) = k(j);    % G6:  dp->ii
                P.G(1,12) = k(j);   % G11: sp->ii
            case 3
                P.G(1,4) = k(j);    % G4: ii->ii
            case 4
                P.G(1,4) = -k(j);    % G4: ii->ii
            case 5
                P.G(1,3) = -k(j);
        end

        % create forward model and solve for steady state
        %----------------------------------------------------------------------
        M.x = spm_dcm_neural_x(P,M);
    
        % M.u = sparse(1,size(pE.C,2));
        [csd,freq] = spm_csd_mtf(P,M);
        csd = csd{1};
        psd = abs(csd(:,1,1));

        % normalise like described in Adams et al., 2022, supplement, p.8
        % subtract 1/f noise
        b = robustfit(log(freq), log(psd));
        psd_fit = exp(b(1) + b(2) * log(freq));
        psd_normalised = log10(psd) - log10(psd_fit.');
    
        subplot(1,5,i_model)
        plot(freq, psd_normalised, 'Color', colors(j,:));
        xlabel('frequency')
        ylabel('normalised power (AU)')
        title(sprintf('Model %d', i_model),'FontSize',16)
        axis square, hold on, set(gca,'XLim',[0 Hz(end)])
    end
end
