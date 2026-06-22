with encounters as (
    select * from {{ ref('stg_encounters') }}
),

patients as (
    select patient_id, age_band, gender, race, state
    from {{ ref('mart_patient_demographics') }}
),

payers as (
    select id as payer_id, name as payer_name
    from synthea.payers
)

select
    e.encounter_year,
    e.encounter_month,
    e.encounter_class,
    e.description                       as encounter_type,
    py.payer_name,
    p.age_band,
    p.gender,
    p.race,
    p.state,

    count(*)                            as encounter_count,
    count(distinct e.patient_id)        as unique_patients,
    round(avg(e.total_claim_cost)::numeric, 2)   as avg_claim_cost,
    round(sum(e.total_claim_cost)::numeric, 2)   as total_claim_cost,
    round(sum(e.payer_coverage)::numeric, 2)     as total_payer_coverage,
    round(sum(e.patient_oop)::numeric, 2)        as total_patient_oop,
    round(avg(e.duration_hours)::numeric, 2)     as avg_duration_hours

from encounters e
left join patients p  on e.patient_id = p.patient_id
left join payers py   on e.payer_id   = py.payer_id
group by 1, 2, 3, 4, 5, 6, 7, 8, 9
