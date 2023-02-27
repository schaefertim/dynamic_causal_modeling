% function run_my_spm_fx_cmc_2017
% Test run canonical microcircuit
%
% Code copied from run_spm_fx_cmc_2014 and then modified.

addpath('dynamic_causal_modeling/')
addpath('cbrewer2/cbrewer2/')
% spm default
spm('defaults', 'eeg')

% Model specification
%==========================================================================
rng('default')
 
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
M.Hz  = 2:96;

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
% set colours - remove darkest ones from ends and lightest from middle
colormap = cbrewer2('div', 'RdBu', n_param_step+6);
colormap = colormap([2:n_param_step/2+1 n_param_step/2+6:n_param_step+6],:);
k     = linspace(-0.36,0,n_param_step);  % e^-0.36 = 0.7 (30% decrease)
for j = 1:n_param_step
    for i_model = 1:5
        % amplitude of observation noise
        %------------------------------------------------------------------
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
                P.G(1,4) = k(j);    % G4:  ii->ii
            case 4
                P.G(1,4) = -k(j);   % G4:  ii->ii
            case 5
                P.G(1,3) = -k(j);   % G7:  sp->sp
        end

        % create forward model and solve for steady state
        %------------------------------------------------------------------
        M.x = spm_dcm_neural_x(P,M);
    
        % M.u = sparse(1,size(pE.C,2));
        [csd,freq] = spm_csd_mtf(P,M);
        csd = csd{1};
        psd = abs(csd(:,1,1));

        % normalise like described in Adams et al., 2022, supplement, p.8
        % subtract 1/f noise
        freq_fit_low = 2;
        freq_selection = freq >= freq_fit_low;
        b = robustfit(log(freq(freq_selection)), log(psd(freq_selection)));
        psd_fit = exp(b(1) + b(2) * log(freq));
        psd_normalised = log10(psd) - log10(psd_fit.');
    
        subplot(2,5,i_model)
        plot(freq(freq_selection), psd_normalised(freq_selection), ...
            'Color', colormap(j,:));
        xlabel('frequency')
        ylabel('normalised power (AU)')
        set(gca,'XLim',[0 80],'YLim',[-0.2 0.4]);
        title(sprintf('Model %d', i_model),'FontSize',16)
        axis square, hold on, set(gca,'XLim',[0 M.Hz(end)])

        subplot(2,5,i_model+5)
        plot(freq, psd, 'Color', colormap(j,:));
        xlabel('frequency')
        ylabel('power')
        set(gca, 'YScale', 'log')
        set(gca, 'XScale', 'log')
        title(sprintf('Model %d', i_model),'FontSize',16)
        axis square, hold on, set(gca,'XLim',[0 M.Hz(end)])
    end
end
