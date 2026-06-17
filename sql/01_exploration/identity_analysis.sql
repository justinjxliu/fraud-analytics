-- Key findings:
-- - name_email_similarity shows fraud separation.
-- - email_is_free shows fraud separation.
-- - phone_home_valid is stronger than phone_mobile_valid.


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

