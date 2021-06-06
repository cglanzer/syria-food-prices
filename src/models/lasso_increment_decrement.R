# ########################################################################
# This scripts checks whether random, artificial data is more likely
# to be chosen to predict increasing / decreasing SMEB values
# than other districts. This should give us an idea on whether
# there is a trend-setting district or not.
# This model only works with 'increasing' / 'decreasing' SMEB.
# ########################################################################

# We start by converting the district data into data which signalizes whether the
# price increased (1) or decreased (or stayed the same) (0). Then, we use this data to perform an autoregressive model:
# We aim to predict whether a certain district will have increased or decreased costs in the next month
# by using the data of all previous increasements / decreasements.
# We use autoregression, i.e., the the predictors are the other districts with 1, 2, ... time steps 'shifted' in the past.

 # Package glmnetUtils: Provides a formula interface for glmnet. glmnet gives us the lasso model.
if (!require("glmnetUtils")) { install.packages("glmnetUtils"); }
library("glmnetUtils")

set.seed(1234)

# IMPORTANT NOTE: Please ensure that getwd() is set to the folder where this file is located.

# This function helps to "fix" the following annoying problem in R:
# For a > b, a:b is not NULL but yields a series running backwards.
linspace = function(a,b) {
  if (a <= b) {
    return(c(a:b));
  }
  else {
    return(c())
  }
  return(c())
}

# Settings
input_file = "../../data/processed/imputed_training_data.csv"
steps_in_the_past = 2 # Max Lag of the autoregressive model.

# We focus on the subdistricts for which we have most of the data available.
# We justify this choice as follows: The imputed data is created according to extrapolation techniques and this dependency
# structure could be caught by this model and lead to wrong results.
indices_of_interest = c("SY020001", "SY020004", "SY020400", "SY020405", "SY020600", "SY070002", "SY070003", "SY070005", "SY070200", "SY070301", "SY070303", "SY070304", "SY070305", "SY070402", "SY070403", "SY070500", "SY070501")

random_districts = 20 # To back up our argument that this model doesn't give any valuable results, we add 'random' districts to the data, which are then surprisingly chosen by the model as better predictors than the actual shifted data. Choose the amount here.

data = read.csv(input_file, header=TRUE)
data = data[,-1] # Remove the 'month' column
data = data[-(1:3),indices_of_interest]

# Prepare the data: Change the input matrix to the matrix of increase / decreasements.
incrdata = matrix(rep(0, dim(data)[2] * (dim(data)[1] - 1)), ncol=dim(data)[2])
for (j in 1:dim(data)[2]) {
  for (i in 1:(dim(data)[1]-1)) {
    if (data[i+1,j] > data[i,j]) {
      incrdata[i,j] = 1
    } else { incrdata[i,j] = 0 }
  }
}
colnames(incrdata) = colnames(data)

final_actual = 0 # Total means of weights over all districts as response variables.
final_rnd = 0
total_sum_weights = rep(0, length(indices_of_interest)*steps_in_the_past) # Total sum of coefficients for non-random data.

for (i in 1:length(indices_of_interest)) { # Average over all response variables
  response_dist <- indices_of_interest[i] # The response variable; We try to predict this district.
  
  response <- incrdata[-c(1:steps_in_the_past),response_dist]
  length_predictor = length(response)
  
  # Build predictors
  predictor_matrix = rep(0, length(response)) # Dummy with right dimension, helps building the matrix. We remove this column afterwards.
  for (j in linspace(0, steps_in_the_past-1)) {
    window = 1:length_predictor # Data we select
    temp = incrdata[j + window,]
    colnames(temp) = paste(colnames(incrdata), "l",steps_in_the_past - j, sep=".")
    predictor_matrix = cbind(predictor_matrix, temp)
  }
  predictor_matrix = predictor_matrix[,-1] # Remove Dummy
  
  # Add random stuff
  for (i in 1:20) {
    rnd = rbinom(dim(predictor_matrix)[1], 1, 0.5)
    predictor_matrix = cbind(predictor_matrix, rnd)
  }
  
  data = data.frame(response, predictor_matrix)
  
  # The following fits a lasso model. We dont fit a mean as we predict and work with binary vectors.
  fit <- glmnet(response~.-1, family="binomial", data=data)
  
  # Some additional plots that could be of interest.
  #plot(fit) # Would give you an evolution of the non-zeroness of predictor coefficients vs. regularization parameter.
  #print(coef(fit, s = fit$lambda[10]))
  #print("This shows the coefficients chosen for a certain smoothing parameter (feel free to change in script). The absolut value of the values corresponds directly to their significance in the model. As can be seen here, it's almost only random predictors that are seen to be significant.")
  #print("To get a better view of how 'important' the random predictors are, we run through all smoothing parameters and sum up the total weight of the random predictors vs. the total weight of the actual data.")
  
  total_rnd = 0
  total_actual = 0
  for (i in 1:length(fit$lambda)) {
    fit.for.lambda = coef(fit, s=fit$lambda[i])
    total_actual = total_actual + mean(abs(as.numeric(fit.for.lambda)[2:(length(indices_of_interest)*steps_in_the_past + 1)]))
    total_rnd = total_rnd + mean(abs(as.numeric(fit.for.lambda)[-c(1:(length(indices_of_interest)*steps_in_the_past + 1))]))
  }
  total_actual = total_actual / length(fit$lambda)
  total_rnd = total_rnd / length(fit$lambda)
  
  # Add to 'total' mean, i.e., where we iterate over all response variables.
  final_actual = final_actual + total_actual / length(indices_of_interest)
  final_rnd = final_rnd + total_rnd / length(indices_of_interest)
}

barplot(c(final_actual, final_rnd), names.arg=c("Mean weight of actual predictors", "Mean weight of random predictors"), main="Lasso predicts if price increases or decreases: real vs. artificial data.")
