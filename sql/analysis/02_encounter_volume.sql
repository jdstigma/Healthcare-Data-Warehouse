-- Encounter volume by year, class, and payer
SET search_path TO synthea, public;

SELECT
    DATE_TRUNC('year', e.start_time)::DATE  AS encounter_year,
    e.encounterclass,
    p.name                                   AS payer_name,
    COUNT(*)                                 AS encounter_count,
    ROUND(AVG(e.total_claim_cost), 2)        AS avg_claim_cost,
    ROUND(SUM(e.total_claim_cost), 2)        AS total_claim_cost,
    ROUND(SUM(e.payer_coverage), 2)          AS total_payer_coverage,
    ROUND(SUM(e.total_claim_cost - e.payer_coverage), 2) AS total_patient_oop
FROM encounters e
LEFT JOIN payers p ON e.payer = p.id
GROUP BY 1, 2, 3
ORDER BY 1, 4 DESC;
