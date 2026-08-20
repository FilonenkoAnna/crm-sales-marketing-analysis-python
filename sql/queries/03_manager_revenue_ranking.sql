-- ============================================================
-- Business question: which managers lead in revenue each month,
-- and is leadership concentrated among a consistent group or
-- does it rotate month to month?
-- ============================================================
--
-- Method note:
-- Revenue is approximated by SUM(initial_amount_paid) for confirmed
-- buyers, grouped by the month a deal actually closed (closing_date),
-- since revenue is realized at close, not at lead creation.
--
-- RANK() OVER (PARTITION BY month ...) resets the ranking separately
-- for every month -- each month gets its own #1, #2, #3, rather than
-- one ranking across the whole dataset. Ties receive the same rank,
-- with a gap left in the numbering for the next distinct value
-- (e.g. two managers tied at rank 2 are both followed by rank 4).
--
-- Result (first several months, sample):
--
-- month       | deal_owner_name  | revenue | rank_in_month
-- ------------|------------------|---------|---------------
-- 2023-08     | Ulysses Adams    | 7450    | 1
-- 2023-08     | Jane Smith       | 5350    | 2
-- 2023-09     | Charlie Davis    | 5750    | 1
-- 2023-09     | Ulysses Adams    | 5000    | 2
-- 2023-10     | Jane Smith       | 8000    | 1
-- 2023-11     | Jane Smith       | 9000    | 1
--
-- Conclusion: leadership is not dominated by a single manager every
-- month, but a small group (Ulysses Adams, Charlie Davis, Jane Smith)
-- repeatedly appears in the top 3 across multiple months -- consistent
-- with the "some managers perform strongly across metrics" pattern
-- noted in the pandas-based sales-team analysis (notebook 09).
-- ============================================================

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', closing_date) AS month,
        deal_owner_name,
        SUM(initial_amount_paid) AS revenue
    FROM buyers
    WHERE closing_date IS NOT NULL
    GROUP BY DATE_TRUNC('month', closing_date), deal_owner_name
)
SELECT
    month,
    deal_owner_name,
    revenue,
    RANK() OVER (PARTITION BY month ORDER BY revenue DESC) AS rank_in_month
FROM monthly_revenue
ORDER BY month, rank_in_month;