WITH
              	MATT_W_ANALYTICS_DEV_dbt_mwinkler_stg_supplies as (SELECT   CAST(SUPPLY_UUID AS VARCHAR) AS SUPPLY_UUID,
  CAST(SUPPLY_ID AS VARCHAR) AS SUPPLY_ID,
  CAST(PRODUCT_ID AS VARCHAR) AS PRODUCT_ID,
  CAST(SUPPLY_NAME AS VARCHAR) AS SUPPLY_NAME,
  CAST(SUPPLY_COST AS NUMBER(16,2)) AS SUPPLY_COST,
  CAST(IS_PERISHABLE_SUPPLY AS BOOLEAN) AS IS_PERISHABLE_SUPPLY  FROM VALUES (NULL, NULL, 1, NULL, 4.5, NULL), (NULL, NULL, 2, NULL, 3.5, NULL), (NULL, NULL, 2, NULL, 5.0, NULL) AS t(SUPPLY_UUID, SUPPLY_ID, PRODUCT_ID, SUPPLY_NAME, SUPPLY_COST, IS_PERISHABLE_SUPPLY)),
  	MATT_W_ANALYTICS_DEV_dbt_mwinkler_stg_products as (SELECT   CAST(PRODUCT_ID AS VARCHAR) AS PRODUCT_ID,
  CAST(PRODUCT_NAME AS VARCHAR) AS PRODUCT_NAME,
  CAST(PRODUCT_TYPE AS VARCHAR) AS PRODUCT_TYPE,
  CAST(PRODUCT_DESCRIPTION AS VARCHAR) AS PRODUCT_DESCRIPTION,
  CAST(PRODUCT_PRICE AS NUMBER(16,2)) AS PRODUCT_PRICE,
  CAST(IS_FOOD_ITEM AS BOOLEAN) AS IS_FOOD_ITEM,
  CAST(IS_DRINK_ITEM AS BOOLEAN) AS IS_DRINK_ITEM  FROM VALUES (1, NULL, NULL, NULL, NULL, NULL, NULL), (2, NULL, NULL, NULL, NULL, NULL, NULL) AS t(PRODUCT_ID, PRODUCT_NAME, PRODUCT_TYPE, PRODUCT_DESCRIPTION, PRODUCT_PRICE, IS_FOOD_ITEM, IS_DRINK_ITEM)),
  	MATT_W_ANALYTICS_DEV_dbt_mwinkler_stg_order_items as (SELECT   CAST(ORDER_ITEM_ID AS VARCHAR) AS ORDER_ITEM_ID,
  CAST(ORDER_ID AS VARCHAR) AS ORDER_ID,
  CAST(PRODUCT_ID AS VARCHAR) AS PRODUCT_ID  FROM VALUES (NULL, 1, 1), (NULL, 2, 2), (NULL, 2, 2) AS t(ORDER_ITEM_ID, ORDER_ID, PRODUCT_ID)),
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
  	MATT_W_ANALYTICS_DEV_dbt_mwinkler_order_items_expect as (SELECT   CAST(ORDER_ITEM_ID AS VARCHAR) AS ORDER_ITEM_ID,
  CAST(ORDER_ID AS VARCHAR) AS ORDER_ID,
  CAST(PRODUCT_ID AS VARCHAR) AS PRODUCT_ID,
  CAST(ORDER_DATE AS DATE) AS ORDER_DATE,
  CAST(PRODUCT_NAME AS VARCHAR) AS PRODUCT_NAME,
  CAST(PRODUCT_PRICE AS NUMBER(16,2)) AS PRODUCT_PRICE,
  CAST(IS_FOOD_ITEM AS BOOLEAN) AS IS_FOOD_ITEM,
  CAST(IS_DRINK_ITEM AS BOOLEAN) AS IS_DRINK_ITEM,
  CAST(SUPPLY_COST AS NUMBER(28,2)) AS SUPPLY_COST  FROM VALUES (NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, 4.5), (NULL, 2, 2, NULL, NULL, NULL, NULL, NULL, 8.5), (NULL, 2, 2, NULL, NULL, NULL, NULL, NULL, 8.5) AS t(ORDER_ITEM_ID, ORDER_ID, PRODUCT_ID, ORDER_DATE, PRODUCT_NAME, PRODUCT_PRICE, IS_FOOD_ITEM, IS_DRINK_ITEM, SUPPLY_COST)),
  	MATT_W_ANALYTICS_DEV_dbt_mwinkler_order_items_actual as (with

order_items as (

    select * from MATT_W_ANALYTICS_DEV_dbt_mwinkler_stg_order_items

),


orders as (

    select * from MATT_W_ANALYTICS_DEV_dbt_mwinkler_stg_orders

),

products as (

    select * from MATT_W_ANALYTICS_DEV_dbt_mwinkler_stg_products

),

supplies as (

    select * from MATT_W_ANALYTICS_DEV_dbt_mwinkler_stg_supplies

),

order_supplies_summary as (

    select
        product_id,

        sum(supply_cost) as supply_cost

    from supplies

    group by 1

),

joined as (

    select
        order_items.*,

        orders.order_date,

        products.product_name,
        products.product_price,
        products.is_food_item,
        products.is_drink_item,

        order_supplies_summary.supply_cost

    from order_items

    left join orders on order_items.order_id = orders.order_id

    left join products on order_items.product_id = products.product_id

    left join order_supplies_summary
        on order_items.product_id = order_supplies_summary.product_id

)

select * from joined
)
            SELECT order_id, product_id, supply_cost, 'actual' AS actual_or_expected FROM MATT_W_ANALYTICS_DEV_dbt_mwinkler_order_items_actual 
            UNION ALL 
            SELECT order_id, product_id, supply_cost, 'expected' AS actual_or_expected FROM MATT_W_ANALYTICS_DEV_dbt_mwinkler_order_items_expect