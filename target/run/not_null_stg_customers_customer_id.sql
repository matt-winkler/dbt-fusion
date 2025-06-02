
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select customer_id
from MATT_W_ANALYTICS_DEV.dbt_mwinkler.stg_customers
where customer_id is null



  
  
      
    ) dbt_internal_test