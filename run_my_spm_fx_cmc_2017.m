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
p     = 16;                                      % autoregression order
options = struct();
options.spatial  = 'LFP';                        % level field potentials
options.model    = 'CMC';                        % canonical microcircuit
% options.analysis = 'CSD';                        % Cross spectral density
M.dipfit.model = options.model;
M.dipfit.type  = options.spatial;
M.dipfit.Nc    = Nc;
M.dipfit.Ns    = Ns;
M.pF.D         = [1]; %[1 4];                          % change conduction delays
 
% extrinsic connections (forward an backward)
%--------------------------------------------------------------------------
A{1} = [0]; % 0; 0 0];
A{2} = [0]; % 0; 0 0];
A{3} = [0]; % 0; 0 0];
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
pE.a(1,:) = -2;
pE.b(1,:) = -8;
pE.c(1,:) = -8;

 
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
M.Rft = 4;


% specify M.u - endogenous input (fluctuations) and intial states
%--------------------------------------------------------------------------
M.u   = sparse(Ns,1);
 
% solve for steady state
%--------------------------------------------------------------------------
M.x   = spm_dcm_neural_x(pE,M);


%==========================================================================
% my own plots
%==========================================================================
spm_figure('GetWin','Figure 1'); clf
k     = linspace(-0.36,0,2);                       % log scaling range
for j = 1:length(k)
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
    
        [csd,freq] = spm_csd_mtf(P,M);
        csd = csd{1};
    
    
        spm_figure('GetWin','Figure 1');
    
        subplot(1,5,i_model)
        plot(freq, real(csd(:,1,1)));
        xlabel('frequency')
        ylabel('power')
        title(sprintf('Model %d', i_model),'FontSize',16)
        axis square, hold on, set(gca,'XLim',[0 Hz(end)])
    end

end

%==========================================================================
return
%==========================================================================


% evaluate expected Granger causality while changing intrinsic connectivity
% see spm_fx_cmc for details about each parameter is changed
%==========================================================================
spm_figure('GetWin','Figure 1'); clf
k     = linspace(-2,0,8);                       % log scaling range
for j = 1:length(k)
    
    
    % amplitude of observation noise
    %----------------------------------------------------------------------
    P        = pE;
    P.G(1,:) = k(j);
       
    % create forward model and solve for steady state
    %----------------------------------------------------------------------
    M.x      = spm_dcm_neural_x(P,M);
    
    % Analytic spectral chararacterisation (parametric)
    %======================================================================
    [csd,Hz] = spm_csd_mtf(P,M);
    ccf      = spm_csd2ccf(csd{1},Hz,dt);
    mar      = spm_ccf2mar(ccf,p);
    mar      = spm_mar_spectra(mar,Hz,ns);
    
    % and non-parametric
    %======================================================================
    gew      = spm_csd2gew(csd{1},Hz);
    
    % save forwards and backwards functions
    %----------------------------------------------------------------------
    GCF(:,j) = abs(gew(:,2,1));
    GCB(:,j) = abs(gew(:,1,2));
    
    % plot forwards and backwards Granger causality (parametric)
    %----------------------------------------------------------------------
    spm_figure('GetWin','Figure 1');
    
    subplot(3,2,1)
    plot(Hz,abs(mar.gew(:,2,1)))
    xlabel('frequency')
    ylabel('absolute value')
    title('forward (MAR)','FontSize',16)
    axis square, hold on, set(gca,'XLim',[0 Hz(end)])
    
    subplot(3,2,2)
    plot(Hz,abs(mar.gew(:,1,2)))
    xlabel('frequency')
    ylabel('absolute value')
    title('backward (MAR)','FontSize',16)
    axis square, hold on, set(gca,'XLim',[0 Hz(end)])

    % plot forwards and backwards Granger causality (non-parametric)
    %----------------------------------------------------------------------
    subplot(3,2,3)
    plot(Hz,abs(gew(:,2,1)))
    xlabel('frequency')
    ylabel('absolute value')
    title('forward (Wilson-Burg) ','FontSize',16)
    axis square, hold on, set(gca,'XLim',[0 Hz(end)])

    
    subplot(3,2,4)
    plot(Hz,abs(gew(:,1,2)))
    xlabel('frequency')
    ylabel('absolute value')
    title('backward (Wilson-Burg)','FontSize',16)
    axis square, hold on, set(gca,'XLim',[0 Hz(end)])

    
end

subplot(3,2,5)
imagesc(Hz,k,GCF')
xlabel('frequency')
ylabel('log(exponent)')
title('forward','FontSize',16)
axis square

subplot(3,2,6)
imagesc(Hz,k,GCB')
xlabel('frequency')
ylabel('log(exponent)')
title('backward','FontSize',16)
axis square

% plot forward and backward and backward causality against each other
%--------------------------------------------------------------------------
spm_figure('GetWin','Figure 2'); clf

subplot(2,1,1)
plot(GCB(12,:),GCF(60,:),':',GCB(12,:),GCF(60,:),'o')
xlabel('backward Granger causality 12 Hz')
ylabel('forward Granger causality 60 Hz')
title('forward and backward Granger causality','FontSize',16)
axis square

return


% timeseries simulation and spectral density estimation
%==========================================================================

% expected cross spectral density
%--------------------------------------------------------------------------
csd       = spm_csd_mtf(pE,M);

% Get spectral profile of fluctuations and noise
%--------------------------------------------------------------------------
[Gu,Gs,Gn] = spm_csd_mtf_gu(pE,Hz);

% Integrate with power law process (simulate multiple trials)
%--------------------------------------------------------------------------
PSD   = 0;
CSD   = 0;
N     = 1024;
U.dt  = dt;
for t = 1:16
    
    % neuronal fluctuations
    %----------------------------------------------------------------------
    U.u      = spm_rand_power_law(Gu,Hz,dt,N);
    LFP      = spm_int_L(pE,M,U);
    
    % and measurement noise
    %----------------------------------------------------------------------
    En       = spm_rand_power_law(Gn,Hz,dt,N);
    Es       = spm_rand_power_law(Gs,Hz,dt,N);
    E        = Es + En*ones(1,Ns);
    
    % and estimate spectral features under a MAR model
    %----------------------------------------------------------------------
    MAR      = spm_mar(LFP + E,p);
    MAR      = spm_mar_spectra(MAR,Hz,ns);
    CSD      = CSD + MAR.P;
    
    % and using Welch's method
    %----------------------------------------------------------------------
    PSD      = PSD + spm_csd(LFP + E,Hz,ns);
    
    CCD(:,t) = abs(CSD(:,1,2)/t);
    PCD(:,t) = abs(CSD(:,1,1)/t);
   
    % plot
    %----------------------------------------------------------------------
    spm_figure('GetWin','Figure 3'); clf
    spm_spectral_plot(Hz,csd{1},'r',  'frequency','density')
    spm_spectral_plot(Hz,CSD/t, 'b',  'frequency','density')
    spm_spectral_plot(Hz,PSD/t, 'g',  'frequency','density')
    legend('real','estimated (AR)','estimated (CSD)')
    drawnow
    
end

%  show convergence of spectral estimators
%--------------------------------------------------------------------------
subplot(2,2,3), hold off
imagesc(Hz,1:t,log(PCD'))
xlabel('frequency')
ylabel('trial number')
title('log auto spectra','FontSize',16)
axis square

subplot(2,2,4), hold off
imagesc(Hz,1:t,log(CCD'))
xlabel('frequency')
ylabel('trial number')
title('log cross spectra','FontSize',16)
axis square
