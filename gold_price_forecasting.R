# -------------------------------------------------------------------------------------
# Download all necessary packages
# -------------------------------------------------------------------------------------
install.packages("feasts")
install.packages("fabletools")

# Importing libraries
library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(tsibble)
library(feasts)
library(forecast)
library(fpp2)
library(fpp3)

# -------------------------------------------------------------------------------------
# Import and arrange the dataset
# -------------------------------------------------------------------------------------
# Reading the csv file from my path

df <- read_csv("/Users/user/Documents/Personal Information/Studies/MSc CBS/2nd semester/Predictive Analytics/Final Project/dataset/goldstock v1.csv")

df

# Select only Date and Close columns, and sort by Date
df <- df %>%
  select(Date, Close) %>%
  arrange(Date)

# Remove duplicate rows based on all columns
df_unique <- df %>% distinct()

df_monthly <- df %>%
  select(Date, Close) %>%               # keep only relevant columns
  mutate(Month = yearmonth(Date)) %>%          # convert to yearmonth class for monthly grouping
  group_by(Month) %>%
  summarise(Close = last(Close)) %>%    # use last close price of the month (can change to mean() if preferred)
  ungroup() %>%
  as_tsibble(index = Month)                     # convert to tsibble with Month as index


df_monthly <- df_monthly %>%
  filter(Month <= yearmonth("2023 Dec"))

# Final Dataset
df_monthly

# -------------------------------------------------
# Initial Data Exploration and Visualization
# -------------------------------------------------

# Initial plot inspection
autoplot(df_monthly) +
  ggtitle("Montlhy Gold Stock Price") +
  theme_minimal()
# Increasing trend with intense fluctuations all over the period

# Seasonality plot on these data
gg_season(df_monthly) +
  ggtitle("Close Price per Year") +
  xlab("Monthly") +
  ylab("Close Price") +
  theme_minimal()
# No obvious seasonality exists

# Autocorrelation plot
acf(df_monthly, main = "Autocorrelation of Close Prices") + theme_minimal()
# Gradually decrease starting from 1.0 until 0.5
# Sign of strong dependence between lags -> past values have long-lasting influence
# Non stationarity -> mean is changing over time as in stationary it drops sharply to zero
# Conclusion: No seasonal spikes

pacf(df_monthly, main="Partial Autocorrelation of Close Prices") + theme_minimal()
# No sign of seasonal spikes at lag 12 or multiples

# -------------------------------------------------
# Classical Decomposition - raw data
# -------------------------------------------------

# Additive method
df_monthly %>%
  model(classical_decomposition(Close, type = "additive")) %>%
  components() %>%
  autoplot() +
  ggtitle("Classical Decomposition - Additive Method") +
  theme_minimal()

# Multiplicative method
df_monthly %>%
  model(classical_decomposition(Close, type = "multiplicative")) %>%
  components() %>%
  autoplot() +
  ggtitle("Classical Decomposition - Multiplicative Method") +
  theme_minimal()

# Upward trend
# Seasonal graph: 
# -> This is a relatively low-amplitude seasonal component, small compared to price levels (~1000–2000).
# -> There's no strong or sharp pattern — more like mild noise or fluctuations.
# -> Conclusion: Very weak seasonality, if any. This is not strong enough to require a seasonal model.
# Random graph is white noise


# --------------------------
# Transformation: Box - Cox
# --------------------------

# Implementing Guererro to find the most optimal lambda
lambda <- df_monthly %>%
  features(Close, features = guerrero)
# Lambda is equal to: -0.3407605

# Boc Cox with the optimal lambda
bc_transformed <- df_monthly %>%
  mutate(Close = box_cox(Close, lambda))

autoplot(bc_transformed, Close) +
  ggtitle("Box-Cox Transformed Close Prices") +
  theme_minimal()

# Box-Cox transformed ACF
bc_transformed %>%
  ACF(Close) %>%
  autoplot() +
  ggtitle("ACF of Box-Cox Transformed Close Prices") +
  theme_minimal()

# Box-Cox transformed PACF
bc_transformed %>%
  PACF(Close) %>%
  autoplot() +
  ggtitle("PACF of Box-Cox Transformed Close Prices") +
  theme_minimal()

# Seasonality plot
gg_season(bc_transformed) +
  ggtitle("Seasonality plot - box-cox transformed data") +
  xlab("Monthly") +
  ylab("Close Price") +
  theme_minimal()

# --------------------------
# Transformation: Log
# --------------------------

