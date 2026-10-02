CREATE DATABASE demand_forecast_db;
USE demand_forecast_db;

-- Create the table that will hold the cleaned sales + forecast data from Python
CREATE TABLE demand_forecast (
    id INT,
    date DATE,
    store_nbr INT,
    family VARCHAR(50),
    sales DECIMAL(10,2),
    onpromotion INT,
    naive_forecast DECIMAL(10,2),
    forecast_error DECIMAL(10,2),
    abs_error DECIMAL(10,2),
    city VARCHAR(50),
    state VARCHAR(50),
    type VARCHAR(5),
    cluster INT
);

-- Check whether this MySQL session allows loading data from a local file
SHOW VARIABLES LIKE 'local_infile';

-- If the above shows OFF, turn it on for this session
SET GLOBAL local_infile = 1;

-- Load the cleaned CSV (built in Python) into the table
LOAD DATA LOCAL INFILE 'C:/Projects/Demand-Forecasting-Analysis/Exports/demand_forecast_clean.csv'
INTO TABLE demand_forecast
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, date, store_nbr, family, sales, onpromotion, naive_forecast, forecast_error, abs_error, city, state, type, cluster);

-- Double-check the row count loaded matches what Python exported
SELECT COUNT(*) FROM demand_forecast;

-- Forecast error (WAPE) by product category, to find which categories are hardest to forecast
SELECT 
    family,
    SUM(abs_error) AS total_abs_error,
    SUM(sales) AS total_actual_sales,
    ROUND(SUM(abs_error) / SUM(sales) * 100, 2) AS wape_percent
FROM demand_forecast
GROUP BY family
ORDER BY wape_percent DESC;

-- Forecast error (WAPE) by region (state), to find which regions are hardest to forecast
SELECT 
    state,
    SUM(abs_error) AS total_abs_error,
    SUM(sales) AS total_actual_sales,
    ROUND(SUM(abs_error) / SUM(sales) * 100, 2) AS wape_percent
FROM demand_forecast
GROUP BY state
ORDER BY wape_percent DESC;

-- Overall forecast error (WAPE) across the whole dataset, for the headline number
SELECT ROUND(SUM(abs_error) / SUM(sales) * 100, 2) AS overall_wape_percent
FROM demand_forecast;

-- Forecast error (WAPE) by sales volume tier, to check whether low-volume days
-- are genuinely harder to forecast than high-volume days
SELECT 
    CASE 
        WHEN sales = 0 THEN 'Zero Sales'
        WHEN sales <= 10 THEN 'Low (1-10)'
        WHEN sales <= 100 THEN 'Medium (11-100)'
        WHEN sales <= 500 THEN 'High (101-500)'
        ELSE 'Very High (500+)'
    END AS sales_tier,
    COUNT(*) AS num_rows,
    SUM(abs_error) AS total_abs_error,
    SUM(sales) AS total_actual_sales,
    ROUND(SUM(abs_error) / NULLIF(SUM(sales), 0) * 100, 2) AS wape_percent
FROM demand_forecast
GROUP BY sales_tier
ORDER BY total_actual_sales DESC;

-- Forecast error (WAPE) by month, to see if certain seasons are harder to forecast
SELECT 
    MONTH(date) AS month_num,
    SUM(abs_error) AS total_abs_error,
    SUM(sales) AS total_actual_sales,
    ROUND(SUM(abs_error) / SUM(sales) * 100, 2) AS wape_percent
FROM demand_forecast
GROUP BY MONTH(date)
ORDER BY month_num;

-- Get the total actual sales and total absolute forecast error
-- across the entire dataset, to use as summary KPI numbers on the dashboard
SELECT 
    SUM(sales) AS total_actual_sales,
    SUM(abs_error) AS total_absolute_error
FROM demand_forecast;