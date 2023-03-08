# meap
Multi-Electrode Array Pharmacology

Code for analyzing MED64 elecrophysiology data for pharamcology. The repo is divided into code written in R and Python.

__meapr/__   <- R package    
__meappy/__ <- python package


## One time setup
1) To get started with the MEAP analysis workflow first install the R meapr and python meappy packages:

    make install

2) Create data repository for MED64 analysis.

    cp -r MED64_Data /path/to/lab/data/repository
   
## Workflow for each experiment

   1) Update `MED64_ExperimentsForAnalysis.xlsx`
      Add metadata for experiment including date, sample information, and additional metadata
      
   2) Generate folders and parameter files for any newly added experiments

      python parameter_yaml.py
      
   3) Conduct MED64 experiment
   
   4) Sort spikes using SpyKING CIRCUS
   
   5) Export data from MED64
      process_           

   6) Manually copy exported files into experiment folders
      