log_df <- df_monthly %>%
  mutate(Close=log(Close)) %>%
  filter(!is.na(Close))
  
autoplot(log_df) +
  ggtitle("Log Transformation") +
  theme_minimal()

# --------------------------
# STL Decomposition - transformed data 
# --------------------------

# stl requires ts
# Convert df into ts
ts_log_monthly <- ts(log_df$Close, frequency = 12, start = c(2014, 1))  # Starting from the first observation

stl_log_decom <- stl(ts_log_monthly, s.window = "periodic")

# Plot 
stl_log_decom %>%
  autoplot() +
  ggtitle("STL Decomposition (transformed data)") +
  theme_minimal()

# -------------------------------------------------------------------------------------
# Tests 
# -------------------------------------------------------------------------------------

# We convert the initial data to ts for performing the ADF test later
start_year <- year(min(log_df$Month))
start_month <- month(min(log_df$Month))

ts_monthly <- ts(log_df$Close,
                 start = c(start_year, start_month),
                 frequency = 12)

# --------------------------
# KPSS
# --------------------------

log_df %>%
  features(Close, unitroot_kpss)
# kpss_pvalue (=0.01) < 0.05, which means we reject H0, they are non-stationary

log_df %>%
  features(Close, unitroot_ndiffs)
# The ndiffs=1 result means that differencing the data 1 time is enough to succeed stationarity.

# --------------------------
# ADF
# --------------------------

# Load the required package
library(tseries)

# Perform the ADF test
adf_result <- adf.test(ts_monthly)

# Print the result
adf_result

# P-value = 0.2702 > 0.05 which means that we fail to reject the null hypothesis, therefore the data are not stationary. 

# So, both of these tests end up to the result that the data are not stationary. 
# However, KPSS is a most accurate test as it assumes stationarity by default and looks for evidence of non-stationarity. 
# In other words, it tries to reject stationarity!!!

# -------------------------------------------------------------------------------------
# Stationarity
# -------------------------------------------------------------------------------------

df_monthly_diff <- log_df %>%
  mutate(Close = difference(Close)) %>%
  filter(!is.na(Close))
# Apply difference 1 time as the unitroot_ndiffs showed us to succeed stationarity

df_monthly_diff %>%
  features(Close, unitroot_kpss) 
# kpss_pvalue (=0.1) > 0.05, which means we fail to reject H0 - the data are now stationary

df_monthly_diff %>%
  features(Close, unitroot_ndiffs)
# The data are now stationary and ndiffs = 0 (we are good to go)

# Plot
autoplot(df_monthly_diff) +
  ggtitle("Plot - Differenced data") +
  theme_minimal()

df_monthly_diff %>%
  ACF(Close) %>%
  autoplot() +
  ggtitle("ACF of Log Transformed & Differenced Close Prices") +
  theme_minimal()
# It’s also visible from the ACF graph that we succeed stationarity as it exhibits a rapid decay. 
# The zero lag is exactly one, simply because it is correlated 100% with itself, but later we don’t identify any pattern which means white noise. 

df_monthly_diff %>%
  PACF(Close) %>%
  autoplot() +
  ggtitle("PACF of Log Transformed & Differenced Close Prices") +
  theme_minimal()
# Similar to ACF, the PACF now is stationary as it also experiences rapid decay to negative, and random spikes later, which do not have a specific pattern for showing correlation.

# Interpretation of manual check and define of ARIMA model's parameters through ACF-PACF
# ARIMA(p,d,q)(P,D,Q)[m]
# p = non-seasonal autoregressive (AR) order
# d = non-seasonal differencing order
# q = non-seasonal moving average (MA) order
# P = seasonal AR order
# D = seasonal differencing order
# Q = seasonal MA order
# m = seasonal period (e.g., 12 for monthly data with annual seasonality)

# Because of no strong evidence of seasonality -> P=D=Q=0 (seasonal parameters), m=1

# p:
# From the PACF plot, lag 1 between the intervals (not significant) and negative.
# This suggests that there is no presence of an autoregressive relationship with the first lag.
# In general partial autocorrelation is random - not existence of a specific pattern/correlation between lags
# -> p = 1

# d:
# 1st difference to the data
# -> d = 1 (we have are gonna use just the log-transformed data before differencing)

# q:
# From the ACF plot, there is also no significant lag
# -> q = 0

# Final ARIMA model:
# -> ARIMA(0,1,0)(0,0,0)[1]

# -------------------------------------------------------------------------------------
# ARIMA model & Forecast
# -------------------------------------------------------------------------------------

