
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    supply_uuid as unique_field,
    count(*) as n_records

from MATT_W_ANALYTICS_DEV.dbt_mwinkler.stg_supplies
where supply_uuid is not null
group by supply_uuid
having count(*) > 1



  
  
      
    ) dbt_internal_test