select id
from departments
where name = 'Sales';

select salary
from employees
where department_id = (
    select id
    from departments
    where name = 'Sales'
)
order by salary desc ;

select
    e.first_name,
    e.last_name,
    e.salary,
    e.department_id
from employees e
where e.salary > any (
    select salary
    from employees
    where department_id = (
        select id
        from departments
        where name = 'Sales'
    )
)
order by e.salary desc;