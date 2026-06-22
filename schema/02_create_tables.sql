-- ============================================================
-- Synthea Healthcare Data Warehouse - Table Definitions
-- Source: https://github.com/synthetichealth/synthea
-- ============================================================

SET search_path TO synthea, public;

-- ------------------------------------------------------------
-- Reference / Dimension tables
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS organizations (
    id                  UUID PRIMARY KEY,
    name                TEXT NOT NULL,
    address             TEXT,
    city                TEXT,
    state               TEXT,
    zip                 TEXT,
    lat                 NUMERIC(10,6),
    lon                 NUMERIC(10,6),
    phone               TEXT,
    revenue             NUMERIC(15,2),
    utilization         INT
);

CREATE TABLE IF NOT EXISTS providers (
    id                  UUID PRIMARY KEY,
    organization        UUID REFERENCES organizations(id),
    name                TEXT NOT NULL,
    gender              CHAR(1),
    speciality          TEXT,
    address             TEXT,
    city                TEXT,
    state               TEXT,
    zip                 TEXT,
    lat                 NUMERIC(10,6),
    lon                 NUMERIC(10,6),
    utilization         INT
);

CREATE TABLE IF NOT EXISTS payers (
    id                  UUID PRIMARY KEY,
    name                TEXT NOT NULL,
    address             TEXT,
    city                TEXT,
    state_headquartered TEXT,
    zip                 TEXT,
    phone               TEXT,
    amount_covered      NUMERIC(15,2),
    amount_uncovered    NUMERIC(15,2),
    revenue             NUMERIC(15,2),
    covered_encounters  INT,
    uncovered_encounters INT,
    covered_medications INT,
    uncovered_medications INT,
    covered_procedures  INT,
    uncovered_procedures INT,
    covered_immunizations INT,
    uncovered_immunizations INT,
    unique_customers    INT,
    qols_avg            NUMERIC(5,4),
    member_months       INT
);

-- ------------------------------------------------------------
-- Core patient table
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS patients (
    id                  UUID PRIMARY KEY,
    birthdate           DATE NOT NULL,
    deathdate           DATE,
    ssn                 TEXT,
    drivers             TEXT,
    passport            TEXT,
    prefix              TEXT,
    first               TEXT,
    last                TEXT,
    suffix              TEXT,
    maiden              TEXT,
    marital             CHAR(1),
    race                TEXT,
    ethnicity           TEXT,
    gender              CHAR(1),
    birthplace          TEXT,
    address             TEXT,
    city                TEXT,
    state               TEXT,
    county              TEXT,
    fips                TEXT,
    zip                 TEXT,
    lat                 NUMERIC(10,6),
    lon                 NUMERIC(10,6),
    healthcare_expenses NUMERIC(15,2),
    healthcare_coverage NUMERIC(15,2),
    income              INT
);

-- ------------------------------------------------------------
-- Encounter / Visit table
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS encounters (
    id                  UUID PRIMARY KEY,
    start_time          TIMESTAMPTZ NOT NULL,
    stop_time           TIMESTAMPTZ,
    patient             UUID NOT NULL REFERENCES patients(id),
    organization        UUID REFERENCES organizations(id),
    provider            UUID REFERENCES providers(id),
    payer               UUID REFERENCES payers(id),
    encounterclass      TEXT,
    code                TEXT,
    description         TEXT,
    base_encounter_cost NUMERIC(10,2),
    total_claim_cost    NUMERIC(10,2),
    payer_coverage      NUMERIC(10,2),
    reasoncode          TEXT,
    reasondescription   TEXT
);

-- ------------------------------------------------------------
-- Clinical event tables
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS conditions (
    start_time          DATE NOT NULL,
    stop_time           DATE,
    patient             UUID NOT NULL REFERENCES patients(id),
    encounter           UUID REFERENCES encounters(id),
    code                TEXT,
    description         TEXT
);

CREATE TABLE IF NOT EXISTS medications (
    start_time          TIMESTAMPTZ NOT NULL,
    stop_time           TIMESTAMPTZ,
    patient             UUID NOT NULL REFERENCES patients(id),
    payer               UUID REFERENCES payers(id),
    encounter           UUID REFERENCES encounters(id),
    code                TEXT,
    description         TEXT,
    base_cost           NUMERIC(10,2),
    payer_coverage      NUMERIC(10,2),
    dispenses           INT,
    totalcost           NUMERIC(10,2),
    reasoncode          TEXT,
    reasondescription   TEXT
);

CREATE TABLE IF NOT EXISTS procedures (
    start_time          TIMESTAMPTZ NOT NULL,
    stop_time           TIMESTAMPTZ,
    patient             UUID NOT NULL REFERENCES patients(id),
    encounter           UUID REFERENCES encounters(id),
    code                TEXT,
    description         TEXT,
    base_cost           NUMERIC(10,2),
    reasoncode          TEXT,
    reasondescription   TEXT
);

CREATE TABLE IF NOT EXISTS observations (
    date_time           TIMESTAMPTZ NOT NULL,
    patient             UUID NOT NULL REFERENCES patients(id),
    encounter           UUID REFERENCES encounters(id),
    category            TEXT,
    code                TEXT,
    description         TEXT,
    value               TEXT,
    units               TEXT,
    type                TEXT
);

