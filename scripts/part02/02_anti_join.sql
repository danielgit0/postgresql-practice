-- find users that never placed an order
-- You should avoid NOT IN and use NOT EXISTS for anti joins
-- because NOT IN fails and returns no results if the subquery contains even a single NULL value.
select u.id, u.first_name || ' ' || u.last_name as name
from users u
where not exists (
    select *
    from orders o
    where u.id = o.user_id
);

-- try to get orders from any of the users in the previous query should return no results
select user_id, id
from orders
where user_id = '07033440-f147-4847-8f22-4e817670f194';