# PostgreSQL Advanced Practice Guide
## From SQL Proficiency to PostgreSQL Expertise

> **Disclaimer**
> 
> This practice guide was AI generated, so it might contain errors or inconsistencies that can be discovered as you go and try the exercises.

> **Audience**
>
> This guide assumes you already know SQL fundamentals (SELECT, INSERT, UPDATE, DELETE, JOINs, GROUP BY, indexes, constraints, normalization).
>
> The goal is to become comfortable writing production-quality PostgreSQL queries and understanding how PostgreSQL behaves internally.

---

# Learning Philosophy

This is not a tutorial where you simply read.

Each chapter contains:

- Theory
- PostgreSQL-specific notes
- Practice exercises
- Challenge exercises
- Things to inspect with EXPLAIN

Do **not** skip the exercises.

---

# Getting Started

## Prerequisites

- Podman & Podman Compose
- A PostgreSQL client for GUI access (DBeaver, DataGrip, pgAdmin) — **`psql` is not required on the host**, it runs inside the container

## 1. Start the Environment

A `compose.yml` is provided at the root of the repository. It spins up:

- **PostgreSQL 17** on port `5432` — database `demo`, user `demo`, password `demo`
- **pgAdmin 4** on port `8080` — login with `demo@demo.com` / `demo`

On first boot, PostgreSQL automatically runs all scripts in `compose/postgres/` in alphabetical order:

| Script | What it does |
|---|---|
| `01-schema.sql` | Creates all tables, types, and indexes |
| `02-functions.sql` | Registers helper functions used by the generator |
| `03-generate-data.sql` | Registers the `generate_demo_data()` procedure |
| `04-clean.sql` | Registers the `cleanup_demo_data()` procedure |

> **Note:** These scripts only define schema and routines — no data is inserted at startup.

```bash
podman compose up -d
```

Wait for the health-check to pass (about 10–15 seconds). The database is ready to use.

---

## 2. Generate Data

Open an interactive `psql` session inside the container:

```bash
podman compose exec postgres psql -U demo -d demo
```

Then call the generator procedure. With defaults it produces a realistic small-to-medium dataset:

```sql
CALL generate_demo_data();
```

Or pass any combination of parameters to control the volume:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `p_departments` | `int` | `15` | Number of departments to create |
| `p_employees` | `int` | `100` | Total employees (≈10% become managers) |
| `p_users` | `int` | `1000` | Number of customer accounts |
| `p_suppliers` | `int` | `50` | Number of product suppliers |
| `p_categories` | `int` | `30` | Total categories (≈20% root, rest subcategories) |
| `p_products` | `int` | `200` | Number of products |
| `p_orders` | `int` | `5000` | Number of orders |
| `p_max_order_items` | `int` | `5` | Max line items per order |
| `p_sessions` | `int` | `3000` | Number of user sessions |
| `p_api_requests` | `int` | `15000` | Number of API request log entries |
| `p_audit_logs` | `int` | `10000` | Number of audit log entries |
| `p_inventory` | `boolean` | `true` | Generate inventory & inventory transactions |
| `p_payments` | `boolean` | `true` | Generate payment records |
| `p_shipments` | `boolean` | `true` | Generate shipment tracking records |

### Examples

**Quick smoke test** — tiny dataset to verify everything works:

```sql
CALL generate_demo_data(
    p_departments => 5,
    p_employees   => 20,
    p_users       => 100,
    p_products    => 50,
    p_orders      => 200
);
```

**Medium dataset** — good for most exercises in this guide:

```sql
CALL generate_demo_data(
    p_users        => 10000,
    p_products     => 1000,
    p_orders       => 50000,
    p_api_requests => 100000,
    p_audit_logs   => 50000
);
```

**Large dataset** — for performance and optimization exercises (Parts 18–20, 28):

