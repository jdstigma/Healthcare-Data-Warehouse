with patients as (
    select * from {{ ref('stg_patients') }}
),

encounter_counts as (
    select
        patient_id,
        count(*)                        as total_encounters,
        sum(total_claim_cost)           as lifetime_claim_cost,
        sum(patient_oop)                as lifetime_oop,
        min(start_time)::date           as first_encounter_date,
        max(start_time)::date           as last_encounter_date
    from {{ ref('stg_encounters') }}
    group by patient_id
),

condition_counts as (
    select
        patient_id,
        count(distinct snomed_code)     as unique_conditions,
        count(*) filter (where is_active) as active_conditions
    from {{ ref('stg_conditions') }}
    group by patient_id
)

select
    p.patient_id,
    p.gender,
    p.race,
    p.ethnicity,
    p.marital,
    p.state,
    p.city,
    p.zip,
    p.lat,
    p.lon,
    p.birthdate,
    p.deathdate,
    p.age_years,
    p.is_deceased,
    p.income,
    p.healthcare_expenses,
    p.healthcare_coverage,

    case
        when p.age_years < 18  then '0–17'
        when p.age_years < 35  then '18–34'
        when p.age_years < 50  then '35–49'
        when p.age_years < 65  then '50–64'
        when p.age_years < 75  then '65–74'
        else                        '75+'
    end                                 as age_band,

    coalesce(e.total_encounters, 0)     as total_encounters,
    coalesce(e.lifetime_claim_cost, 0)  as lifetime_claim_cost,
    coalesce(e.lifetime_oop, 0)         as lifetime_oop,
    e.first_encounter_date,
    e.last_encounter_date,

    coalesce(c.unique_conditions, 0)    as unique_conditions,
    coalesce(c.active_conditions, 0)    as active_conditions

from patients p
left join encounter_counts e on p.patient_id = e.patient_id
left join condition_counts c on p.patient_id = c.patient_id
