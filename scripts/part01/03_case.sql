select username,
       status,
       case status
           when 'ACTIVE' then 'Can Login'
           when 'INACTIVE' then 'Disabled'
           when 'SUSPENDED' then 'Locked'
           else 'Unknown'
           end as account_state
from users
limit 20;