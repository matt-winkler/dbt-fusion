with source_data as (
{% if var('time_period', '1') == '1' %}
select timestamp('2025-10-28 0:00:00') as lastUpdatedTime,	5717966 as skuId, 	120	as channel, timestamp('2025-10-28 0:00:00') as deployStartTime, null as endTime,		'DIRECT_TO_STORE' as deploymentType,	'DEPARTMENT' as deployLevel union all
select timestamp('2025-10-28 0:00:00') as lastUpdatedTime,	6213446 as skuId, 	120	as channel, timestamp('2025-12-15 0:00:00') as deployStartTime,	null as endTime,	'CROSS_DOCK'  as deploymentType,	'SKU' as deployLevel union all
select timestamp('2025-10-28 0:00:00') as lastUpdatedTime,	4445612 as skuId, 	120	as channel, timestamp('2026-02-11 0:00:00') as deployStartTime,	null as endTime,	'RESERVE_STOCK' as deploymentType,	'SKU' as deployLevel

{% elif var('time_period', '1') == '2' %}
select timestamp('2025-10-29 0:00:00') as lastUpdatedTime,	5717966 as skuId, 	120	as channel, timestamp('2025-10-29 0:00:00') as deployStartTime, null as endTime,		'DIRECT_TO_STORE' as deploymentType,	'DEPARTMENT' as deployLevel

{% else %}
select timestamp('2025-10-30 3:00:00') as lastUpdatedTime,	5717966 as skuId, 	120	as channel, timestamp('2025-10-29 0:00:00') as deployStartTime, timestamp('2025-10-30 0:00:00') as endTime,		'DIRECT_TO_STORE' as deploymentType,	'SKU' as deployLevel union all
select timestamp('2025-10-30 3:00:00') as lastUpdatedTime,	6213446 as skuId, 	120	as channel, timestamp('2025-12-15 0:00:00') as deployStartTime,	timestamp('2025-10-30 0:00:00') as endTime,	'CROSS_DOCK'  as deploymentType,	'SKU' as deployLevel union all
select timestamp('2025-10-30 3:00:00') as lastUpdatedTime,	4445612 as skuId, 	120	as channel, timestamp('2026-01-07 0:00:00') as deployStartTime,	null as endTime,	'RESERVE_STOCK' as deploymentType,	'DEPARTMENT' as deployLevel
{% endif %}
)

select {{
        dbt_utils.generate_surrogate_key([
            'skuId',
            'channel'
            ])
        }} as sk_id,
        skuId,
        channel,
        deployStartTime,
        deployLevel as deployment_level,
        deploymentType as deployment_type
from source_data
