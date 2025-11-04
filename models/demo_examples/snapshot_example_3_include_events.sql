 
with min_as_of as (
    select business_key, event_time, min(as_of) as min_as_of
    from   {{ref('snapshot_example_3_data')}}
    group by business_key, event_time
),

next_events as (
    select *,
           lead(event_time, 1) over (partition by business_key order by event_time) as next_event_time
    from min_as_of
),

joined as (

    select base.*,
           next_events.next_event_time
    from   {{ref('snapshot_example_3_data')}} base
    join   next_events 
      on  base.business_key = next_events.business_key
      and base.event_time = next_events.event_time

),

mark_deletes as (
    select *,
           case when next_event_time < as_of then 1 else 0 end as to_delete
    from   joined
),

final as (
    select * from mark_deletes where to_delete = 0
)

select * from final