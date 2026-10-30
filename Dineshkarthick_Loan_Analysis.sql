CREATE DATABASE bank_db;
USE bank_db;


CREATE TABLE district (
 
  district_id INT PRIMARY KEY, district_name VARCHAR(50), region VARCHAR(30), inhabitants INT,
 
  municipalities_lt_499 INT, municipalities_500_1999 INT, municipalities_2000_9999 INT, municipalities_gt_10000 INT,
 
  cities INT, urban_ratio_pct DECIMAL(5,1), avg_salary INT,
 
  unemployment_rate_95 VARCHAR(10), unemployment_rate_96 DECIMAL(4,2),
 
  entrepreneurs_per_1000 INT, crimes_95 VARCHAR(10), crimes_96 INT);



CREATE TABLE account (account_id INT PRIMARY KEY, district_id INT, frequency VARCHAR(30), date DATE,
 
  FOREIGN KEY (district_id) REFERENCES district(district_id));




CREATE TABLE client (client_id INT PRIMARY KEY, birth_date DATE, gender CHAR(1), district_id INT,
 
  FOREIGN KEY (district_id) REFERENCES district(district_id));





CREATE TABLE disposition (disp_id INT PRIMARY KEY, client_id INT, account_id INT, type VARCHAR(10),
 
  FOREIGN KEY (client_id) REFERENCES client(client_id), FOREIGN KEY (account_id) REFERENCES account(account_id));





CREATE TABLE card (card_id INT PRIMARY KEY, disp_id INT, type VARCHAR(10), issued DATE,
 
  FOREIGN KEY (disp_id) REFERENCES disposition(disp_id));





CREATE TABLE loan (loan_id INT PRIMARY KEY, account_id INT, date DATE, amount INT, duration INT,
 
  payments DECIMAL(10,2), status CHAR(1), FOREIGN KEY (account_id) REFERENCES account(account_id));





CREATE TABLE `order` (order_id INT PRIMARY KEY, account_id INT, bank_to VARCHAR(5), account_to VARCHAR(20),
 
  amount DECIMAL(10,2), k_symbol VARCHAR(15), FOREIGN KEY (account_id) REFERENCES account(account_id));
  
  

-- Verify row counts in all 7 tables --

SELECT 'district' AS table_name, COUNT(*) AS total_rows
FROM district

UNION ALL

SELECT 'account', COUNT(*)
FROM account

UNION ALL

SELECT 'client', COUNT(*)
FROM client

UNION ALL

SELECT 'disposition', COUNT(*)
FROM disposition

UNION ALL

SELECT 'card', COUNT(*)
FROM card

UNION ALL

SELECT 'loan', COUNT(*)
FROM loan

UNION ALL

SELECT 'order', COUNT(*)
FROM `order`;




-- Loan data verification --
USE bank_db;

SELECT
    COUNT(*) AS total_loans,
    MIN(`date`) AS first_loan_date,
    MAX(`date`) AS last_loan_date,
    SUM(amount) AS total_loan_amount,
    ROUND(AVG(amount), 2) AS average_loan_amount
FROM loan;




-- Primary key duplicates check --

USE bank_db;

SELECT 'district' AS table_name,
       COUNT(*) - COUNT(DISTINCT district_id) AS duplicate_ids
FROM district

UNION ALL

SELECT 'account',
       COUNT(*) - COUNT(DISTINCT account_id)
FROM account

UNION ALL

SELECT 'client',
       COUNT(*) - COUNT(DISTINCT client_id)
FROM client

UNION ALL

SELECT 'disposition',
       COUNT(*) - COUNT(DISTINCT disp_id)
FROM disposition

UNION ALL

SELECT 'card',
       COUNT(*) - COUNT(DISTINCT card_id)
FROM card

UNION ALL

SELECT 'loan',
       COUNT(*) - COUNT(DISTINCT loan_id)
FROM loan

UNION ALL

SELECT 'order',
       COUNT(*) - COUNT(DISTINCT order_id)
FROM `order`;





-- Check NULL values in all 7 tables --
USE bank_db;

SELECT
    'district' AS table_name,
    SUM(district_id IS NULL) AS null_ids
FROM district

UNION ALL

SELECT 'account', SUM(account_id IS NULL)
FROM account

UNION ALL

SELECT 'client', SUM(client_id IS NULL)
FROM client

UNION ALL

SELECT 'disposition', SUM(disp_id IS NULL)
FROM disposition

UNION ALL

SELECT 'card', SUM(card_id IS NULL)
FROM card

UNION ALL

SELECT 'loan', SUM(loan_id IS NULL)
FROM loan

UNION ALL

SELECT 'order', SUM(order_id IS NULL)
FROM `order`;




-- Foreign key check orhpan record --

USE bank_db;

