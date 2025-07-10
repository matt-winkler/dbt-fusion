{{config(materialized='table')}}

with

locations as (

    select * from {{ ref('stg_locations') }}

)

select * from locations