```sql
CALL generate_demo_data(
    p_users        => 100000,
    p_suppliers    => 500,
    p_categories   => 100,
    p_products     => 10000,
    p_orders       => 500000,
    p_sessions     => 200000,
    p_api_requests => 1000000,
    p_audit_logs   => 500000
);
```

> **Note:** The generator appends new rows each time it is called. Run `CALL cleanup_demo_data()` first if you want a clean slate.

### Generation Steps

The procedure reports progress via `NOTICE` messages as it works through 11 steps:

1. Departments
2. Employees & management hierarchy
3. Users
4. Categories & subcategory hierarchy
5. Suppliers
6. Products & SKUs
7. Inventory stock & transactions *(skippable)*
8. Orders & order items
9. Payments *(skippable)*
10. Shipments *(skippable)*
11. User sessions, API request logs & audit trails

---

## 3. Clean Up

To wipe all data and reset identity sequences:

```sql
CALL cleanup_demo_data();
```

---

## Schema Overview

The schema covers a realistic e-commerce domain:

```
users
orders          → order_items
payments
products        → inventory → inventory_transactions
categories      (self-referencing hierarchy)
suppliers
shipments
employees       (self-referencing manager hierarchy)
departments
audit_logs
sessions
api_requests
```

Target sizes for meaningful optimization practice:

- 1M+ users
- 10M+ orders
- 100M+ audit logs

Large datasets make index tuning, partition pruning, and query optimization exercises meaningful.

## Run your scripts

As you progress, you can always create the scripts within the project itself and rund them with `podman exec`. This will help you save your progress.

```shell
podman compose exec postgres psql -U demo -d demo -f /path/to/your/script.sql
```

---

# Part 1 – Advanced SELECT

## Goal

Write expressive queries without procedural code.

Topics

- DISTINCT ON
- FILTER
- CASE
- COALESCE
- NULLIF
- EXISTS
- ANY
- ALL
- LATERAL

---

## DISTINCT ON

PostgreSQL feature.

Instead of

```sql
ROW_NUMBER()
```

sometimes

```sql
SELECT DISTINCT ON (user_id)
*
FROM orders
ORDER BY user_id, created_at DESC;
```

returns the latest order per user.

### Exercise

Find:

- latest login
- latest payment
- latest shipment

without window functions.

---

## FILTER

Instead of

```sql
SUM(CASE WHEN ...)
```

use

```sql
SELECT

COUNT(*) FILTER (WHERE status='PAID'),

COUNT(*) FILTER (WHERE status='FAILED')

FROM payments;
```

Cleaner and faster.

Exercise:

Generate a report containing

- successful payments
- failed
- refunded
- pending

in one query.

---
## CASE

`CASE` allows you to implement conditional logic directly in SQL. It is similar to an `if/else` statement in programming languages.

```sql
CASE expression
    WHEN value THEN result
    WHEN value THEN result
    ELSE result
END
```

Return:

- username
- status
- account_state

Rules:

- ACTIVE → "Can Login"
- INACTIVE → "Disabled"
- SUSPENDED → "Locked"

---

## COALESCE

`COALESCE()` returns the first non-NULL value.

```sql
COALESCE(value1, value2, value3, ...)
```

Return each orders:

- id
- status
- employee_id

If `employee_id` is `NULL`, display `-1`.

---

## NULLIF

`NULLIF(a,b)` returns NULL if the two values are equal.

Calculate in the products table

```
price / cost
```

without raising an error when cost is zero.

---

## EXISTS

`EXISTS` checks whether at least one matching row exists.

Return every user that has placed at least one order.

---

## ANY

`ANY` compares one value against multiple values.

Return employees whose salary is greater than any salary in the Sales department.

---

## ALL

`ALL` compares one value against every value returned by a subquery.

Return products more expensive than **all** products supplied by supplier 1.

---

## LATERAL

`LATERAL` allows a subquery to reference columns from the current row.

It is extremely useful when you want the "top N related rows" for every row.

Return

- username
- latest login

Use `LATERAL`.

---

# Part 2 – Complex Joins

