% Create a lookup table:
% - for each frequency band
% - for relative and absolute power
% - for each model (6 models)
% - for each synaptic density value (0.5:0.025:1.5)

% load model
[M, pE] = load_cmc_2017_and_priors();
M.Hz = 1:0.25:96;
show_plot = true;

% load frequency definitions
frequency_definitions = get_frequency_definitions();
freq_bands = fieldnames(frequency_definitions);

% list of synaptic density values
synapticDensity = 0.5:0.025:1.5;

for i_model=1:6
    if i_model == 6
        model_name = 'all-excitatory';
    else
        model_name = i_model;
    end
    model_string = string(i_model);
    power_abs = zeros(size(synapticDensity,2),size(freq_bands,1));
    power_rel = zeros(size(synapticDensity,2),size(freq_bands,1));

    % run model for each parameter
    for i_param=1:size(synapticDensity,2)
        % modulate synaptic gain based on database
        P = pE;
        factor = log(synapticDensity(i_param));
        [M,P] = modify_cmc_2017(M,P,model_name,factor);

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

    if show_plot
        % plot
        figure
        for i_freq_band=1:numel(freq_bands)
            plot(synapticDensity, power_rel(:,i_freq_band)), hold on
        end
        title(sprintf("Relative power for model %s", model_string))
        xlabel("Synaptic gain modulation factor"), ylabel("relative power");
        legend(freq_bands)
        shg
    end

    % create and save table
    table_save_rel = table;
    table_save_abs = table;
    table_save_rel.synModulation = reshape(synapticDensity,[],1);
    table_save_abs.synModulation = reshape(synapticDensity,[],1);
    for i_freq_band=1:numel(freq_bands)
        table_save_rel.(freq_bands{i_freq_band}) = power_rel(:,i_freq_band);
        table_save_abs.(freq_bands{i_freq_band}) = power_abs(:,i_freq_band);
    end
    writetable(table_save_rel, sprintf('dynamic_causal_modeling/results/exp010_model_%s_rel.txt', model_string), 'Delimiter', 'tab')
    writetable(table_save_abs, sprintf('dynamic_causal_modeling/results/exp010_model_%s_abs.txt', model_string), 'Delimiter', 'tab')
end
