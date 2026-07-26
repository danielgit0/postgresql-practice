select count(*) filter (where status = 'SUCCESS') as success,
       count(*) filter (where status = 'FAILED') as failed,
       count(*) filter (where status = 'REFUNDED') as refunded,
       count(*) filter (where status = 'PENDING') as pending,
       count(*) as total
from payments;
