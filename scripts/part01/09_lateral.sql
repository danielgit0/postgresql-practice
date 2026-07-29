select user_id
from user_logins
order by login_at desc
fetch first 3 rows only;

select u.id,
       u.username,
       lat.login_at
from users u
         cross join lateral (
    select ul.login_at
    from user_logins ul
    where u.id = ul.user_id
    order by ul.login_at desc
        fetch first 3 rows only
    ) as lat
order by u.username, lat.login_at desc
limit 5;