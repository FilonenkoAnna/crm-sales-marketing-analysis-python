-- Business question: which acquisition sources generate the most leads,
-- and which convert most efficiently into confirmed buyers?
--
-- Result (verified against notebook 08_marketing_effectiveness.ipynb):
-- Organic has the highest conversion (9.8%) despite modest lead volume (1,414).
-- Facebook Ads generates the largest lead volume (4,423) but only 4.4% conversion.
-- CRM and Partnership show low conversion (1.6% / 1.1%) — likely different
-- acquisition flows, not directly comparable to paid advertising.

WITH leads_by_source AS (
    SELECT source, COUNT(DISTINCT contact_name) AS leads_count
    FROM deals
    GROUP BY source
),
buyers_by_source AS (
    SELECT source, COUNT(DISTINCT contact_name) AS buyers_count
    FROM buyers
    GROUP BY source
)
SELECT
    l.source,
    l.leads_count,
    COALESCE(b.buyers_count, 0) AS buyers_count,
    ROUND(COALESCE(b.buyers_count, 0)::NUMERIC / l.leads_count * 100, 1) AS conversion_pct
FROM leads_by_source l
LEFT JOIN buyers_by_source b ON l.source = b.source
ORDER BY l.leads_count DESC;
