with order_items as (
    select * from {{ ref('stg_order_items') }}
),
products as (
    select * from {{ ref('stg_products') }}
)

select
    oi.order_id,
    sum(case when p.is_food_item then 1 else 0 end) as total_food_items
from order_items oi
left join products p on oi.product_id = p.product_id
group by oi.order_id 