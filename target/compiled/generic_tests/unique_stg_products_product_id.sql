
    
    

select
    product_id as unique_field,
    count(*) as n_records

from MATT_W_ANALYTICS_DEV.dbt_mwinkler.stg_products
where product_id is not null
group by product_id
having count(*) > 1


