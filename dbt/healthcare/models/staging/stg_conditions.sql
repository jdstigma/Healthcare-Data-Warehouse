with source as (
    select * from synthea.conditions
)

select
    patient                                                 as patient_id,
    encounter                                               as encounter_id,
    code                                                    as snomed_code,
    description,
    start_time                                              as onset_date,
    stop_time                                               as resolved_date,

    -- derived
    stop_time is null                                       as is_active,
    stop_time::date - start_time::date                      as duration_days

from source
