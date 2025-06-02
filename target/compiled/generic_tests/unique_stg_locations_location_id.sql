
    
    

select
    location_id as unique_field,
    count(*) as n_records

from MATT_W_ANALYTICS_DEV.dbt_mwinkler.stg_locations
where location_id is not null
group by location_id
having count(*) > 1