Topics

- INNER
- LEFT
- RIGHT
- FULL
- SELF
- CROSS
- LATERAL

---

## Self Join

Employees

```
employee
manager
```

Find

```
Employee
Manager
Manager's Manager
```

in one query.

---

## Anti Join

Find users that never placed an order.

Avoid

```sql
NOT IN
```

Use

```sql
NOT EXISTS
```

Explain why.

---

## LATERAL

One of PostgreSQL's most useful features.

Example

```sql
SELECT
u.id,
o.*
FROM users u
CROSS JOIN LATERAL (

SELECT *
FROM orders
WHERE orders.user_id=u.id
ORDER BY created_at DESC
LIMIT 3

) o;
```

Exercise

Retrieve

Top 5 purchases for every customer.

---

# Part 3 – Advanced Aggregation

Topics

- GROUPING SETS
- ROLLUP
- CUBE
- HAVING
- FILTER

---

## ROLLUP

Instead of multiple UNIONs.

Example

```
Country

City

Revenue
```

Generate

Country totals

AND

Grand total

using

```sql
ROLLUP
```

---

## GROUPING SETS

Practice producing

```
Revenue by

country

city

product

month

all products
```

using one query.

---

# Part 4 – Window Functions

One of the most important PostgreSQL skills.

Topics

- ROW_NUMBER
- RANK
- DENSE_RANK
- NTILE
- LAG
- LEAD
- FIRST_VALUE
- LAST_VALUE
- running totals
- moving averages

---

## Running Total

```sql
SUM(amount)

OVER(

ORDER BY created_at

)
```

Exercise

Generate account balance after every transaction.

---

## LAG

Find

Difference between consecutive purchases.

---

## LEAD

Predict next scheduled shipment.

---

## Challenge

Compute

Customer lifetime value

without subqueries.

---

# Part 5 – CTEs

Topics

- Ordinary
- Recursive
- Materialization

---

## CTE

```sql
WITH recent_orders AS (

SELECT ...

)

SELECT ...
```

When does PostgreSQL inline CTEs?

When is it materialized?

Read

```
EXPLAIN
```

---

# Recursive CTE

Hierarchy

```
CEO

↓

Manager

↓

Developer

↓

Intern
```

Build

Org chart.

---

Challenge

Traverse

Categories

with unlimited nesting.

---

# Part 6 – Recursive Problems

Implement

Filesystem traversal

```
/

├── home

│ ├── user

│ └── admin
```

Exercise

Return full path

```
/home/user/documents
```

---

Generate

Calendar table

using recursion.

---

# Part 7 – Set Operations

Topics

- UNION
- UNION ALL
- INTERSECT
- EXCEPT

Exercise

Customers

who

ordered

AND

requested refunds.

---

Exercise

Customers

who ordered

BUT

never logged in.

---

# Part 8 – Subqueries

Practice

Correlated

Non-correlated

Scalar

EXISTS

IN

ANY

ALL

---

Challenge

Rewrite every query using a JOIN.

Compare execution plans.

---

# Part 9 – JSONB

One of PostgreSQL's strongest features.

Topics

```
json

jsonb
```

operators

```
->

->>

#

@>

?
```

Indexes

GIN

---

Store

```
preferences

metadata

configuration
```

inside JSON.

---

Exercise

Find

Users

whose

```
theme=dark
```

---

Challenge

Index JSON.

Measure performance.

---

# Part 10 – Arrays

Topics

```
[]

ANY

UNNEST
```

Exercise

Products

containing

```
electronics
```

inside category array.

---

# Part 11 – String Functions

Practice

```
regexp_replace

regexp_matches

split_part

concat_ws

format

translate
```

Exercise

Normalize phone numbers.

---

Challenge

Extract domain

from email.

---

# Part 12 – Date & Time

Topics

```
date_trunc

age

interval

extract

generate_series
```

Exercise

Generate daily revenue.

---

Challenge

Find users inactive

