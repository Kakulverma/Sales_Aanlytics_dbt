{{ config(materialized="table") }}

with 
    kpi as (select invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id,country, (quantity * unit_price)  as line_amount  from {{ ref("stg_sales") }}),

    tsr as (select sum(line_amount) as total_sales_revenue from kpi),

    aov as (
        select sum(line_amount) / count(distinct(invoice_no)) as avg_order_value
        from kpi
    ),

    clv as (
        select customer_id, sum(line_amount) as customer_revenue
        from kpi
        group by customer_id
    ),
    clv_final as (select avg(customer_revenue) as avg_customer_revenue from clv),

    mst as (
        select
            extract(year from invoice_date) as years,
            extract(month from invoice_date) as months,
            sum(line_amount) as total_revenues
        from kpi
        group by 1, 2
    ),
    top_10_bsp as (
        select
            stock_code,
            sum(line_amount) as product_revenue,
            rank() over (order by sum(line_amount)) as product_rank
        from kpi
        group by 1
        qualify product_rank <= 10

    )

select
    t.total_sales_revenue,
    a.avg_order_value,
    c.avg_customer_revenue,
    tr.years,
    tr.months,
    tr.total_revenues,
    p.stock_code,
    p.product_revenue,
    p.product_rank
from tsr t
cross join aov a
cross join clv_final c
cross join mst tr
cross join top_10_bsp p
