-- latest login per user, showing the 5 most recent logins overall
select *
from (
         select distinct on (user_id)
             user_id,
             login_at,
             ip_address,
             device,
             successful
         from user_logins
         order by user_id, login_at desc
     ) latest_logins
order by login_at desc
    limit 5;


-- latest payment per order, showing the 5 most recent payments overall
select *
from (
         select distinct on (order_id)
             order_id,
             paid_at,
             status,
             provider
         from payments
         where paid_at is not null
         order by order_id, paid_at desc
     ) latest_payments
order by paid_at desc
    limit 5;

-- latest shipment per order, showing the 5 most recent shipments overall
select *
from (
         select distinct on (order_id)
             order_id,
             shipped_at,
             carrier,
             status
         from shipments
         where shipped_at is not null
         order by order_id, shipped_at desc
     ) latest_shipments
order by shipped_at desc
    limit 5;

-- normal SQL dialect alternative using GROUP BY
select
    order_id,
    max(shipped_at) as shipped_at_max
from shipments
where shipped_at is not null
group by order_id
order by shipped_at_max desc
    limit 5;


-- latest login with user information
select
    u.username,
    u.email,
    ul.login_at,
    ul.ip_address,
    ul.device
from (
         select distinct on (user_id)
             user_id,
             login_at,
             ip_address,
             device
         from user_logins
         order by user_id, login_at desc
     ) ul
         join users u on u.id = ul.user_id
order by ul.login_at desc
    limit 5;
