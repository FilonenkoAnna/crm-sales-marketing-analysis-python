-- ============================================================
-- Business question: does faster first response (SLA) correlate
-- with higher lead-to-buyer conversion?
-- ============================================================
--
-- Method note:
-- This query independently recomputes SLA from raw call timestamps
-- (rather than reusing the pre-computed sla_minutes column in the
-- deals table) and splits deals into 4 equal-size groups using
-- NTILE(), a window function that ranks and buckets rows by
-- population count rather than fixed value thresholds.
--
-- Because of this, group boundaries differ slightly from the
-- fixed-threshold SLA quartiles used in the original pandas-based
-- analysis (see README.md / notebook 12) -- but the direction of
-- the pattern is confirmed independently through a completely
-- separate calculation path.
--
-- Result:
--
-- sla_group   | deals_count | avg_sla_minutes | conversion_pct
-- ------------|-------------|-----------------|---------------
-- 1 (fastest) |        4157 |              33 |          5.70%
-- 2           |        4157 |             199 |          5.05%
-- 3           |        4157 |             754 |          5.03%
-- 4 (slowest) |        4156 |           20434 |          3.68%
--
-- Conclusion: conversion decreases monotonically as response time
-- increases, confirming the association found in the original
-- pandas-based analysis (notebook 12), independent of methodology.
-- ============================================================

-- Step 1: for each deal, find the first call placed to that contact
-- on or after the deal's creation time (a contact may have several
-- deals over time, so we only look at calls that could plausibly
-- relate to *this* deal).
WITH first_call AS (
    SELECT
        d.id AS deal_id,
        MIN(c.call_start_time) AS first_call_time
    FROM deals d
    JOIN calls c
        ON d.contact_name = c.contactid
        AND c.call_start_time >= d.created_time
    GROUP BY d.id
),

-- Step 2: compute SLA in minutes as the gap between deal creation
-- and that first call.
sla_calc AS (
    SELECT
        d.id,
        d.is_buyer,
        EXTRACT(EPOCH FROM (fc.first_call_time - d.created_time)) / 60 AS sla_minutes
    FROM deals d
    JOIN first_call fc ON d.id = fc.deal_id
),

-- Step 3: split deals into 4 equal-size groups by SLA, fastest to slowest.
sla_quartiles AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY sla_minutes) AS sla_group
    FROM sla_calc
)

-- Step 4: summarize deal count, average SLA, and conversion per group.
SELECT
    sla_group,
    COUNT(*) AS deals_count,
    ROUND(AVG(sla_minutes)) AS avg_sla_minutes,
    ROUND(
        SUM(CASE WHEN is_buyer THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100,
    2) AS conversion_pct
FROM sla_quartiles
GROUP BY sla_group
ORDER BY sla_group;