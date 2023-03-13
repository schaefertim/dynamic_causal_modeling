function spm_induced_optimise_RA(pE,M,U,pF,j,syn_chng_all,syn_chng_group,P,D,pl)
% Demo routine that computes transfer functions for free parameters
%==========================================================================
%
% This an exploratory routine that computes the modulation transfer function
% for a range of parameters and states to enable the spectral responses to 
% be optimised with respect to the model parameters of neural mass models 
% under different hidden states.
%
% By editing the script, one can change the neuronal model or the hidden
% neuronal states that are characterised in terms of induced responses
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
 
% Karl Friston
% $Id: spm_induced_optimise.m 6937 2016-11-20 12:30:40Z karl $

% Rick Adams' changes to spm_induced_optimise (& other SPM code):
%--------------------------------------------------------------------------
% added pF to adjust model parameters together
% added j to specify which parameters to alter individually
% added syn_chng_all and syn_chng_group
% commented out D = 2 and made D adjustable
% moved P specification to script that calls this one
% altered  dQ = linspace(Q(i,j) - D,Q(i,j) + D,32); 
% moved model specifications into parent script
% created spm_fx_cmc_2017 as in Shaw et al (2017)'s sp->dp instead of ss
% (also added constant G parameters in every area - but this is not used 
% for simulations which involve only one area)
% changed spm_fx_cmc to spm_fx_cmc_2017_constG in spm_dcm_x_neural (line 79) 
% check lines 59 & 61 in spm_fx_erp (G and H) are correct & not swapped

% load model parameters and G connections to be changed
try M.pF   = pF; end
try M.cmcj = j;  end
     
% hidden neuronal states of interest
%--------------------------------------------------------------------------
[x,f]   = spm_dcm_x_neural(pE,M.dipfit.model);
 
% orders and model
%==========================================================================
nx      = length(spm_vec(x));
nu      = size(pE.C,2);
u       = sparse(1,nu);
 
% create LFP model
%--------------------------------------------------------------------------
M.f     = 'spm_fx_cmc_2017_constG';
M.g     = 'spm_gx_erp';
M.x     = x;
M.n     = nx;
M.pE    = pE;
M.m     = nu;
M.l     = M.dipfit.Nc;
 
% solve for steady state
%--------------------------------------------------------------------------
M.x     = spm_dcm_neural_x(pE,M);
 

% Dependency on parameters in terms of Modulation transfer functions
%==========================================================================
M.u     = u;
M.Hz    = 4:96; % 4:0.25:96 for smoother plot

% compute transfer functions for different parameters
%--------------------------------------------------------------------------
iplot = 1;
ifig  = 1;