for exactly

90–120 days.

---

# Part 13 – Transactions

Topics

ACID

BEGIN

COMMIT

ROLLBACK

SAVEPOINT

---

Exercise

Transfer money.

Requirements

- deduct account A
- add account B
- insert audit log

Rollback on error.

---

Nested rollback

```
SAVEPOINT
```

Practice partial rollback.

---

# Part 14 – Isolation Levels

One of the most important PostgreSQL topics.

Levels

- Read Committed
- Repeatable Read
- Serializable

Understand

Dirty Reads

Non-repeatable Reads

Phantom Reads

Serialization failures

---

Exercise

Open

two terminals.

Observe behavior.

---

Scenario

Transaction A

reads balance.

Transaction B

updates balance.

What happens under each isolation level?

---

Challenge

Create

serialization failure.

Handle retry.

---

# Part 15 – MVCC

Understand

PostgreSQL never overwrites rows.

Topics

- xmin
- xmax
- tuple visibility
- snapshots

Run

```
SELECT xmin, xmax
```

Observe updates.

---

Read

```
VACUUM
```

Understand dead tuples.

---

# Part 16 – Locking

Topics

```
FOR UPDATE

FOR SHARE

SKIP LOCKED

NOWAIT
```

Exercise

Build

Job Queue.

Workers should

never process same job.

---

Challenge

Implement

queue

without race conditions.

---

# Part 17 – Deadlocks

Create

two sessions.

Update rows

in opposite order.

Observe

```
deadlock detected
```

Learn

deadlock prevention.

---

# Part 18 – Indexes

Types

- BTree
- Hash
- GIN
- GiST
- BRIN
- Partial
- Expression
- Covering

---

Exercise

Index

```
LOWER(email)
```

Compare.

---

Partial Index

Only

```
status='ACTIVE'
```

Measure.

---

Challenge

Remove

redundant indexes.

---

# Part 19 – Query Optimization

Absolutely essential.

Topics

```
EXPLAIN

EXPLAIN ANALYZE
```

Understand

- Seq Scan
- Bitmap Scan
- Index Scan
- Nested Loop
- Merge Join
- Hash Join

---

Exercise

Predict plan.

Run plan.

Compare prediction.

---

Read

```
Buffers

Planning Time

Execution Time

Rows

Loops
```

---

Challenge

Reduce

query

from

5 s

to

100 ms.

---

# Part 20 – Statistics

Topics

```
ANALYZE

default_statistics_target

pg_stats
```

Understand

planner estimates.

---

Exercise

Cause planner

to choose

wrong index.

Explain why.

---

# Part 21 – Partitioning

Types

Range

Hash

List

---

Partition

```
orders
```

by year.

Query

one month.

Observe

partition pruning.

---

# Part 22 – Materialized Views

Create

Revenue Dashboard.

Refresh.

Compare

view

vs

materialized view.

---

# Part 23 – Functions

Create

```
LANGUAGE SQL
```

functions.

Then

```
PL/pgSQL
```

functions.

---

Exercise

Create

Tax calculator.

---

Challenge

Return table.

---

# Part 24 – Triggers

Implement

Audit table.

Track

UPDATE

DELETE

INSERT.

---

Challenge

Soft delete.

---

# Part 25 – Full Text Search

Topics

```
tsvector

tsquery

GIN
```

Build

Product search.

---

Challenge

Rank

search results.

---

# Part 26 – Practical Reporting Challenges

## Sales Dashboard

Produce

- monthly revenue
- quarterly growth
- YoY growth
- top products
- top customers
- average order value
- rolling 30-day revenue

---

## Fraud Detection

Detect

- duplicate payments
- suspicious login locations
- repeated failed payments
- impossible travel

---

## Inventory

Find

Products

likely

to stock out

within

14 days.

---

## Customer Analytics

Compute

- lifetime value
- average purchase interval
- churn risk
- retention cohort
- first purchase
- last purchase
- RFM segmentation

