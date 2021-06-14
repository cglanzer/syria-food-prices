## Forecasting the minimum cost of monthly survival during the Syrian war

It is becoming more popular for NGOs to provide cash-based assistance to people in war-torn countries such as Syria. Usually, it takes one month to deliver money to the local population. Unfortunately, the war leads to high fluctuations in the prices of everyday goods, which is why it is crucial to have reliable predictions for these prices in the upcoming months.

In this project, which was part of [*Hack4Good 2019* at ETH Zürich](https://analytics-club.org/wordpress/h4g-past-projects-autumn-2019/) we assisted [IMPACT Initiatives](https://www.impact-initiatives.org/), a Geneva-based NGO, by forecasting these price changes. This is joint work with Aneesh Dahiya, Jaco Fuchs and Julia Ortheden.

*Please note that while our code and findings are available in this repository, the data is, unfortunately, not public.*

### Project description and main challenges involved

IMPACT Initiatives provided us with the monthly prices of various goods in different areas of the country. The biggest challenges of this project were:

- **Missing data:** Around 60% of the data was missing. We relied on simple imputation techniques as a different team was assigned the task of tackling the problem of missing data. For our final model, we used their results which can be found [here](https://analytics-club.org/wordpress/wp-content/uploads/2021/04/Fall_2019_IMPACT_Final_Report_Imputation.pdf).

- **Data cleaning:** The data consists of the prices of many different items in different districts, sub-districts and sub-sub-districts of Syria. Out of this data, we extracted the cost of a *Survival Minimum Expenditure Basket (SMEB)*, which was the focus of our prediction models.

- **Little available data:** Monthly price data was available from February 2017 to August 2019 only, i.e., just a little over two years or 31 data points (per item, per location).

- **Short-term forecasting:** The high volatility of the prices made it difficult to have reliable predictions for one data point (= one month) into the future.

### Our results

- To evaluate our models, we compared them to a *baseline*-model, which predicts the same price for the next month.

- When predicting a single month into the future, we were unable to outperform this baseline model with more complex models.

- When predicting more than one month into the future, a combination of a local polynomial regression with an *ARMA*-model outperforms this baseline prediction and picks up on price trends.


### Structure of this repository

- A detailed **report** of our results can be found in: [/report/report.pdf](https://github.com/cglanzer/syria-food-prices/blob/master/report/report.pdf)

- Data cleaning was performed using pandas (Python), the scripts are in /src/data_cleaning.

- Our models (written in R) can be found in /src/models, including a README file which explains how to run them.

*Please note that unfortunately, the data is not public.*

![LOESS + ARMA(p,q) - Model](report/image1.png "LOESS + ARMA(p,q) - Model")
