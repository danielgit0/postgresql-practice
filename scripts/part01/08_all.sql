select price
from products
where supplier_id = 1
order by price desc
limit 5;

select id, name, price
from products
where price > all (select price
                   from products
                   where supplier_id = 1)
order by price
limit 5;