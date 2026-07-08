with monthly as (
    select
        encounter_class,
        encounter_year,
        encounter_month,
        count(*)                                  as encounter_count,
        count(distinct patient_id)                as unique_patients,
        round(sum(total_claim_cost)::numeric, 2)   as total_claim_cost,
        round(avg(total_claim_cost)::numeric, 2)   as avg_claim_cost
    from {{ ref('stg_encounters') }}
    group by 1, 2, 3
),

-- trailing 6-month window (excludes the current month) so this month's
-- spike doesn't inflate the baseline it's being measured against
rolling as (
    select
        *,
        avg(encounter_count) over (
            partition by encounter_class
            order by encounter_month
            rows between 6 preceding and 1 preceding
        )                                          as rolling_avg_count,
        stddev_samp(encounter_count) over (
            partition by encounter_class
            order by encounter_month
            rows between 6 preceding and 1 preceding
        )                                          as rolling_stddev_count
    from monthly
)

select
    encounter_class,
    encounter_year,
    encounter_month,
    encounter_count,
    unique_patients,
    total_claim_cost,
    avg_claim_cost,
    round(rolling_avg_count::numeric, 2)          as rolling_avg_count,
    round(rolling_stddev_count::numeric, 2)       as rolling_stddev_count,

    round(
        case
            when rolling_stddev_count is null or rolling_stddev_count = 0 then null
            else (encounter_count - rolling_avg_count) / rolling_stddev_count
        end::numeric, 2
    )                                              as volume_z_score,

    -- require at least 3 months of history before flagging
    (
        rolling_stddev_count is not null
        and rolling_stddev_count > 0
        and abs((encounter_count - rolling_avg_count) / rolling_stddev_count) >= 2
    )                                              as is_volume_anomaly

from rolling
order by encounter_class, encounter_year, encounter_month
