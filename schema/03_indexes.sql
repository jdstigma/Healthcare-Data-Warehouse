-- ============================================================
-- Performance indexes for common dashboard query patterns
-- ============================================================

SET search_path TO synthea, public;

-- Patients
CREATE INDEX IF NOT EXISTS idx_patients_state        ON patients(state);
CREATE INDEX IF NOT EXISTS idx_patients_gender       ON patients(gender);
CREATE INDEX IF NOT EXISTS idx_patients_race         ON patients(race);
CREATE INDEX IF NOT EXISTS idx_patients_birthdate    ON patients(birthdate);
CREATE INDEX IF NOT EXISTS idx_patients_deathdate    ON patients(deathdate) WHERE deathdate IS NOT NULL;

-- Encounters
CREATE INDEX IF NOT EXISTS idx_encounters_patient    ON encounters(patient);
CREATE INDEX IF NOT EXISTS idx_encounters_start      ON encounters(start_time);
CREATE INDEX IF NOT EXISTS idx_encounters_class      ON encounters(encounterclass);
CREATE INDEX IF NOT EXISTS idx_encounters_payer      ON encounters(payer);
CREATE INDEX IF NOT EXISTS idx_encounters_org        ON encounters(organization);

-- Conditions
CREATE INDEX IF NOT EXISTS idx_conditions_patient    ON conditions(patient);
CREATE INDEX IF NOT EXISTS idx_conditions_code       ON conditions(code);
CREATE INDEX IF NOT EXISTS idx_conditions_start      ON conditions(start_time);

-- Medications
CREATE INDEX IF NOT EXISTS idx_medications_patient   ON medications(patient);
CREATE INDEX IF NOT EXISTS idx_medications_code      ON medications(code);
CREATE INDEX IF NOT EXISTS idx_medications_start     ON medications(start_time);

-- Procedures
CREATE INDEX IF NOT EXISTS idx_procedures_patient    ON procedures(patient);
CREATE INDEX IF NOT EXISTS idx_procedures_code       ON procedures(code);

-- Observations
CREATE INDEX IF NOT EXISTS idx_observations_patient  ON observations(patient);
CREATE INDEX IF NOT EXISTS idx_observations_code     ON observations(code);
CREATE INDEX IF NOT EXISTS idx_observations_date     ON observations(date_time);
CREATE INDEX IF NOT EXISTS idx_observations_category ON observations(category);

-- Claims / Financial
CREATE INDEX IF NOT EXISTS idx_claims_patient        ON claims(patient_id);
CREATE INDEX IF NOT EXISTS idx_claims_service_date   ON claims(service_date);
CREATE INDEX IF NOT EXISTS idx_claims_tx_claim       ON claims_transactions(claim_id);
CREATE INDEX IF NOT EXISTS idx_claims_tx_patient     ON claims_transactions(patient_id);
CREATE INDEX IF NOT EXISTS idx_claims_tx_type        ON claims_transactions(type);

-- Payer transitions
CREATE INDEX IF NOT EXISTS idx_payer_trans_patient   ON payer_transitions(patient);
CREATE INDEX IF NOT EXISTS idx_payer_trans_year      ON payer_transitions(start_year, end_year);
