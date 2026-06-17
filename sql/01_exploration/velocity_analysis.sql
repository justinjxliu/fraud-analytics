-- =========================================
-- 01. SUMMARY STATISTICS
-- =========================================

-- velocity_6h summary
SELECT
    MIN(velocity_6h) AS min_val,
    quantile_cont(velocity_6h, 0.25) AS p25,
    quantile_cont(velocity_6h, 0.50) AS median,
    quantile_cont(velocity_6h, 0.90) AS p90,
    MAX(velocity_6h) AS max_val
FROM baf_raw;

-- velocity_24h summary
SELECT
    MIN(velocity_24h) AS min_val,
    quantile_cont(velocity_24h, 0.25) AS p25,
    quantile_cont(velocity_24h, 0.50) AS median,
    quantile_cont(velocity_24h, 0.90) AS p90,
    MAX(velocity_24h) AS max_val
FROM baf_raw;

-- velocity_4w summary
SELECT
    MIN(velocity_4w) AS min_val,
    quantile_cont(velocity_4w, 0.25) AS p25,
    quantile_cont(velocity_4w, 0.50) AS median,
    quantile_cont(velocity_4w, 0.90) AS p90,
    MAX(velocity_4w) AS max_val
FROM baf_raw;


-- =========================================
-- 02. VELOCITY RELATIONSHIPS
-- =========================================

-- burst_ratio summary
WITH burst_ratio_table AS (
    SELECT velocity_6h / velocity_24h AS burst_ratio
    FROM baf_raw
)
SELECT
    MIN(burst_ratio) AS min_val,
    quantile_cont(burst_ratio, 0.25) AS p25,
    quantile_cont(burst_ratio, 0.50) AS median,
    quantile_cont(burst_ratio, 0.90) AS p90,
    MAX(burst_ratio) AS max_val
FROM burst_ratio_table;


-- =========================================
-- 03. EXTREME VALUES
-- =========================================

-- largest burst_ratio
WITH enriched AS (
    SElECT 
        *,
        velocity_6h / velocity_24h AS burst_ratio
    FROM baf_raw
)
SELECT
    velocity_6h,
    velocity_24h,
    velocity_4w,
    burst_ratio,
    income,
    customer_age,
    name_email_similarity,
    fraud_bool
FROM enriched
ORDER BY burst_ratio DESC
LIMIT 10;


-- =========================================
-- 04. FRAUD COMPARISON
-- =========================================

-- burst_ratio split
WITH burst_ratio_fraud_bool_table AS (
    SELECT
        fraud_bool,
        velocity_6h / velocity_24h AS burst_ratio
    FROM baf_raw
)
SELECT
    fraud_bool,
    MIN(burst_ratio) AS min_val,
    quantile_cont(burst_ratio, 0.25) AS p25,
    quantile_cont(burst_ratio, 0.50) AS median,
    quantile_cont(burst_ratio, 0.90) AS p90,
    MAX(burst_ratio) AS max_val
FROM burst_ratio_fraud_bool_table
GROUP BY fraud_bool;

-- burst_ratio bucketed
WITH burst_ratio_fraud_bool_table AS (
    SELECT
        fraud_bool,
        velocity_6h / velocity_24h AS burst_ratio
    FROM baf_raw
)
SELECT
    CASE
        WHEN burst_ratio < 1 THEN 1
        WHEN burst_ratio < 3 THEN 2
        WHEN burst_ratio < 5 THEN 3
        WHEN burst_ratio < 7 THEN 4
        ELSE 5
    END AS burst_ratio_bucket,
    COUNT(*) AS bucket_size,
    AVG(fraud_bool) AS fraud_rate
FROM burst_ratio_fraud_bool_table
GROUP BY burst_ratio_bucket
ORDER BY burst_ratio_bucket;

