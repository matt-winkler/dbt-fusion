
  create or replace   view MATT_W_ANALYTICS_DEV.dbt_mwinkler.stg_supplies
  
   as (
    with

source as (

    -- 
    select * from MATT_W_ANALYTICS_DEV.dbt_mwinkler_raw.raw_supplies

),

renamed as (

    select

        ----------  ids
        md5(cast(coalesce(cast(id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(sku as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as supply_uuid,
        id as supply_id,
        sku as product_id,

        ---------- text
        name as supply_name,

        ---------- numerics
        (cost / 100)::numeric(16, 2) as supply_cost,

        ---------- booleans
        perishable as is_perishable_supply

    from source

)

select * from renamed
  );

