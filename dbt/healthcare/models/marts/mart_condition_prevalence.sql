with conditions as (
    select * from {{ ref('stg_conditions') }}
),

patients as (
    select patient_id, age_band, gender, race, state
    from {{ ref('mart_patient_demographics') }}
),

total_patients as (
    select count(distinct patient_id) as n from {{ ref('stg_patients') }}
),

condition_encounters as (
    select
        encounter_id,
        total_claim_cost,
        patient_oop
    from {{ ref('stg_encounters') }}
)

select
    c.snomed_code,
    c.description                               as condition_name,
    p.age_band,
    p.gender,
    p.race,
    p.state,
    c.is_active,

    count(distinct c.patient_id)                as patient_count,
    count(*)                                    as episode_count,
    round(
        count(distinct c.patient_id) * 100.0
        / (select n from total_patients), 2
    )                                           as prevalence_pct,
    round(avg(c.duration_days)::numeric, 1)     as avg_duration_days,
    round(avg(e.total_claim_cost)::numeric, 2)  as avg_encounter_cost

from conditions c
left join patients p            on c.patient_id   = p.patient_id
left join condition_encounters e on c.encounter_id = e.encounter_id
group by 1, 2, 3, 4, 5, 6, 7
