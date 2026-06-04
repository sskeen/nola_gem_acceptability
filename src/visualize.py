# visualize.py
# Visualization functions for acceptability data
# Simone J. Skeen x Claude Code

import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns


def plot_acceptability_scatter(df, int_cols, x_labels, y_labels, title, output_path,
                                replace_val=None, color='#7eb0d5', figsize=(8, 5)):
    '''
    Creates a jittered scatter plot with mean +/- SD overlay for Likert-scale acceptability data.

    Parameters:
    -----------
    df : pd.DataFrame
        DataFrame containing the intervention columns.
    int_cols : list
        Column names to plot (e.g., ['int1_rev', 'int2_rev', ...]).
    x_labels : list
        Labels for x-axis ticks (must match length of int_cols).
    y_labels : dict
        Mapping of numeric values to y-axis labels (e.g., {1: 'disagree', 2: 'somewhat disagree'}).
    title : str
        Plot title.
    output_path : Path
        Full path for saving the figure.
    replace_val : int, optional
        Value to replace with NaN before plotting (e.g., 5 for "N/A" responses).
    color : str
        Hex color for points and error bars. Default: '#7eb0d5' (ng_blue).
    figsize : tuple
        Figure dimensions. Default: (8, 5).

    Returns:
    --------
    None (displays and saves figure)
    '''
    sns.set_style(style='whitegrid', rc=None)

    fig, ax = plt.subplots(figsize=figsize)
    x_positions = range(len(int_cols))

    for i, col in enumerate(int_cols):
        y_vals = df[col].astype(float)

        # handle N/A responses if specified
        if replace_val is not None:
            y_vals = y_vals.replace(replace_val, np.nan).dropna()

        x_jittered = np.random.normal(
            loc=i,
            scale=0.16,
            size=len(y_vals),
        )

        # scatter points
        ax.scatter(
            x_jittered,
            y_vals,
            alpha=0.6,
            s=35,
            color=color,
            linewidths=0.5,
        )

        # mean +/- SD overlay
        ax.errorbar(
            i,
            y_vals.mean(),
            yerr=y_vals.std(),
            fmt='D',
            color=color,
            markersize=8,
            capsize=0,
            linewidth=1,
            zorder=3,
        )

    # format axes
    ax.set_xticks(x_positions)
    ax.set_xticklabels(
        x_labels,
        rotation=45,
        ha='right',
        fontsize=9,
    )
    ax.tick_params(
        axis='y',
        left=False,
        labelleft=False,
    )

    ax_right = ax.secondary_yaxis('right')
    ax_right.set_yticks(list(y_labels.keys()))
    ax_right.set_yticklabels(list(y_labels.values()))

    ax.set_title(title, fontsize=10)
    ax.grid(False)
    plt.tight_layout()

    # save and display
    plt.savefig(output_path, dpi=300)
    plt.show()
