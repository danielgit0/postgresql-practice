/*
it works similarly to the rollup, but it computes more combinations

For N input columns, ROLLUP produces N + 1 grouping levels.
For N input columns,CUBE produces \[2^{N}\] grouping sets (exponentially more combinations).
*/

select status,
       sum(total_amount)
from orders
group by
    cube (status)
order by status;

select status,
       user_id,
       sum(total_amount)
from orders
where user_id = '00097fcf-dede-4532-854d-4aab1ca3b94f'
group by status,
    cube ( user_id)
order by status,
         user_id;

select user_id,
       employee_id,
       status,
       sum(total_amount)
from orders
where user_id = '00097fcf-dede-4532-854d-4aab1ca3b94f'
group by
    cube (user_id, employee_id, status);

/*
               user_id                | employee_id |   status   |   sum
--------------------------------------+-------------+------------+----------
                                      |             |            | 12551.20
 00097fcf-dede-4532-854d-4aab1ca3b94f |          14 | PENDING    |  2748.15
 00097fcf-dede-4532-854d-4aab1ca3b94f |          46 | PROCESSING |  7842.44
 00097fcf-dede-4532-854d-4aab1ca3b94f |          25 | SHIPPED    |  1960.61
 00097fcf-dede-4532-854d-4aab1ca3b94f |          14 |            |  2748.15
 00097fcf-dede-4532-854d-4aab1ca3b94f |          25 |            |  1960.61
 00097fcf-dede-4532-854d-4aab1ca3b94f |          46 |            |  7842.44
 00097fcf-dede-4532-854d-4aab1ca3b94f |             |            | 12551.20
                                      |          25 | SHIPPED    |  1960.61
                                      |          14 | PENDING    |  2748.15
                                      |          46 | PROCESSING |  7842.44
                                      |          46 |            |  7842.44
                                      |          14 |            |  2748.15
                                      |          25 |            |  1960.61
 00097fcf-dede-4532-854d-4aab1ca3b94f |             | PROCESSING |  7842.44
 00097fcf-dede-4532-854d-4aab1ca3b94f |             | SHIPPED    |  1960.61
 00097fcf-dede-4532-854d-4aab1ca3b94f |             | PENDING    |  2748.15
                                      |             | SHIPPED    |  1960.61
                                      |             | PENDING    |  2748.15
                                      |             | PROCESSING |  7842.44
(20 rows)
*/