-- 1. Account -> District
SELECT
    'account_district' AS relationship_name,
    COUNT(*) AS orphan_rows
FROM account a
LEFT JOIN district d
    ON a.district_id = d.district_id
WHERE d.district_id IS NULL

UNION ALL

-- 2. Client -> District
SELECT
    'client_district',
    COUNT(*)
FROM client c
LEFT JOIN district d
    ON c.district_id = d.district_id
WHERE d.district_id IS NULL

UNION ALL

-- 3. Disposition -> Client
SELECT
    'disposition_client',
    COUNT(*)
FROM disposition dp
LEFT JOIN client c
    ON dp.client_id = c.client_id
WHERE c.client_id IS NULL

UNION ALL

-- 4. Disposition -> Account
SELECT
    'disposition_account',
    COUNT(*)
FROM disposition dp
LEFT JOIN account a
    ON dp.account_id = a.account_id
WHERE a.account_id IS NULL

UNION ALL

-- 5. Card -> Disposition
SELECT
    'card_disposition',
    COUNT(*)
FROM card ca
LEFT JOIN disposition dp
    ON ca.disp_id = dp.disp_id
WHERE dp.disp_id IS NULL

UNION ALL

-- 6. Loan -> Account
SELECT
    'loan_account',
    COUNT(*)
FROM loan l
LEFT JOIN account a
    ON l.account_id = a.account_id
WHERE a.account_id IS NULL

UNION ALL

-- 7. Order -> Account
SELECT
    'order_account',
    COUNT(*)
FROM `order` o
LEFT JOIN account a
    ON o.account_id = a.account_id
WHERE a.account_id IS NULL;










-- view --

USE bank_db;

CREATE OR REPLACE VIEW vw_loan_master AS
SELECT
    l.loan_id,
    l.account_id,
    l.date AS loan_date,
    l.amount,
    l.duration,
    l.payments,
    l.status,

    CASE
        WHEN l.status IN ('B', 'D') THEN 1
        ELSE 0
    END AS bad_loan,

    CASE
        WHEN l.amount < 100000 THEN 'Under 100k'
        WHEN l.amount < 200000 THEN '100-200k'
        WHEN l.amount < 300000 THEN '200-300k'
        ELSE 'Over 300k'
    END AS amount_band,

    TIMESTAMPDIFF(
        YEAR, c.birth_date, l.date
    ) AS age_at_loan,

    a.district_id,
    a.frequency AS account_frequency,
    a.date AS account_open_date,

    d.district_name,
    d.region,
    d.inhabitants,
    d.municipalities_lt_499,
    d.municipalities_500_1999,
    d.municipalities_2000_9999,
    d.municipalities_gt_10000,
    d.cities,
    d.urban_ratio_pct,
    d.avg_salary,
    d.unemployment_rate_95,
    d.unemployment_rate_96,
    d.entrepreneurs_per_1000,
    d.crimes_95,
    d.crimes_96,

    c.client_id,
    c.gender,
    c.birth_date

FROM loan l

INNER JOIN account a
    ON l.account_id = a.account_id

INNER JOIN district d
    ON a.district_id = d.district_id

INNER JOIN disposition dp
    ON a.account_id = dp.account_id
    AND dp.type = 'OWNER'

INNER JOIN client c
    ON dp.client_id = c.client_id;
    
    
    
    
    
    
    
    
    SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT loan_id) AS unique_loans,
    SUM(amount) AS total_loan_amount
FROM vw_loan_master;







-- analytical queries --

-- Overall Loan Portfolio KPIs --

USE bank_db;

SELECT
    COUNT(DISTINCT loan_id) AS total_loans,
    SUM(amount) AS total_loan_amount,
    ROUND(AVG(amount), 2) AS average_loan_amount,
    ROUND(AVG(duration), 2) AS average_duration_months,
    SUM(bad_loan) AS bad_loans,

    ROUND(
        100.0 * SUM(bad_loan) / COUNT(*), 2
    ) AS bad_loan_pct,

    SUM(
        CASE
            WHEN bad_loan = 1 THEN amount
            ELSE 0
        END
    ) AS bad_loan_amount,

    ROUND(
        100.0 * SUM(
            CASE WHEN bad_loan = 1 THEN amount ELSE 0 END
        ) / SUM(amount),
        2
    ) AS exposure_at_risk_pct

FROM vw_loan_master;






-- Loan Status Distribution --

SELECT
    loan_status,
    COUNT(*) AS total_loans,
    SUM(loan_amount) AS total_loan_amount,

    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM vw_loan_master),
        2
    ) AS loan_percentage

FROM (
    SELECT
        loan_id,
        status AS loan_status,
        amount AS loan_amount
    FROM vw_loan_master
) AS loan_data

GROUP BY loan_status
ORDER BY loan_status;






-- Loan Amount Band Analysis --

