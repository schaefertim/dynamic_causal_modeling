import os.path

import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
import seaborn as sns

# settings - change these to your needs!
data_path = "/home/tim/dynamic_causal_modeling/data"
results_path = "/home/tim/dynamic_causal_modeling/results"
fig_path = "/home/tim/dynamic_causal_modeling/plots"
synaptic_gain_rescaling_interval = (0.7, 1.0)  # (0.5, 1.5)
i_model = 6

# synaptic density data
data = [
    {
        "path_EEG": os.path.join(data_path, "MeasuredDensity_extended.txt"),
        "title": "MeasuredDensity_extended",
        "id_name": "gId",
        "density_name": "Neurite_Syn1Area",
    },
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
df_data = pd.DataFrame(data)

df_simulation = pd.read_csv(
    os.path.join(
        results_path,
        f"exp010_model_{i_model}_abs_all.txt",
    ),
    sep="\t",
    index_col=0,
)
# dataframe has index column the frequencies
# other columns are name synaptic density values and contain absolute power values

# convert column names to float
df_simulation.columns = df_simulation.columns.astype(float)

# reduce columns to synaptic density values > 0.7 and < 1.0
df_simulation = df_simulation.loc[
    :, (df_simulation.columns >= 0.7) & (df_simulation.columns <= 1.0)
]

# reduce rows to frequencies <= 70 Hz
df_simulation = df_simulation.loc[df_simulation.index <= 70]

# divide by total power to get relative power
for column in df_simulation.columns:
    df_simulation[column] = df_simulation[column] / df_simulation[column].sum()


for data in df_data.itertuples():
    print(f"analyzing {data.path_EEG}")
    # load measured
    df_EEG = pd.read_csv(
        data.path_EEG,
        sep="\t",
    )
    # reduce to unique ids
    df_EEG = df_EEG.drop_duplicates(subset=data.id_name)
    print(f"Loaded {len(df_EEG)} rows.")

    # transform synaptic density to synaptic gain
    min_syn = df_EEG[data.density_name].min()
    max_syn = df_EEG[data.density_name].max()
    df_EEG["synaptic_gain"] = synaptic_gain_rescaling_interval[0] + (
        df_EEG[data.density_name] - min_syn
    ) / (max_syn - min_syn) * (
        synaptic_gain_rescaling_interval[1] - synaptic_gain_rescaling_interval[0]
    )

    # add columns for each frequency
    df_EEG = pd.concat([df_EEG, pd.DataFrame(columns=df_simulation.index)], axis=1)

    # for each frequency, interpolate power from simulation
    for frequency in df_simulation.index:
        df_EEG[frequency] = np.interp(
            df_EEG["synaptic_gain"],
            df_simulation.columns,
            df_simulation.loc[frequency],
        )

    # plot powerspectra of interpolated power
    fig, ax = plt.subplots(constrained_layout=True)
    sns.despine()
    # create color map 0.7 -> red, 1.0 -> blue
    norm = plt.Normalize(vmin=0.7, vmax=1.0)
    sm = plt.cm.ScalarMappable(cmap="coolwarm_r", norm=norm)

    for idx_EEG in df_EEG.index:
        ax.plot(
            df_simulation.index,
            df_EEG.loc[idx_EEG, df_simulation.index],
            color=sm.to_rgba(df_EEG.at[idx_EEG, "synaptic_gain"]),
            label=df_EEG.loc[idx_EEG, data.id_name],
        )
    ax.set_title(f"Model {i_model} - {data.title} (N={len(df_EEG)})")
    ax.set_ylabel("Relative power [a.u.]")
    ax.set_yscale("log")
    ax.set_xlabel("Frequency [Hz]")

    # inset with histogram of synaptic gain in top right corner
    # should have same colorscheme as line
    ax_inset = fig.add_axes([0.6, 0.6, 0.25, 0.25])
    n_bins = 6
    hist, bin_edges = np.histogram(
        df_EEG["synaptic_gain"], bins=n_bins, range=(0.7, 1.0)
    )
    palette = sns.color_palette("coolwarm_r", n_bins)
    for i, (start, end) in enumerate(zip(bin_edges[:-1], bin_edges[1:])):
        ax_inset.bar(
            (start + end) / 2,
            hist[i],
            width=(end - start),
            color=palette[i],
        )
    ax_inset.set_xlabel("Synaptic gain")
    ax_inset.set_xticks([0.7, 0.8, 0.9, 1.0])
    ax_inset.set_ylabel("Count")
    sns.despine(ax=ax_inset)

    fig.show()
    fig.savefig(os.path.join(fig_path, f"exp013_model_{i_model}_{data.title}.svg"))
    fig.savefig(os.path.join(fig_path, f"exp013_model_{i_model}_{data.title}.pdf"))
