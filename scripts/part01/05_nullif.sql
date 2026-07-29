select id,
       price,
       cost,
       -- there was no cost = 0 within the generated data,
       -- so I used one of the rando generated values from the result to force it.
       -- the value might be different everytime the data is generated
       price / nullif(cost, 241.39) price_div_by_cost
from products
limit 10;