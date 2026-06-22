with source as (
    select * from synthea.observations
)

select
    patient                                                 as patient_id,
    encounter                                               as encounter_id,
    date_time                                               as observed_at,
    category,
    code                                                    as loinc_code,
    description,
    value,
    units,
    type,

    -- cast numeric observations for downstream aggregation
    case when type = 'numeric' then value::numeric end      as value_numeric

from source
