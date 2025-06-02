
    
    

with all_values as (

    select
        customer_type as value_field,
        count(*) as n_records

    from MATT_W_ANALYTICS_DEV.dbt_mwinkler.customers
    group by customer_type

)

select *
from all_values
where value_field not in (
    'new','returning'
)


