with

source as (

    -- {# This references seed (CSV) data - try switching to {{ source('ecom', 'raw_orders') }} #}
    select * from {{ ref('raw_orders') }}

),

renamed as (

    select

        ----------  ids
        id as order_id,
        store_id as location_id,
        customer as customer_id,

        ---------- numerics
        subtotal as subtotal_cents,
        tax_paid as tax_paid_cents,
        order_total as order_total_cents,
        {{ cents_to_dollars('subtotal') }} as subtotal,
        {{ cents_to_dollars('tax_paid') }} as tax_paid,
        {{ cents_to_dollars('order_total') }} as order_total,

        ---------- timestamps
        ordered_at as order_date,
        1 as default_order_flag

    from source

)

select * from renamed
