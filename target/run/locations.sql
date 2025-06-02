
  
    

        create or replace  table MATT_W_ANALYTICS_DEV.dbt_mwinkler.locations
         as
        (with

locations as (

    select * from MATT_W_ANALYTICS_DEV.dbt_mwinkler.stg_store_locations

)

select * from locations
        );
      
  