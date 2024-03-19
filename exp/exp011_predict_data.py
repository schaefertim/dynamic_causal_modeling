import os.path

import numpy as np
import pandas as pd

# settings - change these to your needs!
data_path = "/home/tim/dynamic_causal_modeling/data"
results_path = "/home/tim/dynamic_causal_modeling/results"
synaptic_gain_rescaling_interval = (0.5, 1.5)

# synaptic density data
data = [
    {
        "path_EEG": os.path.join(data_path, "Measured_Density_reprocessed.txt"),
        "title": "Measured_Density_reprocessed Neurite_Syn1Count",
        "id_name": "gId",
        "density_name": "Neurite_Syn1Count",
    },
    {
        "path_EEG": os.path.join(data_path, "Measured_Density_reprocessed.txt"),
        "title": "Measured_Density_reprocessed Neurite_Syn1Area",
        "id_name": "gId",
        "density_name": "Neurite_Syn1Area",
    },
    {
        "path_EEG": os.path.join(
            data_path, "EEG_SynDens_v2_power_Measured_synDens_PSD95.txt"
        ),
        "title": "measured PSD95",
        "id_name": "donor",
        "density_name": "Neurite_PSD95OvArea",
    },
    {
        "path_EEG": os.path.join(
            data_path, "EEG_SynDens_v2_power_Measured_synDens_SYN1_shank3.txt"
        ),
        "title": "measured SYN1 shank3",
        "id_name": "donor",
        "density_name": "Neurite_Syn1Count",
    },
]
data = pd.DataFrame(data)
# frequency names
frequencies = [
    "delta",
    "theta",
    "alpha",
    "beta",
    "gamma1",
    "gamma2",
    "lowFreq",
    "hiFreq",
    "totalAbsPow",
]

for i_model in range(1, 7):
    print(f"Loading model data for model_{i_model}.")
    df_simulation_rel = pd.read_csv(
        os.path.join(
            results_path,
            f"exp010_model_{i_model}_rel.txt",
        ),
        sep="\t",
    )
    for i_data in data.index:
        print(f"analyzing {data.loc[i_data, 'path_EEG']}")
        # load measured
        df_EEG = pd.read_csv(
            data.loc[i_data, "path_EEG"],
            sep="\t",
        )
        # create new pandas DataFrame based on unique ids
        df_result_rel = df_EEG.drop_duplicates(
            data.loc[i_data, "id_name"]
        ).reset_index()[[data.loc[i_data, "id_name"], data.loc[i_data, "density_name"]]]
        # rescale to synaptic_gain_rescaling_interval
        min_syn = df_result_rel[data.loc[i_data, "density_name"]].min()
        max_syn = df_result_rel[data.loc[i_data, "density_name"]].max()
        df_result_rel["synaptic_gain"] = synaptic_gain_rescaling_interval[0] + (
            df_result_rel[data.loc[i_data, "density_name"]] - min_syn
        ) / (max_syn - min_syn) * (
            synaptic_gain_rescaling_interval[1] - synaptic_gain_rescaling_interval[0]
        )
        # for each row lookup relative power in model simulation
        for frequency in frequencies:
            df_result_rel[frequency] = np.interp(
                df_result_rel["synaptic_gain"].values,
                df_simulation_rel["synModulation"].values,
                df_simulation_rel[frequency].values,
            )
        print(
            f"Write results for {data.loc[i_data, 'title']} model_{i_model} to file."
        )
        df_result_rel.to_csv(
            os.path.join(
                results_path,
                f"exp011 {data.loc[i_data, 'title']} model_{i_model} rel power.txt",
            ),
            sep="\t",
        )
