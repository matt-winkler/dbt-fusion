with orders as (
    select * from {{ ref('orders') }}
),
locations as (
    select * from {{ ref('locations') }}
),
order_types as (
    select
        o.order_id,
        o.location_id,
        case
            when o.is_food_order and o.is_drink_order then 'food_and_drink'
            when o.is_food_order then 'food_only'
            when o.is_drink_order then 'drink_only'
            else 'neither'
        end as order_type
    from orders o
)

select
    l.location_name,
    ot.order_type,
    count(*) as order_count
from order_types ot
join locations l on ot.location_id = l.location_id
group by l.location_name, ot.order_type
order by l.location_name, ot.order_type 