-- Retrieve top 5 purchases for every customer.
select u.id,
       o.total_amount
from users u
         cross join lateral (
    select *
    from orders
    where orders.user_id = u.id
    order by total_amount desc
        limit 5
) o
limit 20;