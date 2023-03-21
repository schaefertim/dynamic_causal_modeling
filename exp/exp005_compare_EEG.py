"""Compare measured EEG to model prediction.

Plot relative power of model vs relative model of measured EEG for each patient.
"""
import pandas as pd
from matplotlib import pyplot as plt

EEG_measured = pd.read_csv(
    "/home/tim/dynamic_causal_modeling/data/EEG_SynDens_v2_power_Measured_synDens_PSD95.txt",
    sep="\t",
)
# fix donor labels
EEG_measured["donor"] = EEG_measured["donor"].apply(lambda donor: donor.replace("0", "").upper())

# %%
model_measured = pd.read_csv(
    "/home/tim/dynamic_causal_modeling/results/result_measured.txt", sep="\t"
)
list_quantities = ["absPower_normalized", "absPower", "relPower", "relPower_normalized"]
frequencies = ['delta', 'theta', 'alpha', 'beta', 'gamma1', 'gamma2', 'lowFreq', 'hiFreq', 'totalAbsPow']

# %% common labels
labels_EEG = set(EEG_measured["donor"])
labels_model = set(model_measured["donor"])
labels_common = list(labels_EEG.intersection(labels_model))
print("common labels", labels_common)
print("residual EEG", labels_EEG - labels_model)
print("residual model", labels_model - labels_EEG)
del labels_EEG, labels_model

# %% plot quantities against each other
fig, axs = plt.subplots(
    ncols=len(labels_common),
    sharex="all",
    sharey="all",
    figsize=(10, 3),
    constrained_layout=True,
)
fig.suptitle("Relative power comparison")
for i_donor, donor in enumerate(labels_common):
    axs[i_donor].set_title(donor)
    axs[i_donor].set_xlabel("rel. power\nmodel")
    for i_frequ, frequ in enumerate(frequencies[:-1]):
        EEG_measured_reduced = EEG_measured[
            (EEG_measured["donor"] == donor) &
            (EEG_measured["relative"] == True)  # noqa: E712
        ]
        ax = axs[i_donor]
        ax.plot([0, 1], [0, 1], linestyle="--", color="black")
        ax.errorbar(
            model_measured.loc[model_measured["donor"] == donor, f"relPower_{frequ}"],
            EEG_measured_reduced[frequ[0].upper()+frequ[1:]].mean(),
            yerr=EEG_measured_reduced[frequ[0].upper()+frequ[1:]].std(),
            marker='x',
            label=frequ,
        )
        if i_donor == 0:
            ax.set_ylabel(f"rel. power\nmeasured")
axs[-1].legend(bbox_to_anchor=(1.1, 1.05))
fig.show()
