
  create or replace   view MATT_W_ANALYTICS_DEV.dbt_mwinkler.stg_locations
  
   as (
    with

source as (

    -- 
    select * from MATT_W_ANALYTICS_DEV.dbt_mwinkler_raw.raw_stores

),

renamed as (

    select

        ----------  ids
        id as location_id,

        ---------- text
        name as location_name,

        ---------- numerics
        tax_rate,

        ---------- timestamps
        cast(opened_at as date) as opened_date

    from source

)

select * from renamed
  );

