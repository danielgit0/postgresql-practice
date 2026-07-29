select id,
       status,
       coalesce(employee_id, -1) employee_id
from orders
limit 10;