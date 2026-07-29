select u.id, u.username
from users u
where exists (
    select id
    from orders o
    where o.user_id = u.id
)
limit 10;

select u.id, u.username
from users u
where not exists (
    select id
    from orders o
    where o.user_id = u.id
)
limit 10;