
  
    

        create or replace  table MATT_W_ANALYTICS_DEV.dbt_mwinkler.supplies
         as
        (with

supplies as (

    select * from MATT_W_ANALYTICS_DEV.dbt_mwinkler.stg_supplies

)

select * from supplies
        );
      
  