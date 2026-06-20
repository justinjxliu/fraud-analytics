-- =========================================
-- 01. DATA QUALITY
-- =========================================

-- Findings:
-- - prev_address_months_count is missing for ~71% of applications.
-- - Applications without a recorded previous address exhibit a substantially higher fraud rate (~1.42%) than applications with a recorded previous address (~0.31%).
-- - Missingness appears informative and should be treated as a potential signal rather than discarded.
-- - current_address_months_count has negligible missingness (~0.4%) and missingness does not appear associated with elevated fraud risk.

-- missing prev_address_months_count
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE prev_address_months_count = -1) AS missing_rows,
    COUNT(*) FILTER (WHERE prev_address_months_count = -1) * 100.0 / COUNT(*) AS missing_pct
FROM baf_raw;

-- fraud distribution
SELECT
    COUNT(*) AS total_rows,
    SUM(fraud_bool) AS fraud_rows,
    AVG(fraud_bool) AS fraud_rate,
    CASE
        WHEN prev_address_months_count = -1 THEN 'missing'
        ELSE 'non-missing'
    END AS missingness
FROM baf_raw
GROUP BY missingness;

-- missing current_address_months_count
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE current_address_months_count = -1) AS missing_rows,
    COUNT(*) FILTER (WHERE current_address_months_count = -1) * 100.0 / COUNT(*) AS missing_pct
FROM baf_raw;

-- fraud distribution
SELECT
    COUNT(*) AS total_rows,
    SUM(fraud_bool) AS fraud_rows,
    AVG(fraud_bool) AS fraud_rate,
    CASE
        WHEN current_address_months_count = -1 THEN 'missing'
        ELSE 'non-missing'
    END AS missingness
FROM baf_raw
GROUP BY missingness;


-- =========================================
-- 02. SUMMARY STATISTICS
-- =========================================

-- prev_address_months_count summary
SELECT
    MIN(prev_address_months_count) AS min_val,
    quantile_cont(prev_address_months_count, 0.25) AS p25,
    quantile_cont(prev_address_months_count, 0.50) AS median,
    quantile_cont(prev_address_months_count, 0.90) AS p90,
    MAX(prev_address_months_count) AS max_val
FROM baf_raw
WHERE prev_address_months_count != -1;

-- current_address_months_count summary
SELECT
    MIN(current_address_months_count) AS min_val,
    quantile_cont(current_address_months_count, 0.25) AS p25,
    quantile_cont(current_address_months_count, 0.50) AS median,
    quantile_cont(current_address_months_count, 0.90) AS p90,
    MAX(current_address_months_count) AS max_val
FROM baf_raw
WHERE current_address_months_count != -1;


-- =========================================
-- 03. FRAUD RELATIONSHIP
-- =========================================

-- - Missing previous address history is strongly associated with elevated fraud risk.
-- - Among applicants with recorded address history, fraud cases exhibit longer previous address tenure than non-fraud cases.
-- - This suggests the predictive value may come primarily from missingness rather than short address tenure.

-- prev_address_months_count split
SELECT
    fraud_bool,
    MIN(prev_address_months_count) AS min_val,
    quantile_cont(prev_address_months_count, 0.25) AS p25,
    quantile_cont(prev_address_months_count, 0.50) AS median,
    quantile_cont(prev_address_months_count, 0.90) AS p90,
    MAX(prev_address_months_count) AS max_val
FROM baf_raw
WHERE prev_address_months_count != -1
GROUP BY fraud_bool;

