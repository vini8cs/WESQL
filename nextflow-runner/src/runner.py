import argparse
import subprocess


def main():
    parser = argparse.ArgumentParser(description="Run a Nextflow pipeline.")
    parser.add_argument(
        "--profile",
        choices=["docker", "conda", "gcp"],
        required=True,
        help="Specify the profile to use for the Nextflow pipeline.",
    )
    parser.add_argument("--input", required=True, help="Input directory for the Nextflow pipeline.")
    parser.add_argument("--output", required=True, help="Output directory for the Nextflow pipeline.")

    args = parser.parse_args()

    # Construct the Nextflow command
    command = [
        "nextflow",
        "run",
        "main.nf",  # Assuming main.nf is in the current directory
        "-profile",
        args.profile,
        "-input",
        args.input,
        "-output",
        args.output,
    ]

    # Run the Nextflow command
    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running Nextflow: {e}")


if __name__ == "__main__":
    main()
