



select
    1
from MATT_W_ANALYTICS_DEV.dbt_mwinkler.customers

where not(lifetime_spend_pretax + lifetime_tax_paid = lifetime_spend)

