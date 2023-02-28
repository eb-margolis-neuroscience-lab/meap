from gettext import install
from setuptools import setup
import os

lib_folder = os.path.dirname(os.path.realpath(__file__))
requirement_path = lib_folder + '/requirements.txt'
install_requires = []
if os.path.isfile(requirement_path):
    with open(requirement_path) as f:
        install_requires = f.read().splitlines()


exec(open("meappy/version.py").read())

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()


setup(
    name="meappy",
    include_dirs=["meappy"],
    version=__version__,
    description="Python package for pharmacology analysis of multi-electrode array experiemnts",
    author="Walter German",
    author_email="pwaltergerman@gmail.com",
    url="https://github.com/eb-margolis-neuroscience-lab/meap",
    license="MIT",
    packages=["meappy"],
    install_requires = install_requires,
    package_data={'meappy': ['data//20211109_15h09m07s_test/unit_electrode.tsv', 
                             'data/20211109_15h09m07s_test/units_ts.ts']},
    data_files=[('my_data', ['data//20211109_15h09m07s_test/unit_electrode.tsv', 
                             'data/20211109_15h09m07s_test/units_ts.ts'])],
    long_description=long_description,
    long_description_content_type="text/markdown",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Topic :: Scientific/Engineering :: Chemistry",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
        "Typing :: Typed",
    ],
)