SELECT
    amount_band,

    COUNT(*) AS total_loans,

    SUM(loan_amount) AS total_loan_amount,

    SUM(bad_loan) AS bad_loans,

    ROUND(
        100.0 * SUM(bad_loan) / COUNT(*),
        2
    ) AS bad_loan_pct,

    SUM(
        CASE
            WHEN bad_loan = 1 THEN loan_amount
            ELSE 0
        END
    ) AS bad_loan_amount

FROM vw_loan_master

GROUP BY amount_band

ORDER BY
    CASE amount_band
        WHEN 'Under 100k' THEN 1
        WHEN '100-200k' THEN 2
        WHEN '200-300k' THEN 3
        WHEN 'Over 300k' THEN 4
        ELSE 5
    END;
    
    
    
    
    
    
  -- Region-wise Loan Risk Analysis — JOIN --
  
  SELECT
    d.region,

    COUNT(*) AS total_loans,

    SUM(v.amount) AS total_loan_amount,

    SUM(v.bad_loan) AS bad_loans,

    ROUND(
        100.0 * SUM(v.bad_loan) / COUNT(*),
        2
    ) AS bad_loan_pct,

    SUM(
        CASE
            WHEN v.bad_loan = 1 THEN v.amount
            ELSE 0
        END
    ) AS bad_loan_amount

FROM vw_loan_master v

INNER JOIN district d
    ON v.district_id = d.district_id

GROUP BY d.region

ORDER BY bad_loan_pct DESC;







-- Loan Duration vs Repayment Risk --

SELECT
    duration AS loan_duration_months,

    COUNT(*) AS total_loans,

    ROUND(AVG(amount), 2) AS average_loan_amount,

    ROUND(AVG(payments), 2) AS average_monthly_payment,

    SUM(bad_loan) AS bad_loans,

    ROUND(
        100.0 * SUM(bad_loan) / COUNT(*),
        2
    ) AS bad_loan_pct

FROM vw_loan_master

WHERE duration IN (12, 24, 36, 48, 60)

GROUP BY duration

ORDER BY duration;







-- Customer Age Group vs Loan Risk --


USE bank_db;

SELECT
    CASE
        WHEN age_at_loan < 30 THEN 'Under 30'
        WHEN age_at_loan BETWEEN 30 AND 44 THEN '30-44'
        WHEN age_at_loan BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60+'
    END AS age_group,

    COUNT(*) AS total_loans,

    SUM(CASE
        WHEN bad_loan = 1 THEN 1
        ELSE 0
    END) AS bad_loans,

    ROUND(
        SUM(CASE
            WHEN bad_loan = 1 THEN 1
            ELSE 0
        END) * 100.0 / COUNT(*),
        2
    ) AS bad_loan_percentage

FROM vw_loan_master

WHERE age_at_loan IS NOT NULL

GROUP BY age_group

ORDER BY bad_loan_percentage DESC;







-- Year-wise Loan Amount Growth — CTE + Window Function --

USE bank_db;

WITH yearly_loans AS (
    SELECT
        YEAR(loan_date) AS loan_year,
        SUM(amount) AS total_loan_amount,
        COUNT(DISTINCT loan_id) AS total_loans
    FROM vw_loan_master
    WHERE loan_date IS NOT NULL
    GROUP BY YEAR(loan_date)
),
yearly_growth AS (
    SELECT
        loan_year,
        total_loans,
        total_loan_amount,

        LAG(total_loan_amount) OVER (
            ORDER BY loan_year
        ) AS previous_year_amount

    FROM yearly_loans
)
SELECT
    loan_year,
    total_loans,
    total_loan_amount,
    previous_year_amount,

    total_loan_amount - previous_year_amount
        AS amount_growth,

    ROUND(
        (total_loan_amount - previous_year_amount)
        * 100.0 / NULLIF(previous_year_amount, 0),
        2
    ) AS growth_percentage

FROM yearly_growth
ORDER BY loan_year;







-- Top 10 Districts by Loan Amount — RANK() --

USE bank_db;

WITH district_loans AS (
    SELECT
        district_name,
        COUNT(DISTINCT loan_id) AS total_loans,
        SUM(amount) AS total_loan_amount
    FROM vw_loan_master
    WHERE district_name IS NOT NULL
    GROUP BY district_name
),
district_ranking AS (
    SELECT
        district_name,
        total_loans,
        total_loan_amount,

        RANK() OVER (
            ORDER BY total_loan_amount DESC
        ) AS district_rank

    FROM district_loans
)
SELECT
    district_rank,
    district_name,
    total_loans,
    total_loan_amount
FROM district_ranking
WHERE district_rank <= 10
ORDER BY district_rank;


USE bank_db;

SELECT COUNT(*) AS total_rows
FROM loan_master_clean;


SELECT *
FROM loan_master_clean
LIMIT 5;