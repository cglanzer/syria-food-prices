# ################################################################################################################################
# loess_arma_comparison_to_baseline.R
# This model first estimates the trend with LOESS (Local Polynomial Regression Fitting) and a fixed smoothing parameter,
# then fits a ARMA model to the remainder if possible, using auto.arima()
# 
# This file performs a comparison with the baseline model for arbitrary steps into the future and plots the score of both models.
# ################################################################################################################################

# More detailed model description:
# Let time_series be an arbitrary subdistrict.
# We fit loess() to log(time_series). Then, we calculate the remainder (what was not explained by our fitted trend) and
# search for a dependency structure (Autocorrelation, Partial autocorrelation). If there is a dependency structure,
# we fit an ARMA model (Autoregression / Moving Average model) using auto.arima() to determine the hyperparameters of this model.
# Note: There appears to be a bug in R, which is why we fit the auto.arima() model including an intercept term.
# This shouldn't have an influcence on the final result, though.

# Important notes:
# On this testing set, we actually outperform the baseline model a little!
# We have previously worked with a different testing set where this model was performing worse than the baseline model,
# so this is likely to be a random effect.

# TO RUN ENSURE THAT SETWD() IS SET TO THE FOLDER WHERE THIS FILE IS LOCATED :-)
# Package 'forecast': For auto.arima()
if (!require("forecast")) { install.packages("forecast"); }
library("forecast")

# SETTINGS, PLEASE CHANGE / ADAPT IF NEEDED
input_file = "../../data/processed/testing_data.csv"
debug_plots = TRUE # Default: True. Plots debug plots for every time series & step.
# The following variable specifies the range of 'into the future' steps that we should evaluate the model over.
# F.e., if you set this to "3", then the model is compared to the baseline model for a prediction of three steps into the future.
# If you set this to 5:2, the model is evaluated to the baseline model for a prediction of 5, 4, 3 and 2 steps into the
# future and the mean of the error is taken over those values.
testing_range=4:2

# Load the data
# Only the hyperparameters of this model were trained in advance and they are now
# fixed constants, so we might directly apply the model to the testing data.
data = read.csv(input_file, header=TRUE)
months = data[,1]
data = data[,-1] # Remove the 'months' column

# Scoring variables
score_total = 0
score_total_baseline = 0

for (col_ind in 1:dim(data)[2]) { # Iterate over all sub-districts in the testing set.
  
  score_current_ts = c() # Score for the current time series.
  score_current_ts_baseline = c() # Score for the baseline model for this time series.
  
  for (forecast.length in testing_range)
  {
    dat = na.omit(data[,col_ind])
    
    ts.orig = ts(dat)
    ts.log.orig = ts(log(dat)) # We perform a log-transformation
    
    training.window = 1:(length(dat)-forecast.length)
    forecast.window = (length(dat)-(forecast.length-1)):length(dat)
    
    ts.training = ts(dat[training.window])
    ts.log.training = ts(log(dat[training.window])) # log of the training data for the current time series.
    
    # Fit trend and calculate remainder
    # We fit a degree 1 trend with loess.
    loesstmp <- loess(ts.log.training~time(ts.log.training), degree = 1, span = 1, control=loess.control(surface="direct"))
    ts.log.fit.trend <- loesstmp$fitted
    ts.log.fit.trend.remainder <- loesstmp$residuals
    
    # Fit ARMA(p,q) via auto-fit to the remainder.
    ts.log.fit.arima = tryCatch({
      auto.arima(ts(ts.log.fit.trend.remainder), max.p = 12, max.q = 12, stationary = TRUE, ic = "aic", stepwise=FALSE)
    },
    error = function(err) {
      #print("No ARMA model estimated. Remainder has insignificant acf / pacf (auto.arima()).")
      return(FALSE)
    })
    with_arma=TRUE
    if (class(ts.log.fit.arima)[1] == "logical") { with_arma=FALSE } # It's FALSE if there's no suitable auto.arima() fit. This means that there was no sufficient dependency structure detected.
    
    # Calculate predictions, case by case analysis whether we have fitted an ARMA model or not. If not, we use only the trend estimate.
    ts.log.predict.trend = predict(loesstmp, newdata=forecast.window)
    if (with_arma) { ts.log.predict.arima <- predict(ts.log.fit.arima, n.ahead=length(forecast.window))$pred }
    if (with_arma) { ts.log.predict.total = ts.log.predict.trend + ts.log.predict.arima }
    if (!with_arma) { ts.log.predict.total = ts.log.predict.trend }
    
    # Exponentiate final prediction
    ts.predict.total = exp(ts.log.predict.total)
    
    # Calculate baseline model prediction, just repeating the last observed value.
    bslin_predict = rep(ts.orig[training.window[length(training.window)]], rep(length(forecast.window)))
    
    # Exponentiate to predict original data / model.
    if (debug_plots) {
      plot(ts.orig, type="o", ylim=c(min(ts.orig - 10), max(ts.orig)))
      if (with_arma) { title("Prediction using loess() and ARMA(p,q).") }
      if (!with_arma) { title("Prediction using loess(). No ARMA model fitted.") }
      lines(training.window, exp(predict(loesstmp, newdata=training.window)), type="o", col="blue")
      lines(forecast.window, ts.predict.total, col="red", type="o")
      lines(forecast.window, bslin_predict, col="orange", type="o")
      if (with_arma) { legend("topleft", bg="white", legend=c("Original data", "Trend in training data", "Model Prediction", "Baseline model"), lty=c(1,1,1,1), col=c("black", "blue", "red","orange")) }
      if (!with_arma) { legend("topleft", bg="white", legend=c("Original data", "Trend in training data", "Model Prediction", "Baseline model"), lty=c(1,1,1,1), col=c("black", "blue", "red","orange")) }
    }
    
    # Calculate score
    tmpmse = mean(abs((ts.orig[forecast.window] - ts.predict.total) / ts.orig[forecast.window])) # Note: Mean useless if forecast.window has length 1
    score_current_ts[length(score_current_ts) + 1] = tmpmse
    
    tmpmse = mean(abs((ts.orig[forecast.window] - bslin_predict) / ts.orig[forecast.window]))
    score_current_ts_baseline[length(score_current_ts_baseline) + 1] = tmpmse
  }

  score_total = score_total + mean(score_current_ts)
  score_total_baseline = score_total_baseline + mean(score_current_ts_baseline)
  print(paste("Model score for ", colnames(data)[col_ind], ": ", mean(score_current_ts), ", Baseline model: ", mean(score_current_ts_baseline), sep=""))
}
score_total_baseline = score_total_baseline / dim(data)[2]
score_total = score_total / dim(data)[2]

print(paste("Total averaged score for the model:", score_total))
print(paste("Total averaged score for the baseline model:", score_total_baseline))
