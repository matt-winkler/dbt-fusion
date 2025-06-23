with

supplies as (

    select * from {{ ref('stg_supplies', v='1') }}

)

select * from supplies
