select status,
       sum(total_amount)
from orders
group by
    rollup (status)
order by status;

select status,
       user_id,
       sum(total_amount)
from orders
where user_id = '00097fcf-dede-4532-854d-4aab1ca3b94f'
group by status,
    rollup ( user_id)
order by status,
         user_id;

select status,
       user_id,
       sum(total_amount)
from orders
where user_id = '00097fcf-dede-4532-854d-4aab1ca3b94f'
group by status,
    rollup ( user_id)
order by status,
         user_id;

select user_id,
       employee_id,
       status,
       sum(total_amount)
from orders
where user_id = '00097fcf-dede-4532-854d-4aab1ca3b94f'
group by
    rollup (user_id, employee_id, status);

/*
               user_id                | employee_id |   status   |   sum
--------------------------------------+-------------+------------+----------
 00097fcf-dede-4532-854d-4aab1ca3b94f |          14 | PENDING    |  2748.15
 00097fcf-dede-4532-854d-4aab1ca3b94f |          14 |            |  2748.15
 00097fcf-dede-4532-854d-4aab1ca3b94f |          25 | SHIPPED    |  1960.61
 00097fcf-dede-4532-854d-4aab1ca3b94f |          25 |            |  1960.61
 00097fcf-dede-4532-854d-4aab1ca3b94f |          46 | PROCESSING |  7842.44
 00097fcf-dede-4532-854d-4aab1ca3b94f |          46 |            |  7842.44
 00097fcf-dede-4532-854d-4aab1ca3b94f |             |            | 12551.20
                                      |             |            | 12551.20
(8 rows)
*/