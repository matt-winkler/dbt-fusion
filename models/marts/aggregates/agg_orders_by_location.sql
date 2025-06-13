with orders as (
    select * from {{ ref('orders') }}
)

select
    location_id,
    order_date,
    count(order_id) as total_orders
from orders
group by location_id, order_date 