{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='sk_id'
    )
}}

{% if not is_incremental() %}
   select *,
          as_of as eff_begin_tmstmp,
          lead(as_of, 1) over (partition by business_key order by as_of) as eff_end_tmstmp,
          0 as to_delete
   from {{ref('snapshot_example_3_data')}}

{% else %}
with new_records as (
    select new_records.*,
           0 as to_delete
    from {{ref('snapshot_example_3_data')}} new_records
    -- can turn all of the below into it's own macro
    
    left join (
        select business_key, max(event_time) as max_event_time 
        from {{this}}
        group by business_key
     ) as target_table
      on new_records.business_key = target_table.business_key
    where new_records.event_time > target_table.max_event_time

),
mark_deletes as (
    select 1 as id
)

select * from new_records
union all
select * from mark_deletes
{% endif %}