from setuptools import find_packages, setup

setup(
    name="nextflow-runner",
    version="0.1.0",
    author="Your Name",
    author_email="your.email@example.com",
    description="A Python script to run Nextflow pipelines with Docker, Conda, or GCP profiles.",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    install_requires=[
        "subprocess32",  # or 'subprocess' if using Python 3.5+
    ],
    entry_points={
        "console_scripts": [
            "nextflow-runner=runner:main",
        ],
    },
)
