Program Setup

1) There are 4 instances of '[File Location]' within the program; 3 in the ModelSimulation class and one in the Solver class.
Change these to the appropriate address for where the project and related files are saved.

2) The NHS dataset is only required for data matching, if the user wishes to do so. 
The dataset needed can be downloaded from https://www.opendata.nhs.scot/dataset/covid-19-in-scotland/resource/287fc645-4352-4477-9c8c-55bc054b7e76
The current version online is constantly undergoing revisions and changes, so the dataset used in the project may be different to the current version.
This "outdated" version is also provided for convenience, if the user wishes to use the old dataset.

3) Install the latest version of NetLogo to your system - this can be found at https://ccl.northwestern.edu/netlogo/

4) Add the NetLogo library folder (netlogo-libraries) to the project dependencies. In IntelliJ this can be done through File -> Project Structure -> Libraries.

5) Set up a run configuration which uses the Solver class as its main class.

NetLogo Model Setup

1) Similarly to the program, there are 2 instances of '[File Location]' that must be changed to the appropriate address; 
these can both be found towards the start of the program and refer to the file that the model will create to store experiment results.