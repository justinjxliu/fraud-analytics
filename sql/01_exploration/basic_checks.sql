-- =========================================
-- 01. SANITY CHECKS
-- =========================================

SELECT COUNT(*) FROM baf_raw;

-- =========================================
-- 02. DATA SAMPLING
-- =========================================

SELECT * FROM baf_raw LIMIT 10;

-- =========================================
-- 03. COLUMN INSPECTION
-- =========================================

PRAGMA table_info('baf_raw');

-- =========================================
-- 04. MISSING VALUES
-- =========================================

SELECT
    COUNT(*) AS total,
    COUNT(income) AS non_null_income
FROM baf_raw;

-- =========================================
-- 05. DISTRIBUTIONS
-- =========================================

SELECT employment_status, COUNT(*)
FROM baf_raw
GROUP BY 1;

-- =========================================
-- 06. EARLY FRAUD SIGNAL EXPLORATION
-- =========================================


