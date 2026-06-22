with source as (
    select * from synthea.encounters
)

select
    id                                                      as encounter_id,
    patient                                                 as patient_id,
    organization                                            as organization_id,
    provider                                                as provider_id,
    payer                                                   as payer_id,
    start_time,
    stop_time,
    encounterclass                                          as encounter_class,
    code,
    description,
    reasoncode                                              as reason_code,
    reasondescription                                       as reason_description,
    base_encounter_cost,
    total_claim_cost,
    payer_coverage,

    -- derived
    total_claim_cost - payer_coverage                       as patient_oop,
    extract(epoch from (stop_time - start_time)) / 3600.0  as duration_hours,
    date_trunc('month', start_time)::date                   as encounter_month,
    date_part('year', start_time)::int                      as encounter_year

from source
