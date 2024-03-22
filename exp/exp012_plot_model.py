import os

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


results_path = "/home/tim/dynamic_causal_modeling/results"
fig_path = "/home/tim/dynamic_causal_modeling/plots"
i_model = 6

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

# plot
fig, ax = plt.subplots(constrained_layout=True)
sns.despine()
# create color map 0.7 -> red, 1.0 -> blue
sm = plt.cm.ScalarMappable(cmap="coolwarm_r", norm=plt.Normalize(vmin=0.7, vmax=1.0))
sm.set_array([])
fig.colorbar(sm, ax=ax, label="Synaptic gain")
palette = sns.color_palette("coolwarm_r", n_colors=df_simulation.shape[1])
sns.lineplot(
    data=df_simulation,
    ax=ax,
    dashes=False,
    palette=palette,
    legend=False,
)

ax.set_ylabel("Relative power [a.u.]")
ax.set_yscale("log")
ax.set_xlabel("Frequency [Hz]")
fig.show()

# save as svg and pdf
fig.savefig(os.path.join(fig_path, f"exp012_model_{i_model}_rel.svg"))
fig.savefig(os.path.join(fig_path, f"exp012_model_{i_model}_rel.pdf"))
