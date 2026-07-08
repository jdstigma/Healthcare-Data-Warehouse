with encounters as (
    select * from {{ ref('stg_encounters') }}
),

patients as (
    select patient_id, age_band, gender, state
    from {{ ref('mart_patient_demographics') }}
),

-- peer group = same encounter class + encounter type, so a $50k inpatient
-- stay isn't compared against a $80 outpatient visit
peer_stats as (
    select
        encounter_class,
        description,
        avg(total_claim_cost)          as peer_avg_cost,
        stddev_samp(total_claim_cost)  as peer_stddev_cost,
        count(*)                       as peer_encounter_count
    from encounters
    group by 1, 2
)

select
    e.encounter_id,
    e.patient_id,
    p.age_band,
    p.gender,
    p.state,
    e.provider_id,
    e.encounter_class,
    e.description                          as encounter_type,
    e.start_time,
    e.encounter_year,
    e.encounter_month,
    e.total_claim_cost,
    e.payer_coverage,
    e.patient_oop,
    e.duration_hours,

    round(s.peer_avg_cost::numeric, 2)     as peer_avg_cost,
    round(s.peer_stddev_cost::numeric, 2)  as peer_stddev_cost,
    s.peer_encounter_count,

    round(
        case
            when s.peer_stddev_cost is null or s.peer_stddev_cost = 0 then 0
            else (e.total_claim_cost - s.peer_avg_cost) / s.peer_stddev_cost
        end::numeric, 2
    )                                        as cost_z_score,

    -- require a peer group of at least 10 so small samples don't trip the flag
    (
        s.peer_stddev_cost is not null
        and s.peer_stddev_cost > 0
        and s.peer_encounter_count >= 10
        and abs((e.total_claim_cost - s.peer_avg_cost) / s.peer_stddev_cost) >= 3
    )                                        as is_cost_anomaly

from encounters e
left join patients p   on e.patient_id      = p.patient_id
left join peer_stats s on e.encounter_class = s.encounter_class
                       and e.description    = s.description