% NEW: >1 params are changing
%--------------------------------------------------------------------------
if syn_chng_group ~= 0  
    
    % line search (with solution for steady state)
    %----------------------------------------------------------
    D  = -log(1+syn_chng_group); % overwrite D if using a group of params
    dQ = linspace(0 - D,0,10);
    
    for q = 1:length(dQ)
        qE      = pE;
        M.pF    = pF;
        % CMC: change specified group of intrinsic parameters all at once
        if any(strcmp(P, 'G')) && any(M.dipfit.model == 'CMC')
            qE      = setfield(qE,'G',{1,1:length(pE.G)},dQ(q));
        end
        % CMC: change extrinsic parameters all at once
        if any(strcmp(P, 'E')) && any(M.dipfit.model == 'CMC')
            M.pF.E   = M.pF.E*exp(dQ(q));
        end
        [G,w]   = spm_csd_mtf(qE,M,[]);
        if      M.dipfit.Ns == 1
            GW(:,q) = G{1};
        elseif  M.dipfit.Ns == 2
            GWCSD(:,:,:,q) = G{1};
            GW(:,q) = squeeze(GWCSD(:,1,2,q)); % source(s) to plot CSD for (1,1 1,2 2,2)
        end
    end
    
    % title for plot
    if any(strcmp(P, 'G')) && any(strcmp(P, 'E')) && any(M.dipfit.model == 'CMC')
        title_text = [num2str(syn_chng_all*100) '% change in all synapses, & further ' ...
                num2str(syn_chng_group*100) '% loss in all E & G(' num2str(M.cmcj(1:length(pE.G))) ')'];
    elseif any(strcmp(P, 'G')) && any(M.dipfit.model == 'CMC')
        title_text = [num2str(syn_chng_all*100) '% change in all synapses, & further ' ...
                num2str(syn_chng_group*100) '% change in G(' num2str(M.cmcj(1:length(pE.G))) ')'];
    elseif any(strcmp(P, 'E')) && any(M.dipfit.model == 'CMC')
        title_text = [num2str(syn_chng_all*100) '% change in all synapses, & further ' ...
                num2str(syn_chng_group*100) '% loss in all E'];
    elseif any(strcmp(P, 'G')) && any(M.dipfit.model == 'ERP')
        title_text = [num2str(syn_chng_all*100) '% change in all synapses, & further ' ...
                num2str(syn_chng_group*100) '% change in G(' num2str(M.cmcj) ')'];
    end
    
    % plot
    %----------------------------------------------------------
    
    % compute and plot normalised (pre-whitened) data
    subplot(2,5,pl)
    for gw = 1:size(GW,2)
        try % fit gradient+intercept to log-log plot and subtract them
            [robfit] = robustfit(log10(w),log10(abs(GW(:,gw))),'bisquare');
            norm_GW(:,gw) = log10(abs(GW(:,gw)))-(robfit(1)+robfit(2)*log10(w))';
            clear robfit
        end
    end
    
    % set colours - remove darkest ones from ends and lightest from middle
    [colormap]=cbrewer2('div', 'RdBu', size(GW,2)+6); colormap = colormap([2:6 11:15],:);
    
    % plot
    for l = [2:size(GW,2)-1 size(GW,2) 1] % ensure end plots are on top
        if l == 1 || l == size(GW,2)
            plot(w,norm_GW(:,l),'Color',colormap(l,:),'LineWidth',2); hold on
        else
            plot(w,norm_GW(:,l),'Color',colormap(l,:),'LineWidth',2); hold on
        end
        yrange = -0.2:0.1:0.4;
        plot(zeros(length(yrange),1)+7.5,yrange,'k:','LineWidth',1) % th-al
        plot(zeros(length(yrange),1)+14.5,yrange,'k:','LineWidth',1) % al-be
        plot(zeros(length(yrange),1)+30.5,yrange,'k:','LineWidth',1) % be-ga
    end
    xlabel('Frequency (Hz)')
    if pl == 1; ylabel('Normalised power (AU)'); end
    set(gca,'XLim',[0 80],'YLim',[-0.2 0.4]);
    xticks([0 20 40 60 80]); yticks([-0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5])
    set(gca,'FontSize',12)
    
    subplot(2,5,pl+5)
    for gw = 1:size(GW,2)
        plot(w, abs(GW(:,gw)),'Color',colormap(gw,:)); hold on
    end
    set(gca, 'YScale', 'log')
    set(gca, 'XScale', 'log')

