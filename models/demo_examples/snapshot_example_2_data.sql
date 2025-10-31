with source_data as (
{% if var('time_period', '1') == '1' %}
select timestamp('2025-10-28 0:00:00') as lastUpdatedTime,	5717966 as skuId, 	120	as channel, '2025-10-28 0:00:00' as deployStartTime, null as endTime,		'DIRECT_TO_STORE' as deploymentType,	'DEPARTMENT' as deployLevel union all
select timestamp('2025-10-28 0:00:00') as lastUpdatedTime,	6213446 as skuId, 	120	as channel, '2025-12-15 0:00:00' as deployStartTime,	null as endTime,	'CROSS_DOCK'  as deploymentType,	'SKU' as deployLevel union all
select timestamp('2025-10-28 0:00:00') as lastUpdatedTime,	4445612 as skuId, 	120	as channel, '2026-02-11 0:00:00' as deployStartTime,	null as endTime,	'RESERVE_STOCK' as deploymentType,	'SKU' as deployLevel

{% elif var('time_period', '1') == '2' %}
select timestamp('2025-10-29 0:00:00') as lastUpdatedTime,	5717966 as skuId, 	120	as channel, '2025-10-29 0:00:00' as deployStartTime, null as endTime,		'DIRECT_TO_STORE' as deploymentType,	'SKU' as deployLevel

{% else %}
select timestamp('2025-10-30 3:00:00') as lastUpdatedTime,	5717966 as skuId, 	120	as channel, '2025-10-29 0:00:00' as deployStartTime,  '2025-10-30 0:00:00' as endTime,		'DIRECT_TO_STORE' as deploymentType,	'SKU' as deployLevel union all
select timestamp('2025-10-30 3:00:00') as lastUpdatedTime,	6213446 as skuId, 	120	as channel, '2025-12-15 0:00:00' as deployStartTime,	 '2025-10-30 0:00:00' as endTime,	'CROSS_DOCK'  as deploymentType,	'SKU' as deployLevel union all
select timestamp('2025-10-30 3:00:00') as lastUpdatedTime,	4445612 as skuId, 	120	as channel, '2026-01-07 0:00:00' as deployStartTime,	null as endTime,	'RESERVE_STOCK' as deploymentType,	'DEPARTMENT' as deployLevel
{% endif %}
),

processed as (
    select {{
        dbt_utils.generate_surrogate_key([
            'skuId',
            'channel'
            ])
        }} as sk_id,
        skuId as sku_id,
        channel,
        deploymentType as deployment_type,
        deployLevel as deployment_level,
        parse_timestamp('%Y-%m-%d %H:%M:%S', deployStartTime) as deploy_start_time,
        parse_timestamp('%Y-%m-%d %H:%M:%S', coalesce(cast(endTime as string), 
                   '9999-12-31 23:59:59')) as eff_end_tmstmp
        
    from source_data
),

mark_deletes as (
  select sk_id,
         sku_id,
         channel,
         deployment_type,
         deployment_level,
         case when (eff_end_tmstmp != timestamp('9999-12-31 23:59:59') and 
                   eff_end_tmstmp > deploy_start_time)
               then eff_end_tmstmp
               else deploy_start_time 
               end as updated_at,
         eff_end_tmstmp,
         case when eff_end_tmstmp > deploy_start_time then 1 else 0 end as to_delete
  from processed
),

final as (
    select sk_id, 
           sku_id, 
           channel,
           deployment_type,
           deployment_level,
           updated_at,
           --eff_end_tmstmp,
           to_delete
    from mark_deletes
)

select * from final