## Data Extractor

#### Data-Analyser

Simply run analysis.py with following command line argument
````
--col= To select the columns to display (required)
--con = conditions to be specified on columns (optional)
--grp = group by conditions (optional)
--output = the filename where the results to be saved into (optional)
````

````
spark-submit analysis.py --col=<COL1,COL2> --con=<COL1,>,VALUE> --grp=<COL2> --fn=<DIR_NAME>
````


**Example:**
````
spark-submit analysis.py --col=MASTERYR,MONTH,BIASMO1EXTNEW,COUNT(OFFCOD1) --con=MASTERYR,>,2013 --grp=MASTERYR,MONTH,BIASMO1EXTNEW
````


#### Geolocation data 

**Prerequiste:**

* R with package `httr`, `jsonlite`

**Steps:**

1. Navigate inside geocode directory and make sure it has `cities.csv` and `geocode.R` 
2. Open R console
2. Run `source(‘geocode.R’)


#### Aggregated Script

For convenience we make it as a aggregated script. You can run part of it or the whole thing by simply executing
```bash
spark-submit analysis_script_collection.py
``` 

#### Frontend App

**Prerequisute:**
You need to [install R](https://cran.r-project.org/doc/manuals/r-release/R-admin.html) and the following R package to run the app. ``‘shiny’, 'plotly', 'shinydashboard', 'leaflet', 'leaflet.extras', 'shinycssloaders', 'reshape2' ``
Once you install R, to install the packages it simply run from R console

```
R> install.packages( c(‘shiny’, 'plotly', 'shinydashboard', 'leaflet', 'leaflet.extras', 'shinycssloaders', 'reshape2' ) )*
```

**Steps:**

* Clone [This repo](https://github.com/aringhosh/cmpt732-project.git) into your local system.
* Change directory to `Frontend_App` folder.
* Inside the `Frontend_App` folder, there should be two R files called `server.r` and `ui.r` and also a directory called `input2` which holds all the raw csv’s that the visualization app uses.
* While inside the parent folder of app (the original directory of the cloned git repo) simply open the R console and then from the R console, give the following command to start a local instance of the shiny app:
````
runApp('app/')
````
* This should run the app in your local system. You can also see a live demo of the app here: https://aringhosh.shinyapps.io/cmpt-732-us-crime/

