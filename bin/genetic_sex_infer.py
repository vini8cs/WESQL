#!/usr/bin/env python3

import argparse

import polars as pl


def get_options() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create coverage graphs")
    parser.add_argument("-f", "--depth_file", metavar="<file>", help="depth file from Samtools depth", required=True)
    parser.add_argument("-o", "--output", metavar="<file>", help="output file", default="sex_infer.txt")
    options = parser.parse_args()

    return options


def sex_genetic_infer(grafh_df, output):
    chrX = grafh_df.filter(pl.col("chr") == "chrX")
    chrY = grafh_df.filter(pl.col("chr") == "chrY")

    mean_X = chrX["cov"].mean()
    mean_Y = chrY["cov"].mean()

    ratio = mean_Y / mean_X if mean_X > 0 else 0

    with open(output, "w") as output_file:
        if ratio < 0.1:
            output_file.write("female\n")
        else:
            output_file.write("male\n")


def main():
    menu = get_options()
    df = pl.read_csv(menu.depth_file, separator="\t", has_header=False, new_columns=["chr", "pos", "cov"])
    sex_genetic_infer(df, menu.output)


if __name__ == "__main__":
    main()
