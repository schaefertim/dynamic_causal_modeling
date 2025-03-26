import os.path

import numpy as np
import pandas as pd

paths_EEG = [
    "/home/tim/dynamic_causal_modeling/data/EEG_SynDens_v2_power_Measured_synDens_PSD95.txt",
    "/home/tim/dynamic_causal_modeling/data/EEG_SynDens_v2_power_Measured_synDens_SYN1_shank3.txt",
    "/home/tim/dynamic_causal_modeling/data/EEG_SynDens_v2_power_Predicted_synDens_PSD95.txt",
    "/home/tim/dynamic_causal_modeling/data/EEG_SynDens_v2_power_Predicted_synDens_SYN1_shank3.txt",
]
titles = [
    "measured PSD95",
    "measured SYN1 shank3",
    "predicted PSD95",
    "predicted SYN1 shank3",
]

path_results = "/home/tim/dynamic_causal_modeling/results"

# load model data
df_simulation_rel = pd.read_csv(
    "/home/tim/dynamic_causal_modeling/results/exp006_model_simulation_rel.txt",
    sep="\t",
)
df_simulation_abs = pd.read_csv(
    "/home/tim/dynamic_causal_modeling/results/exp006_model_simulation_abs.txt",
    sep="\t",
)

frequencies = ['delta', 'theta', 'alpha', 'beta', 'gamma1', 'gamma2', 'lowFreq', 'hiFreq', 'totalAbsPow']

for path_EEG, title in zip(paths_EEG, titles):
    print(f"analyzing {path_EEG}")
    # load measured
    df_EEG = pd.read_csv(
        path_EEG,
        sep="\t",
    )
    if "donor" in df_EEG.columns:
        id_name = "donor"
    else:
        id_name = "id"
    if "Neurite_PSD95OvArea" in df_EEG.columns:
        density_name = "Neurite_PSD95OvArea"
    elif "Neurite_Syn1Count" in df_EEG.columns:
        density_name = "Neurite_Syn1Count"
    else:
        density_name = "synDensity"

    # create new pandas DataFrame based on unique ids
    df_result_rel = df_EEG.drop_duplicates(id_name).reset_index()[[id_name, density_name]]
    df_result_abs = df_EEG.drop_duplicates(id_name).reset_index()[[id_name, density_name]]

    # rescale to interval (0.5, 1.5)
    for df in [df_result_rel, df_result_abs]:
        min_syn = df[density_name].min()
        max_syn = df[density_name].max()
        df["synaptic_gain"] = 0.5 + (df[density_name] - min_syn) / (max_syn - min_syn)

    # for each row lookup relative power in model simulation
    for df_result, df_simulation in zip(
        [df_result_rel, df_result_abs], [df_simulation_rel, df_simulation_abs]
    ):
        for frequency in frequencies:
            df_result[frequency] = np.interp(
                df_result['synaptic_gain'].values,
                df_simulation['synModulation'].values,
                df_simulation[frequency].values,
            )

    df_result_rel.to_csv(os.path.join(path_results, f"exp008 {title} rel power.txt"), sep="\t")
    df_result_abs.to_csv(os.path.join(path_results, f"exp008 {title} abs power.txt"), sep="\t")
