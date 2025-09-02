{{ config(materialized="table") }}

with
    explr as (select * from {{ ref("stg_sales") }}),

    summary as (
        select
            count(*) as total_records,
            count(distinct(stock_code)) as unique_items,
            count(distinct(customer_id)) as unique_customer_id,
            count(distinct(country)) as unique_country
        from explr
    ),
    distribution_sales as (
        select
            sum(line_amount) as total_sales,
            count(distinct(customer_id)) as customer_count,
            count(distinct(invoice_no)) as invoice_count,
            country
        from explr
        group by country

    )
select
    s.total_records,
    s.unique_items,
    s.unique_customer_id,
    s.unique_country,
    d.total_sales,
    d.customer_count,
    d.country,
    d.invoice_count
from summary s
cross join distribution_sales d
order by d.total_sales
