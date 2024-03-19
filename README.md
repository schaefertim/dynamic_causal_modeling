# Cite this work
If you use this code, please cite the following paper:
```
TODO add citation after publication
```
# How to use

## Folder structure
### data/
Put the raw data in this folder. This data should be a csv file with the following columns:
- subject identifier (`id` or `gId` or something you define)
- synaptic density value (`Neurite_Syn1Count` or `synDensity` or something you define)

### src/
Contains the models and helper functions. Key modules:
- `my_spm_fx_cmc_2017.m` - the main model coded by us
- `modify_cmc_2017.m` - helper function to modify the synaptic gain in the model
- `spm_fx_cmc_2017_constG.m` - code from Adams et al. 2022

### exp/
Contains the scripts described below.

### results/
empty folder where the results will be saved.

### plots/
folder for saving the plots


# Pipeline
1. `exp010_create_lookup_table.m` - run different models and create lookup tables.
2. `exp011_predict_data.py` - predict the relative power from the synaptic density data using the lookup tables.

### Old
works only for model `'all-excitatory'`
1. `exp006_plot_model.m` - run the model for different synaptic gain values and create lookup tables.
2. compute absolute and relative power (script based on which dataset is used):
   - `exp008_abs_rel_power_data.py`
   - `exp009_abs_rel_power_data.py`

# Scripts

### exp001_run_my_spm_fx_2017.m
Test script for model. Run this to confirm it is working as intended.

### exp002_rsEEG_simulation.m
Test script for Rick Adams' model.

### exp003_run_cmc_2017_modularized.m
Tests the functionality of the synaptic gain modification.
Plots the results.

### exp004_synaptic_modulation.m
Load synaptic density data and run the model.

### exp005_compare_EEG.py
Plot model results (from `exp004_synaptic_modulation.m`) vs rsEEG data.

### exp006_plot_model.m
Run the model (`model='all-excitatory'`) for different synaptic gain values and create lookup table.\
Plot and save the results.

### exp007_plot_synGain_vs_relPower.py
-- outdated -- (fix reference to `model_simulation.txt`)\
- Maps measured synaptic density to normalized range.
- plot change in power depending on synaptic gain: model and measured data

### exp008_abs_rel_power_data.py
Compute absolute and relative power from model table (from `exp006_plot_model.m`).
Save into file.\
Based on data files:
- `EEG_SynDens_v2_power_Measured_synDens_PSD95.txt`
- `EEG_SynDens_v2_power_Measured_synDens_PSD95.txt`
- `EEG_SynDens_v2_power_Predicted_synDens_PSD95.txt`
- `EEG_SynDens_v2_power_Predicted_synDens_SYN1_shank3.txt`

### exp009_abs_rel_power_data.py
Same but based on data files:
- `Measured_Density_reprocessed.txt`
- `Predicted_Density_reprocessed.txt`


# Acknowledgements
This work is inspired by Adams et al., 2022, Biological Psychiatry.\
Many thanks to Rick Adams for sharing the code (we created an independent version with same results) and helping in resolving the following issue.

### Issue with spm
The default behaviour for `N.nodelay` undefined,
changed in commit https://github.com/spm/spm/commit/30b2259b1223d7bce7906d484a3d69e8922618ac (spm_dcm_delay.m, line 112).
In previous versions (including the one Adams et al. is based on) the default was `N.nodelay = 0;`.
In the latest spm version the default is `N.nodelay = 1;`.
We set explicitly `N.nodelay = 0;` to get the old behaviour.