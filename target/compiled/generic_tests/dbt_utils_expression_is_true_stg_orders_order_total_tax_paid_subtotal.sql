



select
    1
from MATT_W_ANALYTICS_DEV.dbt_mwinkler.stg_orders

where not(order_total - tax_paid = subtotal)

