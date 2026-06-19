-- =========================================
-- 01. SUMMARY STATISTICS
-- =========================================

-- name_email_similarity summary
SELECT
    MIN(name_email_similarity) AS min_val,
    quantile_cont(name_email_similarity, 0.25) AS p25,
    quantile_cont(name_email_similarity, 0.50) AS median,
    quantile_cont(name_email_similarity, 0.90) AS p90,
    MAX(name_email_similarity) AS max_val
FROM baf_raw;

-- customer_age summary
SELECT
    MIN(customer_age) AS min_val,
    quantile_cont(customer_age, 0.25) AS p25,
    quantile_cont(customer_age, 0.50) AS median,
    quantile_cont(customer_age, 0.90) AS p90,
    MAX(customer_age) AS max_val
FROM baf_raw;


-- =========================================
-- 02. FRAUD RELATIONSHIP
-- =========================================

-- Key findings:
-- - name_email_similarity shows fraud separation.
-- - email_is_free shows fraud separation.
-- - phone_home_valid is stronger than phone_mobile_valid.

-- name_email_similarity split
SELECT
    fraud_bool,
    MIN(name_email_similarity) AS min_val,
    quantile_cont(name_email_similarity, 0.25) AS p25,
    quantile_cont(name_email_similarity, 0.50) AS median,
    quantile_cont(name_email_similarity, 0.90) AS p90,
    MAX(name_email_similarity) AS max_val
FROM baf_raw
GROUP BY fraud_bool;

-- name_email_similarity bucketed
SELECT
    CASE
        WHEN name_email_similarity < 0.2 THEN 1
        WHEN name_email_similarity < 0.4 THEN 2
        WHEN name_email_similarity < 0.6 THEN 3
        WHEN name_email_similarity < 0.8 THEN 4
        ELSE 5
    END AS name_email_similarity_bucket,
    COUNT(*) AS bucket_size,
    AVG(fraud_bool) AS fraud_rate
FROM baf_raw
GROUP BY name_email_similarity_bucket
ORDER BY name_email_similarity_bucket;

-- email_is_free bucketed
SELECT
    email_is_free,
    COUNT(*) AS bucket_size,
    AVG(fraud_bool) AS fraud_rate
FROM baf_raw
GROUP BY email_is_free;

-- phone_home_valid bucketed
SELECT
    phone_home_valid,
    COUNT(*) AS bucket_size,
    AVG(fraud_bool) AS fraud_rate
FROM baf_raw
GROUP BY phone_home_valid;

-- phone_mobile_valid bucketed
SELECT
    phone_mobile_valid,
    COUNT(*) AS bucket_size,
    AVG(fraud_bool) AS fraud_rate
FROM baf_raw
GROUP BY phone_mobile_valid;


-- =========================================
-- 03. INTERACTION EFFECTS
-- =========================================

-- Findings:
-- - Fraud risk is highest when low name/email similarity is combined with a free email provider.
-- - Fraud rate rises to ~1.72%, compared with a dataset baseline of ~1.10%.
-- - High similarity and paid email providers exhibit the lowest fraud rate (~0.59%).
-- - The interaction suggests identity consistency and email quality jointly contribute to fraud risk.

-- name_email_similarity x email_is_free
WITH bounds AS (
    SELECT quantile_cont(name_email_similarity, 0.5) AS median
    FROM baf_raw
)
SELECT
    CASE
        WHEN name_email_similarity < median AND email_is_free = 1 THEN 'low_sim_free_email'
        WHEN name_email_similarity >= median AND email_is_free = 1 THEN 'high_sim_free_email'
        WHEN name_email_similarity < median AND email_is_free = 0 THEN 'low_sim_paid_email'
        ELSE 'high_sim_paid_email'
    END AS quadrant,
    COUNT(*) AS total_rows,
    SUM(fraud_bool) AS fraud_rows,
    AVG(fraud_bool) AS fraud_rate
FROM baf_raw
CROSS JOIN bounds
GROUP BY quadrant
ORDER BY fraud_rate DESC;

-- name_email_similarity x phone_home_valid
WITH bounds AS (
    SELECT quantile_cont(name_email_similarity, 0.5) AS median
    FROM baf_raw
)
SELECT
    CASE
        WHEN name_email_similarity < median AND phone_home_valid = 0 THEN 'low_sim_invalid_home'
        WHEN name_email_similarity >= median AND phone_home_valid = 0 THEN 'high_sim_invalid_home'
        WHEN name_email_similarity < median AND phone_home_valid = 1 THEN 'low_sim_valid_home'
        ELSE 'high_sim_valid_home'
    END AS quadrant,
    COUNT(*) AS total_rows,
    SUM(fraud_bool) AS fraud_rows,
    AVG(fraud_bool) AS fraud_rate
FROM baf_raw
CROSS JOIN bounds
GROUP BY quadrant
ORDER BY fraud_rate DESC;

-- name_email_similarity x email_is_free x phone_home_valid
-- low similarity
WITH bounds AS (
    SELECT quantile_cont(name_email_similarity, 0.5) AS median
    FROM baf_raw
)
SELECT
    COUNT(*) AS total_rows,
    SUM(fraud_bool) AS fraud_rows,
    AVG(fraud_bool) AS fraud_rate,
    CASE
        WHEN email_is_free = 1 AND phone_home_valid = 0 THEN 'free_email_invalid_home'
        WHEN email_is_free = 0 AND phone_home_valid = 0 THEN 'paid_email_invalid_home'
        WHEN email_is_free = 1 AND phone_home_valid = 1 THEN 'free_email_valid_home'
        ELSE 'paid_email_valid_home'
    END AS quadrant
FROM baf_raw
CROSS JOIN bounds
WHERE name_email_similarity < median
GROUP BY quadrant
ORDER BY fraud_rate DESC;

-- high similarity
WITH bounds AS (
    SELECT quantile_cont(name_email_similarity, 0.5) AS median
    FROM baf_raw
)
SELECT
    COUNT(*) AS total_rows,
    SUM(fraud_bool) AS fraud_rows,
    AVG(fraud_bool) AS fraud_rate,
    CASE
        WHEN email_is_free = 1 AND phone_home_valid = 0 THEN 'free_email_invalid_home'
        WHEN email_is_free = 0 AND phone_home_valid = 0 THEN 'paid_email_invalid_home'
        WHEN email_is_free = 1 AND phone_home_valid = 1 THEN 'free_email_valid_home'
        ELSE 'paid_email_valid_home'
    END AS quadrant
FROM baf_raw
CROSS JOIN bounds
WHERE name_email_similarity >= median
GROUP BY quadrant
ORDER BY fraud_rate DESC;

