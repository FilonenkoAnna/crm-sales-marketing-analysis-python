# SQL Layer

This folder contains a set of PostgreSQL queries built on top of the same cleaned CRM dataset used throughout the notebooks in this project.

The goal is not to duplicate the pandas-based analysis, but to demonstrate the same underlying business questions (and one new one) solved with SQL — joins, common table expressions (CTEs), and window functions.

> **Data privacy:** as with the rest of the project, the original CRM data and the resulting local database are not included in this public repository. See "Reproducing locally" below.

---

## Queries

| File | Business Question | Technique |
|---|---|---|
| [`01_funnel_and_conversion.sql`](queries/01_funnel_and_conversion.sql) | Which acquisition sources generate the most leads, and which convert most efficiently into confirmed buyers? | CTE, `LEFT JOIN`, `COALESCE` |
| [`02_sla_response_time.sql`](queries/02_sla_response_time.sql) | Does faster first response (SLA) correlate with higher lead-to-buyer conversion? | CTE with a join-time condition, `EXTRACT(EPOCH ...)`, `NTILE()` |
| [`03_manager_revenue_ranking.sql`](queries/03_manager_revenue_ranking.sql) | Which managers lead in revenue each month — a consistent group, or does leadership rotate? | `RANK() OVER (PARTITION BY ...)` |
| [`04_cohort_retention.sql`](queries/04_cohort_retention.sql) | For leads grouped by the month of their first CRM appearance, what share eventually buy, and how long does it take? | CTE, `DATE_TRUNC`, `AGE()` |

Each file documents its own result and conclusion in a comment block at the top, so the analysis is readable without running the query.

`04_cohort_retention.sql` is the one query in this folder that adds a genuinely new analytical angle — none of the 12 notebooks in this project perform cohort-based retention analysis. The other three independently recompute findings already covered by the pandas notebooks, as a demonstration of the same reasoning expressed in SQL.

---

## Notable findings

- **Query 01** confirms the source-level conversion pattern from the notebooks exactly: Organic leads the group at 9.8% conversion despite modest volume (1,414 leads), while Facebook Ads generates the largest volume (4,423 leads) at a lower 4.4% conversion.
- **Query 02** independently recomputes SLA from raw call timestamps (rather than reusing the pre-computed `sla_minutes` column) and confirms the same monotonic pattern found in the pandas analysis: conversion decreases as response time increases, from 5.70% in the fastest-response quartile down to 3.68% in the slowest. Because `NTILE()` splits deals into four *equal-size* groups rather than using fixed value thresholds, and because averages (rather than medians) are used here, absolute figures differ somewhat from the notebook's SLA table — the direction of the relationship, however, is confirmed independently.
- **Query 03** shows that monthly revenue leadership is not dominated by a single manager, but a small group (Ulysses Adams, Charlie Davis, Jane Smith) repeatedly appears in the top 3 across multiple months — consistent with the "some managers perform strongly across metrics" pattern noted in the sales-team performance notebook.
- **Query 04** shows that purchases are heavily concentrated in the same calendar month as the first lead (month 0) and the following month, with a long, thin tail extending several months out — consistent with the short median deal-closing time (17 days) found in the time-series analysis.
