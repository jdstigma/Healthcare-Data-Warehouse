with medications as (
    select * from {{ ref('stg_medications') }}
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
    m.rxnorm_code,
    m.description                               as medication_name,
    m.reason_description,
    py.payer_name,
    p.age_band,
    p.gender,
    p.state,
    m.is_active,

    count(distinct m.patient_id)                as unique_patients,
    count(*)                                    as prescription_count,
    round(avg(m.total_cost)::numeric, 2)        as avg_total_cost,
    round(sum(m.total_cost)::numeric, 2)        as total_cost,
    round(sum(m.payer_coverage)::numeric, 2)    as total_payer_coverage,
    round(sum(m.patient_cost)::numeric, 2)      as total_patient_cost,
    round(avg(m.payer_coverage_pct)::numeric, 1) as avg_payer_coverage_pct

from medications m
left join patients p on m.patient_id = p.patient_id
left join payers py  on m.payer_id   = py.payer_id
group by 1, 2, 3, 4, 5, 6, 7, 8
