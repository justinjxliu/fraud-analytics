-- =========================================
-- 01. DATA QUALITY
-- =========================================

-- Findings:
-- - session_length_in_minutes has very low missingness (~0.2%).
-- - Missing values do not appear associated with elevated fraud rates.

-- missing session lengths
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE session_length_in_minutes = -1) AS missing_rows,
    COUNT(*) FILTER (WHERE session_length_in_minutes = -1) * 100.0 / COUNT(*) AS missing_pct
FROM baf_raw;

-- fraud rate for missing vs non-missing
SELECT
    CASE
        WHEN session_length_in_minutes = -1 THEN 'missing'
        ELSE 'non-missing'
    END AS missingness,
    COUNT(*) AS bucket_size,
    AVG(fraud_bool) AS fraud_rate
FROM baf_raw
GROUP BY missingness;


-- =========================================
-- 02. SUMMARY STATISTICS
-- =========================================

-- session_length_in_minutes summary
SELECT
    MIN(session_length_in_minutes) AS min_val,
    quantile_cont(session_length_in_minutes, 0.25) AS p25,
    quantile_cont(session_length_in_minutes, 0.50) AS median,
    quantile_cont(session_length_in_minutes, 0.90) AS p90,
    MAX(session_length_in_minutes) AS max_val
FROM baf_raw
WHERE session_length_in_minutes != -1;


-- =========================================
-- 03. FRAUD RELATIONSHIP
-- =========================================

-- session_length_in_minutes bucketed
WITH bounds AS (
    SELECT
        quantile_cont(session_length_in_minutes, 0.25) AS p25,
        quantile_cont(session_length_in_minutes, 0.50) AS median,
        quantile_cont(session_length_in_minutes, 0.75) AS p75
    FROM baf_raw
)
SELECT
    CASE
        WHEN session_length_in_minutes < p25 THEN 1
        WHEN session_length_in_minutes < median THEN 2
        WHEN session_length_in_minutes < p75 THEN 3
        ELSE 4
    END AS bucket,
    COUNT(*) AS bucket_size,
    AVG(fraud_bool) AS fraud_rate
FROM baf_raw
CROSS JOIN bounds
WHERE session_length_in_minutes != -1
GROUP BY bucket
ORDER BY bucket;


-- =========================================
-- 04. EXTREME VALUES
-- =========================================

-- smallest session_length_in_minutes
SELECT
    session_length_in_minutes,
    velocity_6h,
    name_email_similarity,
    customer_age,
    email_is_free,
    phone_home_valid,
    fraud_bool
FROM baf_raw
WHERE session_length_in_minutes != -1
ORDER BY session_length_in_minutes
LIMIT 10;

-- largest session_length_in_minutes
SELECT
    session_length_in_minutes,
    velocity_6h,
    name_email_similarity,
    customer_age,
    email_is_free,
    phone_home_valid,
    fraud_bool
FROM baf_raw
WHERE session_length_in_minutes != -1
ORDER BY session_length_in_minutes DESC
LIMIT 10;


-- =========================================
-- 05. INTERACTION EFFECTS
-- =========================================

-- Findings:
-- - Short-session/high-velocity applications do not exhibit elevated fraud rates.
-- - Fraud rate (~0.82%) is below the overall dataset baseline (~1.10%).
-- - No evidence of fraud enrichment was observed for the low-session/high-velocity segment examined.

WITH bounds AS (
    SELECT
        quantile_cont(session_length_in_minutes, 0.25) AS p25,
        quantile_cont(velocity_6h, 0.75) AS p75
    FROM baf_raw
)
SELECT
    COUNT(*) AS total_rows,
    SUM(fraud_bool) AS fraud_rows,
    AVG(fraud_bool) AS fraud_rate
FROM baf_raw
CROSS JOIN bounds
WHERE
    session_length_in_minutes != -1
    AND session_length_in_minutes < p25
    AND velocity_6h > p75
;

