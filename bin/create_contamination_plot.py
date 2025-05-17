#!/usr/bin/env python3

import argparse

import matplotlib.pyplot as plt
import pandas as pd

TAXIDS_TARGETS = {
    "Bacteria": "2",
    "Archaea": "2157",
    "Fungi": "4751",
    "Plant": "33090",
    "Human": "9606",
    "Eukaryota": "2759",
    "Unclassified": "0",
}

GROUP_COLORS = {
    "Bacteria": "#4E79A7",
    "Archaea": "#F28E2B",
    "Fungi": "#E15759",
    "Plant": "#76B7B2",
    "Human": "#59A14F",
    "Other Eukaryota": "#EDC948",
    "Unclassified": "#B07AA1",
}


def get_options() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create coverage graphs")
    parser.add_argument("-r", "--report", help="Kraken Report", required=True)
    parser.add_argument("-g", "--graph_output", default="contamination_graph.pdf", help="Contamination graph file name")
    parser.add_argument(
        "-e",
        "--contamination_estimation_output",
        default="contamination_estimation_output.txt",
        help="Contamination estimation file name",
    )
    options = parser.parse_args()

    return options


def process_df(df, values):
    euk_total = values["Eukaryota"]
    known_euks = values["Human"] + values["Fungi"] + values["Plant"]
    values["Other Eukaryota"] = round(max(euk_total - known_euks, 0), 3)

    final_groups = {
        "Bacteria": values["Bacteria"],
        "Archaea": values["Archaea"],
        "Fungi": values["Fungi"],
        "Plant": values["Plant"],
        "Human": values["Human"],
        "Other Eukaryota": values["Other Eukaryota"],
        "Unclassified": values["Unclassified"],
    }

    result_df = pd.DataFrame(list(final_groups.items()), columns=["Group", "Percentage"])
    result_df = result_df[result_df["Percentage"] > 0]
    return result_df.sort_values(by="Percentage", ascending=True)


def create_plot(df, output):
    colors = df["Group"].map(GROUP_COLORS)

    xmax = df["Percentage"].max() * 1.15

    plt.figure(figsize=(10, 6))
    bars = plt.barh(df["Group"], df["Percentage"], color=colors, edgecolor="white")

    for bar in bars:
        width = bar.get_width()
        plt.text(width + xmax * 0.01, bar.get_y() + bar.get_height() / 2, f"{width:.2f}%", va="center", fontsize=11)

    plt.xlim(0, xmax)
    plt.title("Top-level Taxonomic Contamination", fontsize=16, fontweight="bold")
    plt.xlabel("Percentage (%)")
    plt.grid(axis="x", linestyle="--", alpha=0.6)
    plt.tight_layout()
    plt.savefig(output, format="pdf")


def estimate_contamination(values):
    human = values["Human"]
    unclassified = values["Unclassified"]
    contamination = round(100 - human - unclassified, 3)
    return contamination


def main():
    args = get_options()
    df = pd.read_csv(
        args.report,
        sep="\t",
        header=None,
        names=["percentage", "reads_clade", "reads_direct", "rank_code", "taxid", "name"],
    )

    values = {}
    for label, taxid in TAXIDS_TARGETS.items():
        row = df[df["taxid"].astype(str) == taxid]
        values[label] = round(float(row.iloc[0]["percentage"]) if not row.empty else 0.0, 3)

    processed_df = process_df(df, values)
    create_plot(processed_df, args.graph_output)
    contamination = estimate_contamination(values)
    with open(args.contamination_estimation_output, "w") as f:
        f.write(f"Contamination: {contamination:.2f}%\n")


if __name__ == "__main__":
    main()
