with source as (
    select * from synthea.patients
)

select
    id                                                      as patient_id,
    birthdate,
    deathdate,
    gender,
    race,
    ethnicity,
    marital,
    city,
    state,
    zip,
    lat,
    lon,
    income,
    healthcare_expenses,
    healthcare_coverage,

    -- derived
    date_part('year', age(coalesce(deathdate, current_date), birthdate))::int
                                                            as age_years,
    deathdate is not null                                   as is_deceased,
    date_part('year', age(current_date, birthdate))::int
        < 18                                                as is_minor

from source
