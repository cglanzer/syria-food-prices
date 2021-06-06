## Description of the model files
Before running any of the models in R, please ensure that the working directory (getwd()) is set to /src/models such that the relative paths work correctly. This can be done by using setwd().

### File 1: lasso_increment_decrement.R:
This scripts checks whether random, artificial data is more likely to be chosen to predict increasing / decreasing SMEB values in comparison to 'real' data (all other subdistricts). This should give us an idea on whether there is a trendsetting district or not. 
Run this script to generate the plot "Linear Model: Real vs Artifitial Data" of the report.

- Necessary packages: glmnetUtils, should be installed automatically if unavailable.

To run this script, open a terminal and run 
> $ R

> source("lasso_increment_decrement.R")


### File 2: loess_arma_model.R
This model first estimates the trend with LOESS (Local Polynomial Regression Fitting) and a fixed smoothing parameter, then fits an ARMA model to the remainder if possible, using auto.arima().
loess_arma_model.R provides a function which can be used to make custom predictions using this model.

- Necessary packages: forecast, should be installed automatically if unavailable.

To run this script, open a terminal and run
> $ R

> source("loess_arma_model.R")

Now, you have access to the function forecast_arma_loess(), which can be used to make custom predictions using this model. Please open the file and read the comments on top on how to use this function (parameters etc.).
If you forecast several time series, press ENTER to shift between the plots.


### File 3: loess_arma_comparison_to_baseline.R:
This script compares the LOESS-ARMA model above to the baseline model. Run this script to generate the respective plot in the report.

- Necessary packages: forecast, should be installed automatically if unavailable.

To run this script, open a terminal and run
> $ R

> source("loess_arma_comparison_to_baseline.R")

