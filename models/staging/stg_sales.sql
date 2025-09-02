{{config(materialized = 'view')}}


with src as (
    select * from {{source('sales_dataset','sales_raw')}}
),

typed as (
    select 
      cast(InvoiceNO as string) as invoice_no,
      cast(StockCode as string) as stock_code,
      trim(Description) as description,
      cast(Quantity as int64) as quantity,
      cast(InvoiceDate as timestamp) as invoice_date,
      cast(UnitPrice as numeric) as unit_price,
      cast(CustomerID as string) as customer_id,
      trim(Country) as country 
from src
),

filtered as (
    select * from typed
    where invoice_no is not null
    and   quantity is not null
    and   customer_id is not null
    and stock_code is not null
    and invoice_date is not  null
    and unit_price is not null
),
dedup as (select * except(rn)
from(
    select *,
    row_number()over(partition by invoice_no,stock_code,description,quantity,invoice_date,unit_price, customer_id,country order by invoice_no) as rn
    from filtered
)
where rn = 1
)

select 
invoice_no,stock_code,description,quantity,invoice_date,unit_price,customer_id,country,
quantity * unit_price AS line_amount
from dedup