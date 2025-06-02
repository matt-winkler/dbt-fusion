
  
    

        create or replace  table MATT_W_ANALYTICS_DEV.dbt_mwinkler.products
         as
        (with

products as (

    select * from MATT_W_ANALYTICS_DEV.dbt_mwinkler.stg_products

)

select * from products
        );
      
  