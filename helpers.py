"""
helpers.py — reusable utility functions for CRM data cleaning,
descriptive statistics, and visualization.
"""

import math
import re

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from IPython.display import display


def to_snake(name: str) -> str:
    """
    Convert a column name to snake_case.

    Example:
        'Contact Owner Name' -> 'contact_owner_name'
    """
    # Remove parentheses and their contents:
    # 'Call Duration (in seconds)' -> 'Call Duration'
    name = re.sub(r'\s*\(.*?\)', '', name)

    # Trim leading and trailing whitespace
    name = name.strip()

    # Insert an underscore between lowercase and uppercase letters:
    # 'AdGroup' -> 'Ad_Group'
    name = re.sub(r'([a-z])([A-Z])', r'\1_\2', name)

    # Replace spaces and hyphens with underscores
    name = re.sub(r'[\s\-]+', '_', name)

    # Keep only letters, numbers, and underscores
    name = re.sub(r'[^\w]', '', name)

    # Convert to lowercase
    name = name.lower()

    # Remove repeated underscores and trim them from the edges
    name = re.sub(r'_+', '_', name).strip('_')

    return name


def df_overview(df: pd.DataFrame) -> None:
    """
    Display a compact overview of a DataFrame.

    Parameters
    ----------
    df : pd.DataFrame
        DataFrame to inspect.
    """
    print(f"\n{'=' * 60}")
    print(f"Shape: {df.shape[0]} rows × {df.shape[1]} columns")

    summary = pd.DataFrame({
        'dtype': df.dtypes,
        'missing': df.isnull().sum(),
        'missing_%': (df.isnull().mean() * 100).round(1),
        'unique': df.nunique(),
    })
    display(summary)

    print("\nFirst 5 rows:")
    display(df.head(5))


def df_clean_summary(df: pd.DataFrame) -> None:
    """
    Display shape, data types, and remaining missing values
    after a cleaning step.
    """
    print(f"{'=' * 60}")
    print(f"Shape: {df.shape[0]} rows × {df.shape[1]} columns")

    print("\nData types:")
    print(df.dtypes)

    print("\nMissing values:")
    missing = df.isnull().sum()
    missing_df = pd.DataFrame({
        'missing': missing,
        '%': (missing / len(df) * 100).round(2)
    })
    missing_df = missing_df[missing_df['missing'] > 0]

    if missing_df.empty:
        print("No missing values ✓")
    else:
        display(missing_df)


def set_style():
    """
    Apply a consistent visualization style across notebooks.

    Returns
    -------
    dict
        Dictionary with the main project colors.
    """
    accent = '#2563EB'
    background = '#F8FAFC'
    grid = '#E2E8F0'
    text = '#1E293B'

    sns.set_theme(style='white', font_scale=1.05)

    plt.rcParams.update({
        'figure.facecolor': background,
        'axes.facecolor': background,
        'axes.edgecolor': grid,
        'axes.spines.top': False,
        'axes.spines.right': False,
        'grid.color': grid,
        'grid.linestyle': '--',
        'text.color': text,
        'axes.labelcolor': text,
        'xtick.color': text,
        'ytick.color': text,
    })

    return {
        'accent': accent,
        'bg': background,
        'grid': grid,
        'text': text,
    }


def descriptive_stats(df: pd.DataFrame, exclude=None) -> None:
    """
    Display descriptive statistics for numerical and categorical columns.

    Parameters
    ----------
    df : pd.DataFrame
        DataFrame to analyze.
    exclude : list[str] | None
        Optional list of columns to exclude.
    """
    data = df.drop(columns=exclude, errors='ignore') if exclude else df

    print(f"Rows: {len(df):,} | Columns: {df.shape[1]}\n")

    num_cols = data.select_dtypes(include=np.number).columns.tolist()
    if num_cols:
        print("Numerical variables:\n")
        desc = data[num_cols].describe().T.round(2)
        desc['mode'] = data[num_cols].mode().iloc[0]
        display(desc)

    cat_cols = data.select_dtypes(
        include=['object', 'category']
    ).columns.tolist()

    if cat_cols:
        print("Categorical variables:\n")
        display(data[cat_cols].describe().T)


def cat_stats(
    df: pd.DataFrame,
    table_name: str,
    exclude=None
) -> None:
    """
    Display counts and percentage distributions for categorical columns.
    """
    data = df.drop(columns=exclude, errors='ignore') if exclude else df

    cat_cols = data.select_dtypes(
        include=['object', 'category']
    ).columns.tolist()

    for col in cat_cols:
        value_counts = data[col].value_counts(dropna=True)

        result = pd.DataFrame({
            col: value_counts.index,
            'count': value_counts.values,
            'percentage': (
                value_counts.values / value_counts.sum() * 100
            ).round(2),
        })

        print(f"{table_name} — {col}")
        display(result)


colors = set_style()


def date_stats(
    df: pd.DataFrame,
    date_cols,
    table_name: str = '',
    plot: bool = True
) -> None:
    """
    Display summary statistics and monthly distributions
    for datetime columns.
    """
    for col in date_cols:
        series = df[col].dropna()

        print(f"{table_name} — {col}")
        print(f"  count:   {len(series)}")
        print(f"  missing: {df[col].isna().sum()}")
        print(f"  min:     {series.min().strftime('%d.%m.%Y')}")
        print(f"  max:     {series.max().strftime('%d.%m.%Y')}")
        print(f"  range:   {(series.max() - series.min()).days} days")
        print()

        monthly = (
            series.dt.to_period('M')
            .value_counts()
            .sort_index()
            .rename_axis('month')
            .reset_index(name='count')
        )

        monthly['percentage'] = (
            monthly['count'] / len(series) * 100
        ).round(2)

        display(monthly)

        if plot:
            fig, ax = plt.subplots(figsize=(12, 3))
            ax.bar(
                monthly['month'].astype(str),
                monthly['count'],
                color=colors['accent']
            )
            ax.set_title(f"{table_name} — {col}")
            ax.tick_params(axis='x', rotation=45)
            plt.tight_layout()
            plt.show()

        print()


def plot_distributions(
    df: pd.DataFrame,
    cols,
    ncols: int = 3,
    figsize=None
) -> None:
    """
    Plot distributions for numerical and categorical variables.
    """
    nrows = math.ceil(len(cols) / ncols)

    if figsize is None:
        figsize = (6 * ncols, 4 * nrows)

    fig, axes = plt.subplots(
        nrows,
        ncols,
        figsize=figsize,
        squeeze=False
    )
    axes = axes.flatten()

    for i, col in enumerate(cols):
        ax = axes[i]

        if df[col].dtype == 'object' or df[col].dtype.name == 'category':
            sns.countplot(
                data=df,
                y=col,
                color=colors['accent'],
                order=df[col].value_counts().index,
                ax=ax
            )

            for patch in ax.patches:
                ax.text(
                    patch.get_width() + 0.3,
                    patch.get_y() + patch.get_height() / 2,
                    f'{int(patch.get_width())}',
                    va='center'
                )
        else:
            sns.histplot(
                df[col],
                bins=30,
                color=colors['accent'],
                ax=ax
            )

        ax.set_title(col)

    for j in range(i + 1, len(axes)):
        axes[j].set_visible(False)

    plt.tight_layout()
    plt.show()
