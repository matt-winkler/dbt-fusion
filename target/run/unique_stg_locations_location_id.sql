
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    location_id as unique_field,
    count(*) as n_records

from MATT_W_ANALYTICS_DEV.dbt_mwinkler.stg_locations
where location_id is not null
group by location_id
having count(*) > 1



  
  
      
    ) dbt_internal_test