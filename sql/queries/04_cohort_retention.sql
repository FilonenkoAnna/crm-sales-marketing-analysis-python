-- ============================================================
-- Business question: for leads grouped by the month of their first
-- CRM appearance (cohort), what share eventually become buyers,
-- and how many months does that typically take?
-- ============================================================
--
-- This is the one query in this folder that adds a genuinely new
-- analytical angle rather than re-deriving a result already covered
-- by the pandas notebooks -- none of the 12 notebooks in this project
-- perform cohort-based retention analysis.
--
-- Method note:
-- - A contact's cohort is the calendar month of their earliest deal
--   (first CRM appearance), not the month of any individual deal.
-- - cohort_size is the total number of unique contacts in that
--   cohort, regardless of whether they ever bought -- this is the
--   denominator for retention_pct.
-- - months_since_cohort is computed via AGE(), which returns a
--   human-readable "N years M months" interval; EXTRACT() converts
--   that into a single integer count of months.
-- - Later cohorts (e.g. spring 2024) naturally have fewer populated
--   months_since_cohort values, since the observation window ends
--   in mid-2024 -- there simply hasn't been time for a "6 months
--   later" purchase to occur yet for those cohorts. This is a
--   right-censoring effect, not a data quality issue.
--
-- Result (sample, first two cohorts):
--
-- cohort_month | months_since_cohort | cohort_size | buyers_count | retention_pct
-- -------------|----------------------|-------------|--------------|---------------
-- 2023-07      | 0                    | 592         | 2            | 0.3%
-- 2023-07      | 1                    | 592         | 5            | 0.8%
-- 2023-08      | 0                    | 824         | 23           | 2.8%
-- 2023-08      | 1                    | 824         | 15           | 1.8%
--
-- Conclusion: for both cohorts, purchases are heavily concentrated
-- in month 0 (the same calendar month as the first lead) and month 1,
-- with a long, thin tail extending several months out. This is
-- consistent with the short median deal-closing time (17 days)
-- reported in the pandas time-series analysis (notebook 07), now
-- confirmed independently from a cohort perspective.
-- ============================================================

WITH cohort AS (
    SELECT
        contact_name,
        DATE_TRUNC('month', MIN(created_time)) AS cohort_month
    FROM deals
    GROUP BY contact_name
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM cohort
    GROUP BY cohort_month
),
buyer_purchase AS (
    SELECT
        c.contact_name,
        c.cohort_month,
        DATE_TRUNC('month', b.closing_date) AS purchase_month,
        (
            EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', b.closing_date), c.cohort_month)) * 12
            + EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', b.closing_date), c.cohort_month))
        ) AS months_since_cohort
    FROM cohort c
    JOIN buyers b ON c.contact_name = b.contact_name
    WHERE b.closing_date IS NOT NULL
)
SELECT
    bp.cohort_month,
    bp.months_since_cohort,
    cs.cohort_size,
    COUNT(*) AS buyers_count,
    ROUND(COUNT(*)::NUMERIC / cs.cohort_size * 100, 1) AS retention_pct
FROM buyer_purchase bp
JOIN cohort_size cs ON bp.cohort_month = cs.cohort_month
GROUP BY bp.cohort_month, bp.months_since_cohort, cs.cohort_size
ORDER BY bp.cohort_month, bp.months_since_cohort;