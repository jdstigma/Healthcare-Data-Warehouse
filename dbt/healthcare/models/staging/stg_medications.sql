with source as (
    select * from synthea.medications
)

select
    patient                                                 as patient_id,
    encounter                                               as encounter_id,
    payer                                                   as payer_id,
    code                                                    as rxnorm_code,
    description,
    start_time,
    stop_time,
    reasoncode                                              as reason_code,
    reasondescription                                       as reason_description,
    base_cost,
    payer_coverage,
    totalcost                                               as total_cost,
    dispenses,

    -- derived
    stop_time is null                                       as is_active,
    totalcost - payer_coverage                              as patient_cost,
    case
        when totalcost = 0 then null
        else round((payer_coverage / totalcost * 100)::numeric, 1)
    end                                                     as payer_coverage_pct

from source
