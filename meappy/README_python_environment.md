# Install & Run Python Scripts and Notebooks
## Installation of Python environment  
Follow these istructions to set up the python environment for running these scripts and Jupyter notebooks.

### Windows OS
Instructions to set up Python and Jupyter Lab environment on a Windows computer.   
[Download and install the Anaconda application for Windows](https://docs.anaconda.com/anaconda/install/windows/)   

These intructions will not use the "Navigator". Instead, it will use command line, using the application “Anaconda Powershell Prompt (anaconda 3)"   

In the terminal shell, go to the directory that will contain the python code to be run.   
Example:   
`cd C:\Users\fieldslab2\Desktop\Lab\MatLab\Python_Code`   

Create the new Anaconda __virtual environment__ for Jupyter Lab.    
This example names the virtual env "jupyterlab"   
`conda create --name jupyterlab python=3.10`

Activate the correct Anaconda virtual environment    
`conda activate jupyterlab`   

Install the modules required by this repo.  
__list last updated 2022-04-12__  
```
conda install jupyterlab
conda install matplotlib seaborn scipy
conda install pyyaml xlrd
```

Start the __Jupyter Lab__ application in a browser window using the terminal command:   
`jupyter lab`

## Run Jupyter Lab notebooks
### Windows OS
Open terminal window with application “Anaconda Powershell Prompt (anaconda 3)"   
Use command line in terminal window to go to your local computer's Python code folder.    
Example:   
`cd C:\Users\fieldslab2\Desktop\Lab\MatLab\Python_Code`

Activate the anaconda virtual environment for Jupyter notebooks   
`conda activate jupyterlab`   

Use command line to start __Jupyter Lab__ application in browser window   
`jupyter lab`

Within the Browswer Application of Jupyter Lab, you can use the left sidebar to navigate to the Jupyter notebook and open it.
Read the [The JupyterLab Interface](https://jupyterlab.readthedocs.io/en/stable/user/interface.html) documents for details.   
