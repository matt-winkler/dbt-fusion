
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select location_id
from MATT_W_ANALYTICS_DEV.dbt_mwinkler.stg_locations
where location_id is null



  
  
      
    ) dbt_internal_test