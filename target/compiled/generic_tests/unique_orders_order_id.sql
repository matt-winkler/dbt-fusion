
    
    

select
    order_id as unique_field,
    count(*) as n_records

from MATT_W_ANALYTICS_DEV.dbt_mwinkler.orders
where order_id is not null
group by order_id
having count(*) > 1


