
select {{dbt_utils.star(
    from=ref('stg_supplies', v='2'), 
    except=['is_perishable_supply'])
    }}
from {{ref('stg_supplies', v='2')}}