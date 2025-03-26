"""Plot synaptic gain vs relative power in EEG.

Both model and measured.
"""
import pandas as pd
from matplotlib import pyplot as plt

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

# load model data
df_simulation = pd.read_csv(
    "/home/tim/dynamic_causal_modeling/results/model_simulation.txt",
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
    # rescale to interval (0.5, 1.5)
    min_syn = df_EEG[density_name].min()
    max_syn = df_EEG[density_name].max()
    df_EEG[density_name] = 0.5 + (df_EEG[density_name] - min_syn) / (max_syn - min_syn)

    # plot
    fig, axs = plt.subplots(
        nrows=len(frequencies[:-1]),
        sharex="all",
        figsize=(7, 10),
        constrained_layout=True,
    )
    fig.suptitle(title)
    for i_frequ, frequ in enumerate(frequencies[:-1]):
        ax = axs[i_frequ]
        handle_model, = ax.plot(
            df_simulation["synModulation"],
            df_simulation[frequ],
            color="tab:blue",
            label="model",
        )
        ax.set_ylabel(f"{frequ}\nrel. power")
        for donor in df_EEG[id_name].unique():
            df_reduced = df_EEG[
                (df_EEG[id_name] == donor) &
                (df_EEG["relative"] == True)
                ]
            # plot measured
            handle_patient = ax.errorbar(
                df_reduced[density_name].iloc[0],
                df_reduced[frequ[0].upper() + frequ[1:]].mean(),
                df_reduced[frequ[0].upper() + frequ[1:]].std(),
                marker="x",
                color="tab:orange",
                label="patient",
            )
    axs[0].legend(handles=[handle_patient, handle_model])
    axs[-1].set_xlabel("synaptic modulation/synaptic density")
    fig.show()

# plot only model
fig, axs = plt.subplots(
    nrows=len(frequencies[:-1]),
    sharex="all",
    figsize=(7, 10),
    constrained_layout=True,
)
for i_frequ, frequ in enumerate(frequencies[:-1]):
    ax = axs[i_frequ]
    handle_model, = ax.plot(
        df_simulation["synModulation"],
        df_simulation[frequ],
        color="tab:blue",
        label="model",
    )
    ax.set_ylabel(f"{frequ}\nrel. power")
axs[0].legend(handles=[handle_model, ])
axs[-1].set_xlabel("synaptic modulation/synaptic density")
fig.show()
