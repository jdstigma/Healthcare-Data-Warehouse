with source as (
    select * from synthea.procedures
)

select
    patient                                                 as patient_id,
    encounter                                               as encounter_id,
    code                                                    as snomed_code,
    description,
    start_time,
    stop_time,
    reasoncode                                              as reason_code,
    reasondescription                                       as reason_description,
    base_cost

from source
