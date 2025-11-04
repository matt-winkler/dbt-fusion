{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='sk_id',
        post_hook=[
            "delete from {{this}} where to_delete = 1;",
            "{{snapshot_example_3__update_end_time(this, 'eff_end_tmstmp', 'eff_begin_tmstmp', 'sk_id', 'business_key')}}"
        ]
    )
}}

with change_set as (
    select upstream_data.*,
          upstream_data.as_of as eff_begin_tmstmp,
          timestamp("9999-12-31 23:59:59") as eff_end_tmstmp,
          0 as to_delete
   from {{ref('snapshot_example_3_data')}} upstream_data
   join {{ref('snapshot_example_3_include_events')}} include_events
    on upstream_data.sk_id = include_events.sk_id
),

{% if not is_incremental() %}
   
   select * from change_set

{% else %}

with new_records as (
    select change_set.*
    from change_set
    -- can turn all of the below into it's own macro
    join (
        select business_key, max(event_time) as max_event_time 
        from {{this}}
        --from `sales-demo-project-314714`.`dbt_mwinkler`.`snapshot_example_3_target`
        group by business_key
     ) as target_table
      on change_set.business_key = target_table.business_key
      and change_set.event_time > target_table.max_event_time
),

mark_deletes as (

    select target_table.sk_id,
           target_table.business_key,
           target_table.event_time,
           target_table.as_of,
           target_table.rms_sku_num,
           target_table.store_num,
           target_table.price_type,
           target_table.price_amount,
           target_table.currency,
           target_table.eff_begin_tmstmp,
           target_table.eff_end_tmstmp,
           1 as to_delete
    --from {{this}} as target_table
    from {{this}} as target_table
    join  (
        select business_key, 
               event_time,
               min(as_of) as min_as_of
        from change_set
        group by business_key, event_time
    ) as new_records 
      on  target_table.business_key = new_records.business_key
      and target_table.event_time < new_records.event_time
      and target_table.as_of > new_records.min_as_of
)
--select * from mark_deletes

select * from new_records
union all 
select * from mark_deletes
{% endif %}