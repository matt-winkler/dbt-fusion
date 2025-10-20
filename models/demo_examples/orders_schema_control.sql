{{
    config(
        materialized='table'
    )
}}

select order_id,
       order_total,
       DATE(DATETIME(order_date)) as order_date
from {{ref('orders')}}