-- find employee -> manager -> manager's manager
-- left join is better for cases in which the employee does not have a direct manager
select e1.id, e1.first_name as employee, e2.id, e2.first_name as manager, e3.id, e3.first_name as manager_manager
from employees e1
         left join employees e2
                    on e1.manager_id = e2.id
         left join employees e3
             on e2.manager_id = e3.id
order by e3.id
limit 20;

-- using a recursive table with custom table expression (CTE - more on Pat 5)
-- in this case to find the subordinates of employee id = 1
/*
Example result
 id | manager_id |    full_name
----+------------+------------------
  1 |            | John Roberts         -> Base result user_id=1
--                                      -> Recursive member 1, users where user_id=1 is the manager
 59 |          1 | Helen Gomez
 64 |          1 | Steven Gonzalez
 86 |          1 | Robert Taylor
 87 |          1 | Michael Reyes
  2 |          1 | Jeffrey Peterson
--                                      -> Recursive member 2, users where user id=2 is the manager
 36 |          2 | Helen Lopez
 42 |          2 | Stephen Lewis
 55 |          2 | Amanda Kelly
 71 |          2 | Julia Harris
*/
with recursive subordinates(id, manager_id, full_name) as (
    select
        id,
        manager_id,
        first_name || ' ' || last_name
    from employees
    where id = 1

    union

    select
        e.id,
        e.manager_id,
        e.first_name || ' ' || e.last_name
    from employees e
            inner join subordinates s on s.id = e.manager_id
)
select * from subordinates;