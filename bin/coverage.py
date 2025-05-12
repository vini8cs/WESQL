#!/usr/bin/env python3

import argparse
import os

import matplotlib.pyplot as plt
import polars as pl


def get_options() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create coverage graphs")
    parser.add_argument("-f", "--depth_files", nargs="+", help="depth files from Samtools", required=True)
    options = parser.parse_args()

    return options


def create_coverage_graph(grafh_df, chr_name):
    plt.figure(figsize=(10, 6))
    samples = grafh_df["sample"].unique()
    colors = plt.cm.tab10.colors

    for idx, sample in enumerate(samples):
        sample_df = grafh_df[grafh_df["sample"] == sample]
        depths = sample_df["depth"].values
        max_depth = depths.max()
        mean_depth = depths.mean()
        x = list(range(0, max_depth + 1))
        y = [(depths >= i).sum() / len(depths) for i in x]

        plt.plot(x, y, linewidth=1, label=f"{sample} (mean={mean_depth:.2f})", color=colors[idx % len(colors)])
        plt.axvline(mean_depth, color=colors[idx % len(colors)], linestyle="--")

    plt.xlabel("Coverage")
    plt.ylabel("Proportion of genome at coverage")
    plt.title(f"Coverage Distribution - {chr_name}")
    plt.legend()
    plt.tight_layout()
    plt.savefig(f"{chr_name}_coverage.svg")
    plt.close()


def main():
    menu = get_options()
    lazy_frames = [
        pl.scan_csv(
            file,
            separator="\t",
            has_header=False,
            new_columns=["chr", "pos", "depth"],
        ).with_columns(pl.lit(os.path.splitext(os.path.basename(file))[0]).alias("sample"))
        for file in menu.depth_files
    ]

    df_lazy = pl.concat(lazy_frames)
    chr_list = df_lazy.select("chr").unique().collect()["chr"].to_list()

    for chr_name in chr_list:
        df_chr = df_lazy.filter(pl.col("chr") == chr_name).collect().to_pandas()
        create_coverage_graph(df_chr, chr_name=str(chr_name).capitalize())


if __name__ == "__main__":
    main()
