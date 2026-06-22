-- Patient demographics overview
SET search_path TO synthea, public;

-- Age distribution (living patients)
SELECT
    CASE
        WHEN age < 18  THEN '0-17'
        WHEN age < 35  THEN '18-34'
        WHEN age < 50  THEN '35-49'
        WHEN age < 65  THEN '50-64'
        WHEN age < 75  THEN '65-74'
        ELSE                '75+'
    END                         AS age_band,
    gender,
    race,
    ethnicity,
    COUNT(*)                    AS patient_count
FROM (
    SELECT
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, birthdate))::INT AS age,
        gender,
        race,
        ethnicity
    FROM patients
    WHERE deathdate IS NULL
) t
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2;