fit_010000 <- log_df %>%
  filter_index(~ "2022 Dec") %>%  # Train set from 2014 to 2022
  model(
    arima010000 = ARIMA(Close ~ pdq(0,1,0) + PDQ(0,0,0) + 0)
  )
# Used the log transformed data and not the log & differenced because we apply diff in arima model (d=1)

fit_010000 %>% pivot_longer(everything(), 
                            names_to = "Model name",
                            values_to = "Orders")

glance(fit_010000) %>% 
  arrange(AICc) %>%
  select(.model:BIC)
# The target is to minimize the AIC (AIC=-389)

# Check the residuals
fit_010000 %>%
  select(arima010000) %>%
  gg_tsresiduals()
# Residuals plot look like white noise
# ACF plot show no autocorrelation between lags
# The residuals are slightly left skewed - not that bad

# Ljung Box test
augment(fit_010000) %>%
  filter(.model == "arima010000") %>%
  features(.innov, ljung_box, lag = 10, dof = 0) # dof = degrees of freedom = p + q = 2
# p-value of Ljung-Box = 0.780 > 0.05 which means that the residuals don't appear correlation on short term (lag = 10)
# However, we are gonna test autoarima to see the results and we are also gonna experimenting with a couple of different arimas (random parameters)


fit_auto <- log_df %>%
  filter_index(~ "2022 Dec") %>%  # Train set from 2014 to 2022
  model(
    auto = ARIMA(Close, stepwise = FALSE, approx = FALSE),
    arima111000 = ARIMA(Close ~ pdq(1,1,1) + PDQ(0,0,0) + 0),
    arima112000 = ARIMA(Close ~ pdq(1,1,2) + PDQ(0,0,0) + 0),
    arima211000 = ARIMA(Close ~ pdq(2,1,1) + PDQ(0,0,0) + 0),
    arima212000 = ARIMA(Close ~ pdq(2,1,2) + PDQ(0,0,0) + 0)
  )

fit_auto %>% pivot_longer(everything(), 
                          names_to = "Model name",
                          values_to = "Orders")
# autoARIMA - 0,1,0, as we initially thought

glance(fit_auto) %>% 
  arrange(AICc) %>%
  select(.model:BIC)
# It seems that auto is tied with mine
# Lower AIC / AICc = better fit (penalizes complexity).
# Lower BIC = stronger penalty for complexity (good for simpler models).
# Lower sigma² = lower residual variance (better prediction accuracy).
# Prefer simpler models if performance difference is very small.

# Check the residuals of auto arima
fit_auto %>%
  select(auto) %>%
  gg_tsresiduals()
# Again residuals plot look like white noise
# ACF plot show no autocorrelation between lags 
# The residuals are normally distributed

# Ljung Box test
augment(fit_auto) %>%
  filter(.model == "auto") %>%
  features(.innov, ljung_box, lag = 10, dof = 0) # dof = degrees of freedom = p(=0) + q(=0) = 0
# p-value of Ljung-Box = 0.780 > 0.05 which indicate even less autocorrelation of lags than the other arima model
# Since p-values are greater than the usual significance level (0.05), we fail to reject the null hypothesis for both models.
# This means there is no significant autocorrelation left in the residuals, so the models adequately capture the autocorrelation structure in the data.
# Conclusion:
  # Both the auto model and the arima101000 model pass the Ljung-Box test for residual autocorrelation, indicating they fit the data well in terms of residual independence.
  # Neither model shows signs of inadequacy in this respect, so Ljung-Box does not favor one model strongly over the other here.

# --------------------------
# Autoarima forecast
# --------------------------

# Fit ARIMA model on data up to 2022 Dec
fit_auto <- log_df %>%
  filter_index(~ "2022 Dec") %>%
  model(auto = ARIMA(Close ~ 0 + pdq(0,1,0) + PDQ(0,0,0)))

# Forecast for 1 year (12 months) from 2023 Jan to 2023 Dec
fc <- fit_auto %>%
  forecast(h = "12 months")

# Filter actual data for 2023 to compare accuracy
df_actual_2023 <- log_df %>%
  filter_index("2023 Jan" ~ "2024 Jan")

# Calculate accuracy
accuracy(fc, df_actual_2023)

# Plot forecast and actuals
fc %>%
  autoplot(log_df) +
  ggtitle("AutoArima Forecast - 1 year") +
  theme_minimal()

# -------------------------------------------------------------------------------------
# ETS model & Forecast
# -------------------------------------------------------------------------------------

