
  create or replace   view MATT_W_ANALYTICS_DEV.dbt_mwinkler.stg_order_items
  
   as (
    with

source as (

    -- 
    select * from MATT_W_ANALYTICS_DEV.dbt_mwinkler_raw.raw_items

),

renamed as (

    select

        ----------  ids
        id as order_item_id,
        order_id,
        sku as product_id

    from source

)

select * from renamed
  );

