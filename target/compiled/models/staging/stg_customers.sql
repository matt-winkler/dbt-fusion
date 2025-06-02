with

source as (

    -- 
    select * from MATT_W_ANALYTICS_DEV.dbt_mwinkler_raw.raw_customers

),

renamed as (

    select

        ----------  ids
        id as customer_id,

        ---------- text
        name as customer_name

    from source

)

select * from renamed