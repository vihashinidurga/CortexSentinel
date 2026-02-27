with customer_revenue as (
    select * from {{ ref('int_customer_revenue') }}
),

top_customers as (
    select
        customer_id,
        customer_name,
        total_revenue
    from customer_revenue
    order by total_revenue desc
    limit 10
)

select * from top_customers
