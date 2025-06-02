
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select supply_uuid
from MATT_W_ANALYTICS_DEV.dbt_mwinkler.stg_supplies
where supply_uuid is null



  
  
      
    ) dbt_internal_test