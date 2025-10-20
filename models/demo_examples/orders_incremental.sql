{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='insert_overwrite',
        partition_by={
            "field": "order_date",
            "data_type": "date"
        },
        on_schema_change='fail'
    )
}}

select order_id, 
       order_total,
       DATE(DATETIME(order_date)) as order_date
from {{ref('orders')}}