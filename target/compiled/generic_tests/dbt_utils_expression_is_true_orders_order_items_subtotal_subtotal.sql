



select
    1
from MATT_W_ANALYTICS_DEV.dbt_mwinkler.orders

where not(order_items_subtotal = subtotal)

