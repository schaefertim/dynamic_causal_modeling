% run model with modulated synaptic strength based on data

% load synaptic densities file
data_measured = readtable("dynamic_causal_modeling/data/MeasuredSynDensity_parameters_SYN1_PSD95.txt");
data_predict  = readtable("dynamic_causal_modeling/data/PredictedSynDensity_parameters_glm_SYN1_PSD95.txt");

% re-normalization, re-scaling -> currently nothing
data_measured.synapticGain = data_measured.Neurite_PSD95OvArea;
data_predict.synapticGain  = data_predict.synDensity;

% plot histogram
figure1 = figure();
subplot(1,2,1)
histogram(data_measured.Neurite_PSD95OvArea)
title(sprintf('mean=%.2f std=%.2f', mean(data_measured.synapticGain), std(data_measured.synapticGain)))
subplot(1,2,2)
histogram(data_predict.synDensity)
title(sprintf('mean=%.2f std=%.2f', mean(data_predict.synapticGain), std(data_predict.synapticGain)))
close(figure1)

% load model
[M, pE] = load_cmc_2017_and_priors();
M.Hz = 1:0.25:96;

% load frequency definitions
frequency_definitions = get_frequency_definitions();
freq_bands = fieldnames(frequency_definitions);

for flag_dataset=1:2
    if flag_dataset==1
        data = data_measured;
    else
        data = data_predict;
    end
    table_result = table();
    figure;
    for i_data=1:size(data,1)
        %display(data_measured.donor(i_data))
        % modulate synaptic gain based on database
        P = pE;
        factor = log(data.synapticGain(i_data));
        [M,P] = modify_cmc_2017(M,P,'all-excitatory',factor);
        
        % compute power spectrum
        [freq, psd, psd_normalised, psd_fit] = spm_get_power_spectrum_and_normalization(M,P);
    
        % compute absolute power
        power_abs = struct();
        power_abs_norm = struct();
        for i_freq_band=1:numel(freq_bands)
            band_name = freq_bands{i_freq_band};
            band_range = frequency_definitions.(band_name);
            % TODO clarify <= or <
            selection = (freq >= band_range(1)) & (freq < band_range(2));
            power_abs.(band_name) = sum(psd(selection));
            power_abs_norm.(band_name) = sum(psd_normalised(selection));
        end
    
        % compute relative power
        power_rel = struct();
        for i_freq_band=1:numel(freq_bands)
            band_name = freq_bands{i_freq_band};
            power_rel.(band_name) = power_abs.(band_name) / power_abs.totalAbsPow;
            power_rel_norm.(band_name) = power_abs_norm.(band_name) / power_abs_norm.totalAbsPow;
        end
        
        subplot(1,2,1)
        plot(freq,psd)
        set(gca,'YScale','log','XScale','log')
        ylabel('power'), xlabel('frequency')
        hold on
        subplot(1,2,2)
        plot(freq,psd_normalised)
        xlabel('frequency'), ylabel('normalized power')
        hold on
    
        % save to table
        table_new_row = data(i_data,:);
        table_new_row.absPower = struct2table(power_abs);
        table_new_row.relPower = struct2table(power_rel);
        table_new_row.absPower_normalized = struct2table(power_abs_norm);
        table_new_row.relPower_normalized = struct2table(power_rel_norm);
        table_result = [table_result; table_new_row];
    end
    % write to file
    table_result = splitvars(table_result);
    display(table_result);
    if flag_dataset==1
        writetable(table_result, 'dynamic_causal_modeling/results/result_measured.txt', 'Delimiter', 'tab')
    else
        writetable(table_result, 'dynamic_causal_modeling/results/result_predicted.txt','Delimiter','tab')
    end
end