CREATE TABLE IF NOT EXISTS immunizations (
    date_time           TIMESTAMPTZ NOT NULL,
    patient             UUID NOT NULL REFERENCES patients(id),
    encounter           UUID REFERENCES encounters(id),
    code                INT,
    description         TEXT,
    base_cost           NUMERIC(10,2)
);

CREATE TABLE IF NOT EXISTS allergies (
    start_time          DATE NOT NULL,
    stop_time           DATE,
    patient             UUID NOT NULL REFERENCES patients(id),
    encounter           UUID REFERENCES encounters(id),
    code                TEXT,
    system              TEXT,
    description         TEXT,
    type                TEXT,
    category            TEXT,
    reaction1           TEXT,
    description1        TEXT,
    severity1           TEXT,
    reaction2           TEXT,
    description2        TEXT,
    severity2           TEXT
);

CREATE TABLE IF NOT EXISTS careplans (
    id                  UUID,
    start_time          DATE NOT NULL,
    stop_time           DATE,
    patient             UUID NOT NULL REFERENCES patients(id),
    encounter           UUID REFERENCES encounters(id),
    code                TEXT,
    description         TEXT,
    reasoncode          TEXT,
    reasondescription   TEXT
);

CREATE TABLE IF NOT EXISTS devices (
    start_time          TIMESTAMPTZ NOT NULL,
    stop_time           TIMESTAMPTZ,
    patient             UUID NOT NULL REFERENCES patients(id),
    encounter           UUID REFERENCES encounters(id),
    code                TEXT,
    description         TEXT,
    udi                 TEXT
);

CREATE TABLE IF NOT EXISTS imaging_studies (
    id                  UUID PRIMARY KEY,
    date_time           TIMESTAMPTZ NOT NULL,
    patient             UUID NOT NULL REFERENCES patients(id),
    encounter           UUID REFERENCES encounters(id),
    series_uid          TEXT,
    bodysite_code       TEXT,
    bodysite_description TEXT,
    modality_code       TEXT,
    modality_description TEXT,
    instance_uid        TEXT,
    sop_code            TEXT,
    sop_description     TEXT,
    procedure_code      TEXT
);

-- ------------------------------------------------------------
-- Financial tables
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS payer_transitions (
    patient             UUID NOT NULL REFERENCES patients(id),
    memberid            TEXT,
    start_year          INT,
    end_year            INT,
    payer               UUID REFERENCES payers(id),
    secondary_payer     UUID REFERENCES payers(id),
    plan_ownership      TEXT,
    owner_name          TEXT
);

CREATE TABLE IF NOT EXISTS claims (
    id                  UUID PRIMARY KEY,
    patient_id          UUID NOT NULL REFERENCES patients(id),
    provider_id         UUID REFERENCES providers(id),
    primary_patient_insurance_id UUID,
    secondary_patient_insurance_id UUID,
    department_id       INT,
    patient_department_id INT,
    diagnosis1          TEXT,
    diagnosis2          TEXT,
    diagnosis3          TEXT,
    diagnosis4          TEXT,
    diagnosis5          TEXT,
    diagnosis6          TEXT,
    diagnosis7          TEXT,
    diagnosis8          TEXT,
    referring_provider_id UUID,
    appointment_id      UUID,
    current_illness_date DATE,
    service_date        DATE,
    supervising_provider_id UUID,
    status1             TEXT,
    status2             TEXT,
    statusp             TEXT,
    outstanding1        NUMERIC(10,2),
    outstanding2        NUMERIC(10,2),
    outstandingp        NUMERIC(10,2),
    lastbilleddate1     DATE,
    lastbilleddate2     DATE,
    lastbilleddatep     DATE,
    healthcare_claim_type_id1 INT,
    healthcare_claim_type_id2 INT
);

CREATE TABLE IF NOT EXISTS claims_transactions (
    id                  UUID PRIMARY KEY,
    claim_id            UUID REFERENCES claims(id),
    charge_id           INT,
    patient_id          UUID REFERENCES patients(id),
    type                TEXT,
    amount              NUMERIC(10,2),
    method              TEXT,
    from_date           DATE,
    to_date             DATE,
    place_of_service    TEXT,
    procedure_code      TEXT,
    modifier1           TEXT,
    modifier2           TEXT,
    diagnosis_ref1      INT,
    diagnosis_ref2      INT,
    diagnosis_ref3      INT,
    diagnosis_ref4      INT,
    units               INT,
    department_id       INT,
    notes               TEXT,
    unit_amount         NUMERIC(10,2),
    transfer_out_id     INT,
    transfer_type       TEXT,
    payments            NUMERIC(10,2),
    adjustments         NUMERIC(10,2),
    transfers           NUMERIC(10,2),
    outstanding         NUMERIC(10,2),
    appointment_id      UUID,
    line_note           TEXT,
    patient_insurance_id UUID,
    fee_schedule_id     INT,
    provider_id         UUID REFERENCES providers(id),
    supervising_provider_id UUID
);

CREATE TABLE IF NOT EXISTS supplies (
    date_time           DATE NOT NULL,
    patient             UUID NOT NULL REFERENCES patients(id),
    encounter           UUID REFERENCES encounters(id),
    code                TEXT,
    description         TEXT,
    quantity            INT
);
