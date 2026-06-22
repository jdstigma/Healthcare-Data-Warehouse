-- Medication utilization: top drugs by patient count, cost, and payer coverage
SET search_path TO synthea, public;

SELECT
    m.description                               AS medication,
    m.code,
    COUNT(DISTINCT m.patient)                   AS unique_patients,
    COUNT(*)                                    AS prescription_count,
    ROUND(AVG(m.totalcost), 2)                  AS avg_total_cost,
    ROUND(SUM(m.totalcost), 2)                  AS total_cost,
    ROUND(SUM(m.payer_coverage), 2)             AS total_payer_coverage,
    ROUND(
        100.0 * SUM(m.payer_coverage) / NULLIF(SUM(m.totalcost), 0), 1
    )                                           AS payer_coverage_pct
FROM medications m
GROUP BY m.description, m.code
ORDER BY unique_patients DESC
LIMIT 50;
