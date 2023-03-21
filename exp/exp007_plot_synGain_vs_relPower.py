"""Plot synaptic gain vs relative power in EEG.

Both model and measured.
"""
import pandas as pd
from matplotlib import pyplot as plt

# load measured
EEG_measured = pd.read_csv(
    "/home/tim/dynamic_causal_modeling/data/EEG_SynDens_v2_power_Measured_synDens_PSD95.txt",
    sep="\t",
)

# load model data
df_simulation = pd.read_csv(
    "/home/tim/dynamic_causal_modeling/results/model_simulation.txt",
    sep="\t",
)

frequencies = ['delta', 'theta', 'alpha', 'beta', 'gamma1', 'gamma2', 'lowFreq', 'hiFreq', 'totalAbsPow']

# plot
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
    for donor in EEG_measured["donor"].unique():
        df_reduced = EEG_measured[
             (EEG_measured["donor"] == donor) &
             (EEG_measured["relative"] == True)
        ]
        # plot measured
        handle_patient = ax.errorbar(
            df_reduced["Neurite_PSD95OvArea"].iloc[0],
            df_reduced[frequ[0].upper() + frequ[1:]].mean(),
            df_reduced[frequ[0].upper() + frequ[1:]].std(),
            marker="x",
            color="tab:orange",
            label="patient",
        )
axs[0].legend(handles=[handle_patient, handle_model])
axs[-1].set_xlabel("synaptic modulation/synaptic density")
fig.show()
