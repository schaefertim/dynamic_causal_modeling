import os.path

import numpy as np
import pandas as pd

paths_EEG = [
    "/home/tim/dynamic_causal_modeling/data/Measured_Density_reprocessed.txt",
    "/home/tim/dynamic_causal_modeling/data/Predicted_Density_reprocessed.txt",
]
titles = [
    "Measured_Density_reprocessed",
    "Predicted_Density_reprocessed",
]

id_name = "gId"
density_names = ["Neurite_Syn1Count", "Neurite_Syn1Area"]

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
    for density_name in density_names:
        if density_name not in df_EEG.columns:
            print(f"Skipping {density_name} because it is not in the data.")
            continue
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
        print(f"Write results for {title} {density_name} to file.")
        df_result_rel.to_csv(os.path.join(path_results, f"exp009 {title} {density_name} rel power.txt"), sep="\t")
        df_result_abs.to_csv(os.path.join(path_results, f"exp009 {title} {density_name} abs power.txt"), sep="\t")