else % previous version (change params individually)
    
    for k = 1:length(P)
        
        % check parameter exists
        %----------------------------------------------------------------------
        
        Q = pE.(P{k});
        
        sfig = sprintf('%s: Parameter dependency - %i, Synaptic loss %i %%',M.dipfit.model,ifig,(syn_chng_all*100));
        spm_figure('GetWin',sfig);
        
        for i = 1:size(Q,1)
            for j = 1:size(Q,2)
                
                % line search (with solution for steady state)
                %----------------------------------------------------------
                dQ    = linspace(Q(i,j) - D,Q(i,j),10);
                for q = 1:length(dQ)
                    qE      = pE;
                    qE      = setfield(qE,P{k},{i,j},dQ(q));
                    [G,w]   = spm_csd_mtf(qE,M,[]);
                    if M.dipfit.Ns == 1
                        GW(:,q) = G{1};
                    elseif M.dipfit.Ns == 2
                        GW(:,:,:,q) = G{1};
                    end
                end
                
                % plot
                %----------------------------------------------------------
                subplot(4,2,2*iplot - 1)
                plot(w,abs(GW))
                xlabel('frequency {Hz}')
                title(sprintf('Param: %s(%i,%i), Synaptic loss %i %%',P{k},i,j,(syn_chng_all*100)),'FontSize',16)
                set(gca,'XLim',[0 w(end)]);
                
                
                subplot(4,2,2*iplot - 0)
                imagesc(dQ,w,log(abs(GW)))
                title('Transfer functions','FontSize',16)
                ylabel('Frequency')
                xlabel('(log) parameter scaling')
                axis xy; drawnow
                
                % update graphics
                %----------------------------------------------------------
                iplot     = iplot + 1;
                if iplot > 4
                    iplot = 1;
                    ifig  = ifig + 1;
                    sfig = sprintf('%s: Parameter dependency - %i',M.dipfit.model,ifig);
                    spm_figure('GetWin',sfig);
                end
                
            end
        end
    end
end

return

% Dependency on hidden states in terms of Modulation transfer functions
%==========================================================================

% new figure
%--------------------------------------------------------------------------
iplot = 1;
ifig  = 1;
D     = 4;
M.Nm  = 3;
sfig  = sprintf('%s: State dependency - %i',model,ifig);
spm_figure('GetWin',sfig);

% Steady state solution and number of eigenmodes
%--------------------------------------------------------------------------
M.Nm  = 3;
x     = full(M.x);
 
 
% MTF, expanding around perturbed states
%==========================================================================

% evoked flucutations in hidden states
%--------------------------------------------------------------------------
G    = M;
G.g  = @(x,u,P,M) x;
erp  = spm_gen_erp(pE,G,U);
xmax = spm_unvec(max(erp{1}),x);
xmin = spm_unvec(min(erp{1}),x);
    
for i = 1:size(x,1)
    for j = 1:size(x,2);
        for k = 1:size(x,3);
            
            % line search
            %--------------------------------------------------------------
            dQ    = linspace(xmin(i,j,k),xmax(i,j,k),32);
            for q = 1:length(dQ)
                
                
                % MTF
                %----------------------------------------------------------
                qx        = x;
                qx(i,j,k) = qx(i,j,k) + dQ(q);
                M.x       = qx;
                [G w]     = spm_csd_mtf(pE,M);
                GW(:,q)   = G{1};
                
                % spectral decomposition
                %----------------------------------------------------------
                S         = spm_ssm2s(pE,M);
                S         = S(1:M.Nm);
                W(:,q)    = abs(imag(S)/(2*pi));
                A(:,q)    = min(4, (exp(real(S)) - 1)./(real(S)) );
                  
            end
            
            % plot
            %----------------------------------------------------------
            subplot(4,3,3*iplot - 2)
            plot(w,abs(GW))
            xlabel('frequency {Hz}')
            title(sprintf('Hidden State: (%i,%i,%i)',i,j,k),'FontSize',16)
            set(gca,'XLim',[0 w(end)]);            
            
            subplot(4,3,3*iplot - 1)
            imagesc(x(i,j,k) + dQ,w,log(abs(GW)))
            title('Transfer functions','FontSize',16)
            ylabel('Frequency')
            xlabel('Deviation')
            axis xy; drawnow
            
            subplot(4,3,3*iplot - 0)
            plot(W',log(A'),'.',W',log(A'),':','MarkerSize',16)
            title('Eigenmodes','FontSize',16)
            xlabel('Frequency')
            ylabel('log-power')
            axis xy; drawnow
            
            
            % update graphics
            %------------------------------------------------------
            iplot     = iplot + 1;
            if iplot > 4
                iplot = 1;
                ifig  = ifig + 1;
                sfig = sprintf('%s: State dependency - %i',model,ifig);
                spm_figure('GetWin',sfig);
            end
            
        end
    end
end
