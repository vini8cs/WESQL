# Nextflow Runner

This project provides a Python script to facilitate the execution of Nextflow pipelines with support for different execution profiles, including Docker, Conda, and Google Cloud Platform (GCP). 

## Features

- **Profile Selection**: Choose between Docker, Conda, or GCP profiles to run your Nextflow pipeline.
- **Input/Output Management**: Specify input and output directories for your pipeline runs.
- **Easy Execution**: Run Nextflow pipelines directly from the command line using a simple Python script.

## Requirements

- Python 3.x
- Nextflow
- Conda (if using the Conda profile)

## Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   cd nextflow-runner
   ```

2. Set up the Conda environment:
   ```
   conda env create -f environment.yml
   conda activate <environment-name>
   ```

3. Install the package:
   ```
   python setup.py install
   ```

## Usage

To run the Nextflow pipeline, use the following command:

```
python src/runner.py --profile <profile> --input <input_directory> --output <output_directory>
```

Replace `<profile>` with `docker`, `conda`, or `gcp`, and specify the appropriate input and output directories.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.
