-- Top conditions by prevalence and average cost
SET search_path TO synthea, public;

WITH condition_costs AS (
    SELECT
        c.description,
        c.code,
        COUNT(DISTINCT c.patient)           AS patient_count,
        COUNT(*)                            AS condition_episodes,
        ROUND(AVG(e.total_claim_cost), 2)   AS avg_encounter_cost
    FROM conditions c
    LEFT JOIN encounters e ON c.encounter = e.id
    GROUP BY c.description, c.code
)
SELECT
    description,
    code,
    patient_count,
    condition_episodes,
    avg_encounter_cost,
    ROUND(100.0 * patient_count / (SELECT COUNT(*) FROM patients), 2) AS prevalence_pct
FROM condition_costs
ORDER BY patient_count DESC
LIMIT 50;
