# Gold-Price-Forecasting-with-Time-Series-Model

This project explores time series forecasting techniques applied to gold prices. The focus lies on understanding how classical statistical models perform on financial data and what insights they can provide.

## Project Overview

Gold is widely used as a hedge against uncertainty, but its price is influenced by a combination of macroeconomic, geopolitical, and market-specific factors. This makes forecasting challenging.

The goal of this project is to:

- Analyze historical gold price behavior
- Apply time series models
- Evaluate how well these models capture trends and generate forecasts

The focus is on learning model behavior and limitations rather than building a production-ready system.

## Dataset 

The dataset that utilized can be found here: <a href="https://www.kaggle.com/datasets/sahilwagh/gold-stock-prices" style="text-decoration: underline;">here</a>
- Source: Kaggle
- Time range: January 2014 – January 2024
- Original frequency: Daily
- Used features:
 -- `Date`
 -- `Close price`

Data was aggregated to monthly frequency by selecting the last available price of each month.

## Approach

The analysis follows a standard time series workflow:

- Data transformation (log transformation, differencing)
- Stationarity testing (ADF, KPSS)
- Decomposition (trend, seasonality, residuals)
- Structural break analysis (COVID-19 period)
- Model implementation and comparison

Models used:

- ARIMA
- ETS (Exponential Smoothing)
- Naive benchmark

## Key Insights

- Gold prices show a strong long-term upward trend
- No consistent seasonality was detected
- ARIMA behaves like a random walk, producing flat forecasts
- ETS captures trend more effectively and performs better overall
- All models struggle to reflect real market volatility

## Practical Implications

- Gold is often used for risk management and portfolio diversification
- Understanding model limitations is important for realistic expectations
- Simple statistical models may not be sufficient for volatile financial markets
- Forecasts should be interpreted cautiously and combined with external factors

## Tools Used

- R
- forecast, fpp2, fpp3
- ggplot2, dplyr

## Project Structure

- gold_price_forecasting.ipynb → main analysis
- gold_price_forecasting_report.pdf → full report
- README.md → project overview

## Report

A detailed explanation of the methodology, model selection, and evaluation is available in:

gold_price_forecasting_report.pdf

## Notes

This project was developed as a learning exercise in time series analysis. The focus is on applying core concepts, interpreting results, and understanding the limitations of classical forecasting models in financial contexts.




