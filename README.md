# Gold Price Forecasting with Time Series Models

This project explores time series forecasting techniques applied to gold prices. The focus is on understanding how classical statistical models perform on financial data and what insights they can provide.

---

## Project Overview

Gold is widely used as a hedge against uncertainty, but its price is influenced by macroeconomic, geopolitical, and market-specific factors. This makes forecasting challenging.

**Objectives:**
- Analyze historical gold price behavior  
- Apply time series models  
- Evaluate how well these models capture trends and generate forecasts  

This project is designed as a learning exercise, focusing on model behavior and limitations rather than production deployment.

---

## Dataset

Dataset available on Kaggle:  
https://www.kaggle.com/datasets/sahilwagh/gold-stock-prices  

**Details:**
- Source: Kaggle  
- Time range: January 2014 – January 2024  
- Original frequency: Daily  

**Features used:**
- `Date`  
- `Close` (closing price) 

Data was aggregated to **monthly frequency** by selecting the last available price of each month.

---

## Approach

The analysis follows a standard time series workflow:

**Preprocessing and analysis:**
- Log transformation and differencing  
- Stationarity testing (ADF, KPSS)  
- Decomposition (trend, seasonality, residuals)  
- Structural break analysis (COVID-19 period)  

**Models used:**
- ARIMA  
- ETS (Exponential Smoothing)  
- Naive benchmark  

---

## Key Insights

- Gold prices show a strong long-term upward trend  
- No consistent seasonality was detected  
- ARIMA behaves like a random walk, producing flat forecasts  
- ETS captures trend more effectively and performs better overall  
- All models struggle to reflect real market volatility  

---

## Practical Implications

- Gold is widely used for portfolio diversification and risk management  
- Model limitations must be considered when interpreting forecasts  
- Classical statistical models may not capture complex market dynamics  
- Forecasts should be combined with external economic information  

---

## Tools Used

- R  
- `forecast`, `fpp2`, `fpp3`  
- `ggplot2`, `dplyr`  

---

## Project Structure

```
gold-price-forecasting/
│
├── README.md
├── gold_price_forecasting.R
└── gold_price_forecasting_report.pdf
```

---

## Report

A detailed explanation of the methodology, model selection, and evaluation is available in: `gold_price_forecasting_report.pdf`

---

## Notes

This project was developed as a learning exercise in time series analysis. The focus is on applying core concepts, interpreting results, and understanding the limitations of classical forecasting models in financial contexts.
