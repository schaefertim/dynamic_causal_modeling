function [freq, psd, psd_normalised, psd_fit] = spm_get_power_spectrum_and_normalization(M,P)
%SPM_GET_POWER_SPECTRUM_AND_NORMALIZATION psd and psd_normalized
%   Computes powerspectrum via spm_csd_mtf(P,M).
%   Normalize by robustfit a linear 1/f to psd and subtracting in
%   log-space.

% create forward model and solve for steady state
%------------------------------------------------------------------
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
end

