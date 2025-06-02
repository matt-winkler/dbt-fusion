
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from MATT_W_ANALYTICS_DEV.dbt_mwinkler.stg_orders

where not(order_total - tax_paid = subtotal)


  
  
      
    ) dbt_internal_test