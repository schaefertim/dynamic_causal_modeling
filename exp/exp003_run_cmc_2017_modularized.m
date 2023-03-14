% Run my cmc_2017 model in a modularized way.
% In preparation of working on experimental synapse data.
addpath('dynamic_causal_modeling/')
addpath('cbrewer2/cbrewer2/'); addpath('28790/colorspace/');

% Model specification
%==========================================================================
spm('defaults', 'eeg')
rng('default')

[M, pE] = load_cmc_2017_and_priors();

%==========================================================================
% plots
%==========================================================================
% spm_figure('GetWin','Figure 1'); clf
n_param_step = 10;
% set colours - remove darkest ones from ends and lightest from middle
colormap = cbrewer2('div', 'RdBu', n_param_step+6);
colormap = colormap([2:n_param_step/2+1 n_param_step/2+6:n_param_step+6],:);
k     = linspace(log(0.7),0,n_param_step);  % e^-0.36 = 0.7 (30% decrease)
for j = 1:n_param_step
    for i_model = 1:5
        P        = pE;
        [M,P] = modify_cmc_2017(M,P,i_model,k(j));
        [freq, psd, psd_normalised, psd_fit] = spm_get_power_spectrum_and_normalization(M,P);
    
        %plot
        subplot(2,5,i_model)
        plot(freq,psd_normalised,'Color',colormap(j,:));
        xlabel('frequency')
        ylabel('normalised power (AU)')
        set(gca,'XLim',[0 80],'YLim',[-0.2 0.4]);
        title(sprintf('Model %d', i_model),'FontSize',16)
        axis square, hold on, set(gca,'XLim',[0 M.Hz(end)])

        subplot(2,5,i_model+5)
        plot(freq, psd, 'Color', colormap(j,:));
        plot(freq, psd_fit, 'Color', colormap(j,:));
        xlabel('frequency')
        ylabel('power')
        set(gca, 'YScale', 'log')
        set(gca, 'XScale', 'log')
        title(sprintf('Model %d', i_model),'FontSize',16)
        axis square, hold on, set(gca,'XLim',[0 M.Hz(end)])
    end
end