# --------------------
# Auto ETS
# --------------------
# Fit ETS model on data up to 2022 Dec
fit_ets_auto <- log_df %>%
  filter_index(~ "2022 Dec") %>%
  model(ETS(Close))

# Decompose the ETS model into components
components(fit_ets_auto) %>%
  autoplot() +
  ggtitle("ETS Model Components (Trend, Seasonality, Error)")

glance(fit_ets_auto) %>% 
  arrange(AICc) %>%
  select(.model:BIC)

# Check the residuals
fit_ets_auto %>%
  gg_tsresiduals()

report(fit_ets_auto)

# --------------------
# Forecast
# --------------------

# Forecast for 1 year (12 months) from 2023 Jan to 2023 Dec
fc_ets <- fit_ets_auto %>%
  forecast(h = "12 months")

# Calculate accuracy for ETS
accuracy(fc_ets, df_actual_2023)

# Plot forecast and actuals
fc_ets %>%
  autoplot(log_df) +
  ggtitle("Auto ETS Forecast - 1 year") +
  theme_minimal()


# --------------------
# Manual ETS
# --------------------
fit_ets <- log_df %>%
  filter_index(~ "2022 Dec") %>%
  model(
    etsAAN = ETS(Close ~ error("A") + trend("A") + season("N")),
    etsMMN = ETS(Close ~ error("M") + trend("M") + season("N"))
  )

# Decompose the ETS model into components
components(fit_ets) %>%
  autoplot() +
  ggtitle("ETS Model Components (Trend, Seasonality, Error)")

glance(fit_ets) %>% 
  arrange(AICc) %>%
  select(.model:BIC)

fit_ets %>%
  select(etsAAN) %>%
  gg_tsresiduals()

fit_ets %>%
  select(etsMMN) %>%
  gg_tsresiduals()

# --------------------
# Forecast
# --------------------

fc_ets_manual <- fit_ets %>%
  forecast(h = "12 months") %>%
  filter_index("2023 Jan" ~ "2024 Jan")

accuracy(fc_ets_manual, df_actual_2023)

fc_ets_manual %>%
  autoplot(log_df) +
  ggtitle("Manual ETS Forecast - 1 year") +
  theme_minimal()

# --------------------
# Naive method
# --------------------

fit_naive <- log_df %>%
  filter_index(~ "2022 Dec") %>%
  model(NAIVE(Close))

# Generate forecast for 12 months ahead (you can change h = 12)
fc_naive <- fit_naive %>%
  forecast(h = "12 months")

# View the forecast table
fc_naive

# Plot the forecast
fc_naive %>%
  autoplot(log_df) +
  ggtitle("Naïve Forecast for Gold Prices (log scale)") +
  theme_minimal()

accuracy(fc_naive, df_actual_2023)

# -------------------------------------------------------------------------------------
# Structural Breaks and Arima
# -------------------------------------------------------------------------------------

install.packages("strucchange")
library(strucchange)

start_ym <- as.yearmon("2014 Jan", format = "%Y %b")
target_ym <- as.yearmon("2020 Feb", format = "%Y %b")

# Calculate the number of months difference + 1 for 1-based indexing
time_index <- as.numeric(12 * (floor(target_ym) - floor(start_ym)) + 
                           (cycle(target_ym) - cycle(start_ym))) + 1

print(time_index)  # Gives index of 2020 Feb relative to 2014 Jan

data <- log_df$Close
time <- 1:length(data)

chow_test_result <- sctest(data ~ time, type = "Chow", point = 74)
print(chow_test_result)


data_ts <- ts(log_df$Close, frequency = 12, start = c(2014, 1))


# Segment 1: From start up to break (including break point)
segment1 <- window(data_ts, end = c(2020, 2))  # 2020 Feb

# Segment 2: After the break
segment2 <- window(data_ts, start = c(2020, 3))  # 2020 Mar onward

fit_segment1 <- auto.arima(segment1)
fit_segment2 <- auto.arima(segment2)

checkresiduals(fit_segment1)
checkresiduals(fit_segment2)

fc_segment1 <- forecast(fit_segment1, h = 12)
fc_segment2 <- forecast(fit_segment2, h = 12)


autoplot(data_ts) + 
  autolayer(fc_segment1$mean, series = "Forecast Segment 1") +
  autolayer(fc_segment2$mean, series = "Forecast Segment 2") +
  ggtitle("Segmented Forecasts") +
  theme_minimal()

# END

