% For each synaptic density compute and plot relative power.
% Result: relationship is almost linear for all frequency bands.

% load model
[M, pE] = load_cmc_2017_and_priors();
M.Hz = 1:0.25:96;

% load frequency definitions
frequency_definitions = get_frequency_definitions();
freq_bands = fieldnames(frequency_definitions);

% list of synaptic density values
synapticDensity = 0.5:0.025:1.5;
power_abs = zeros(size(synapticDensity,2),size(freq_bands,1));
power_rel = zeros(size(synapticDensity,2),size(freq_bands,1));

% run model for each parameter
for i_param=1:size(synapticDensity,2)
    % modulate synaptic gain based on database
    P = pE;
    factor = log(synapticDensity(i_param));
    [M,P] = modify_cmc_2017(M,P,'all-excitatory',factor);
    
    % compute power spectrum
    [freq, psd, psd_normalised, psd_fit] = spm_get_power_spectrum_and_normalization(M,P);

    % compute absolute power
    power_abs_norm = struct();
    for i_freq_band=1:numel(freq_bands)
        band_name = freq_bands{i_freq_band};
        band_range = frequency_definitions.(band_name);
        % TODO clarify <= or <
        selection = (freq >= band_range(1)) & (freq < band_range(2));
        power_abs(i_param,i_freq_band) = sum(psd(selection));
    end

    % compute relative power
    for i_freq_band=1:numel(freq_bands)
        band_name = freq_bands{i_freq_band};
        power_rel(i_param,i_freq_band) = power_abs(i_param,i_freq_band) / power_abs(i_param,end);
    end
end

% plot
figure
for i_freq_band=1:numel(freq_bands)
    plot(synapticDensity, power_rel(:,i_freq_band)), hold on
end
title('Relative power in model')
xlabel("Synaptic gain modulation factor"), ylabel("relative power");
legend(freq_bands)
shg

% create and save table
table_save = table;
table_save.synModulation = reshape(synapticDensity,[],1);
for i_freq_band=1:numel(freq_bands)
    table_save.(freq_bands{i_freq_band}) = power_rel(:,i_freq_band);
end
writetable(table_save, 'dynamic_causal_modeling/results/model_simulation.txt', 'Delimiter', 'tab')