---

# Part 27 – PostgreSQL System Catalogs

Become familiar with

```
pg_class

pg_index

pg_attribute

pg_constraint

pg_stat_activity

pg_locks

pg_stat_user_tables

pg_stat_statements
```

Exercises

- List all indexes in the database.
- Find tables with no primary key.
- Show currently running queries.
- Detect blocking sessions.
- Find unused indexes.
- Display table and index sizes.
- Identify tables with the most dead tuples.

---

# Part 28 – Performance Lab

Create a table with 10 million rows.

```sql
CREATE TABLE benchmark AS
SELECT
    generate_series(1,10000000) AS id,
    md5(random()::text) AS value,
    now() - (random() * interval '365 days') AS created_at,
    (random()*1000)::int AS score;
```

Now practice:

- Sequential scan vs Index Scan
- Composite indexes
- Partial indexes
- Covering indexes (`INCLUDE`)
- BRIN vs B-tree on timestamps
- Parallel query execution
- `work_mem` effects on sorting
- Hash Aggregate vs Group Aggregate
- Join algorithm selection

Record:

- Execution time
- Buffers hit/read
- Rows processed
- Query plan differences

---

# Part 29 – End-to-End Project

Build an e-commerce analytics database.

Requirements:

- 10M orders
- 1M customers
- 500K products
- Historical pricing
- Inventory snapshots
- Payments
- Refunds
- Shipments

Implement:

- Partitioned tables
- JSONB metadata
- Materialized reporting views
- Recursive category hierarchy
- Audit triggers
- Optimized indexes
- Transaction-safe inventory updates
- Background job queue using `SKIP LOCKED`

Produce dashboards for:

- Revenue
- Customer growth
- Product performance
- Inventory turnover
- Operational KPIs

Optimize every report until execution time is under one second.

---

# Suggested Study Order

| Phase | Topics |
|--------|--------|
| 1 | Advanced SELECT, Joins, Aggregation |
| 2 | Window Functions, CTEs, Recursive Queries |
| 3 | JSONB, Arrays, Strings, Dates |
| 4 | Transactions, MVCC, Isolation Levels |
| 5 | Locking, Deadlocks, Concurrency |
| 6 | Indexes, EXPLAIN ANALYZE, Statistics |
| 7 | Partitioning, Materialized Views |
| 8 | Functions, Triggers, Full Text Search |
| 9 | PostgreSQL System Catalogs |
| 10 | Large-scale Performance Lab & End-to-End Project |

---

# Additional Reading

- *The Internals of PostgreSQL* — Hironobu Suzuki
- *Mastering PostgreSQL* — Dimitri Fontaine
- *PostgreSQL Query Optimization* — Henrietta Dombrovskaya
- PostgreSQL Official Documentation (especially chapters on SQL, indexes, MVCC, locking, and query planning)

---

# Final Challenge

Given a production database with:

- 250 million orders
- 50 million users
- 2 billion audit records

Your objectives are to:

1. Design an indexing strategy that balances read performance and write overhead.
2. Diagnose and eliminate slow queries using `EXPLAIN ANALYZE`, planner statistics, and index tuning.
3. Prevent deadlocks and ensure correctness under concurrent writes with appropriate locking strategies.
4. Choose the correct isolation level for payment processing, inventory management, and reporting workloads.
5. Partition large tables and verify partition pruning in execution plans.
6. Build recursive queries for organizational hierarchies and product category trees.
7. Create reporting queries using window functions, `GROUPING SETS`, `ROLLUP`, and materialized views.
8. Optimize JSONB-heavy workloads with GIN indexes and efficient operators.
9. Build a resilient worker queue using `FOR UPDATE SKIP LOCKED`.
10. Keep all critical dashboard queries under one second while maintaining transactional correctness.

If you can comfortably complete this project and explain every execution plan involved, you have reached a strong intermediate-to-advanced PostgreSQL skill level suitable for most backend engineering and database-focused roles.