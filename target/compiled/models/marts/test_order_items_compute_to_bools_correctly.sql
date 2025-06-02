WITH
              	MATT_W_ANALYTICS_DEV_dbt_mwinkler_order_items as (SELECT   CAST(ORDER_ITEM_ID AS VARCHAR) AS ORDER_ITEM_ID,
  CAST(ORDER_ID AS VARCHAR) AS ORDER_ID,
  CAST(PRODUCT_ID AS VARCHAR) AS PRODUCT_ID,
  CAST(ORDER_DATE AS DATE) AS ORDER_DATE,
  CAST(PRODUCT_NAME AS VARCHAR) AS PRODUCT_NAME,
  CAST(PRODUCT_PRICE AS NUMBER(16,2)) AS PRODUCT_PRICE,
  CAST(IS_FOOD_ITEM AS BOOLEAN) AS IS_FOOD_ITEM,
  CAST(IS_DRINK_ITEM AS BOOLEAN) AS IS_DRINK_ITEM,
  CAST(SUPPLY_COST AS NUMBER(28,2)) AS SUPPLY_COST  FROM VALUES (1, 1, NULL, NULL, NULL, NULL, true, false, NULL), (2, 1, NULL, NULL, NULL, NULL, false, true, NULL), (3, 2, NULL, NULL, NULL, NULL, true, false, NULL) AS t(ORDER_ITEM_ID, ORDER_ID, PRODUCT_ID, ORDER_DATE, PRODUCT_NAME, PRODUCT_PRICE, IS_FOOD_ITEM, IS_DRINK_ITEM, SUPPLY_COST)),
  	MATT_W_ANALYTICS_DEV_dbt_mwinkler_stg_orders as (SELECT   CAST(ORDER_ID AS VARCHAR) AS ORDER_ID,
  CAST(LOCATION_ID AS VARCHAR) AS LOCATION_ID,
  CAST(CUSTOMER_ID AS VARCHAR) AS CUSTOMER_ID,
  CAST(SUBTOTAL_CENTS AS bigint) AS SUBTOTAL_CENTS,
  CAST(TAX_PAID_CENTS AS bigint) AS TAX_PAID_CENTS,
  CAST(ORDER_TOTAL_CENTS AS bigint) AS ORDER_TOTAL_CENTS,
  CAST(SUBTOTAL AS NUMBER(16,2)) AS SUBTOTAL,
  CAST(TAX_PAID AS NUMBER(16,2)) AS TAX_PAID,
  CAST(ORDER_TOTAL AS NUMBER(16,2)) AS ORDER_TOTAL,
  CAST(ORDER_DATE AS DATE) AS ORDER_DATE  FROM VALUES (1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL), (2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL) AS t(ORDER_ID, LOCATION_ID, CUSTOMER_ID, SUBTOTAL_CENTS, TAX_PAID_CENTS, ORDER_TOTAL_CENTS, SUBTOTAL, TAX_PAID, ORDER_TOTAL, ORDER_DATE)),
  	MATT_W_ANALYTICS_DEV_dbt_mwinkler_orders_expect as (SELECT   CAST(ORDER_ID AS VARCHAR) AS ORDER_ID,
  CAST(LOCATION_ID AS VARCHAR) AS LOCATION_ID,
  CAST(CUSTOMER_ID AS VARCHAR) AS CUSTOMER_ID,
  CAST(SUBTOTAL_CENTS AS bigint) AS SUBTOTAL_CENTS,
  CAST(TAX_PAID_CENTS AS bigint) AS TAX_PAID_CENTS,
  CAST(ORDER_TOTAL_CENTS AS bigint) AS ORDER_TOTAL_CENTS,
  CAST(SUBTOTAL AS NUMBER(16,2)) AS SUBTOTAL,
  CAST(TAX_PAID AS NUMBER(16,2)) AS TAX_PAID,
  CAST(ORDER_TOTAL AS NUMBER(16,2)) AS ORDER_TOTAL,
  CAST(ORDER_DATE AS DATE) AS ORDER_DATE,
  CAST(ORDER_COST AS NUMBER(38,2)) AS ORDER_COST,
  CAST(ORDER_ITEMS_SUBTOTAL AS NUMBER(28,2)) AS ORDER_ITEMS_SUBTOTAL,
  CAST(COUNT_FOOD_ITEMS AS NUMBER(13,0)) AS COUNT_FOOD_ITEMS,
  CAST(COUNT_DRINKS AS NUMBER(13,0)) AS COUNT_DRINKS,
  CAST(COUNT_ORDER_ITEMS AS NUMBER(18,0)) AS COUNT_ORDER_ITEMS,
  CAST(IS_FOOD_ORDER AS BOOLEAN) AS IS_FOOD_ORDER,
  CAST(IS_DRINK_ORDER AS BOOLEAN) AS IS_DRINK_ORDER,
  CAST(CUSTOMER_ORDER_NUMBER AS NUMBER(18,0)) AS CUSTOMER_ORDER_NUMBER  FROM VALUES (1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, true, true, NULL), (2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, true, false, NULL) AS t(ORDER_ID, LOCATION_ID, CUSTOMER_ID, SUBTOTAL_CENTS, TAX_PAID_CENTS, ORDER_TOTAL_CENTS, SUBTOTAL, TAX_PAID, ORDER_TOTAL, ORDER_DATE, ORDER_COST, ORDER_ITEMS_SUBTOTAL, COUNT_FOOD_ITEMS, COUNT_DRINKS, COUNT_ORDER_ITEMS, IS_FOOD_ORDER, IS_DRINK_ORDER, CUSTOMER_ORDER_NUMBER)),
  	MATT_W_ANALYTICS_DEV_dbt_mwinkler_orders_actual as (

with

orders as (

    select * from MATT_W_ANALYTICS_DEV_dbt_mwinkler_stg_orders

),

order_items as (

    select * from MATT_W_ANALYTICS_DEV_dbt_mwinkler_order_items

),

order_items_summary as (

    select
        order_id,
        dateadd('day', '1', order_date) as one_day_ahead,
        sum(supply_cost) as order_cost,
        sum(product_price) as order_items_subtotal,
        count(order_item_id) as count_order_items,
        
        -- Try switching these from 'sum' to 'count' and then run 'dbt test'
        sum(
            case
                when is_food_item then 1
                else 0
            end
        ) as count_food_items,
        sum(
            case
                when is_drink_item then 1
                else 0
            end
        ) as count_drinks

    from order_items

   group by 1,2

),

compute_booleans as (

    select
        orders.*,

        order_items_summary.order_cost,
        order_items_summary.order_items_subtotal,
        order_items_summary.count_food_items,
        order_items_summary.count_drinks,
        order_items_summary.count_order_items,
        order_items_summary.count_food_items > 0 as is_food_order,
        order_items_summary.count_drinks > 0 as is_drink_order

    from orders

    left join
        order_items_summary
        on orders.order_id = order_items_summary.order_id

),

customer_order_count as (

    select
        *,

        row_number() over (
            partition by customer_id
            order by order_date asc
        ) as customer_order_number

    from compute_booleans

)

select * from customer_order_count)
            SELECT count_drinks, count_food_items, is_drink_order, is_food_order, order_id, 'actual' AS actual_or_expected FROM MATT_W_ANALYTICS_DEV_dbt_mwinkler_orders_actual 
            UNION ALL 
            SELECT count_drinks, count_food_items, is_drink_order, is_food_order, order_id, 'expected' AS actual_or_expected FROM MATT_W_ANALYTICS_DEV_dbt_mwinkler_orders_expect