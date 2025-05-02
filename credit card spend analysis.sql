/*1. write a query to print top 5 cities with highest spends and their percentage
 contribution of total credit card spends */
WITH city_spend AS (
SELECT city_name,SUM(amount) AS total_spend
FROM credit_card_transactions
GROUP BY city_name),
top_5_city AS (
SELECT city_name,total_spend,
ROUND(total_spend*100.0/SUM(total_spend) OVER(),3) AS percentage,
DENSE_RANK() OVER(ORDER BY total_spend DESC) AS rnk
FROM city_spend)
SELECT city_name,total_spend,percentage AS percentage_contribution
FROM top_5_city
WHERE rnk<=5;

/* 2. write a query to print highest spend month and amount spent in that month for each card type */
SELECT * FROM credit_card_transactions;
WITH monthly_spending AS (
SELECT *,MONTH(date) AS spend_month,
SUM(amount) OVER(PARTITION BY MONTH(date)) AS monthly_spend
FROM credit_card_transactions),
top_spending_cards AS (
SELECT *,
DENSE_RANK() OVER(ORDER BY monthly_spend DESC) AS rnk 
FROM monthly_spending)
SELECT card_type,SUM(amount) AS amount_spend
FROM top_spending_cards
WHERE rnk=1
GROUP BY card_type
ORDER BY amount_spend DESC;

/*3.write a query to print the transaction details(all columns from the table) for each card type 
when it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type) */
SELECT * FROM credit_card_transactions;
WITH card_limit AS (
SELECT *,
SUM(amount) OVER(PARTITION BY card_type ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sum,
1000000 AS spend_limit
FROM credit_card_transactions),
first_spend_date AS (
SELECT *,
DENSE_RANK() OVER(PARTITION BY card_type ORDER BY date) AS rnk
FROM card_limit
WHERE running_sum>=spend_limit)
SELECT card_type,MIN(date) AS first_limit_reach_date
FROM first_spend_date
WHERE rnk=1
GROUP BY card_type;

/*4. write a query to find city which had lowest percentage spend for gold card type*/
WITH city_gold_card AS (
SELECT city_name,SUM(amount) AS amount
FROM credit_card_transactions
WHERE Card_Type='Gold'
GROUP BY city_name),
least_gold_spend_city AS (
SELECT city_name,amount*100.0/SUM(amount) OVER() AS spend_percentage,
DENSE_RANK() OVER(ORDER BY amount) AS rnk
FROM city_gold_card)
SELECT city_name,spend_percentage
FROM least_gold_spend_city
WHERE rnk=1;

/*5.write a query to print 3 columns:city,highest_expense_type,lowest_expense_type(example format:Delhi,bills,Fuel)*/
WITH city_expenses AS (
SELECT city_name,Exp_Type,SUM(amount) AS total_amount
FROM credit_card_transactions
GROUP BY city_name,Exp_Type),
city_expense_type AS (
SELECT city_name,Exp_Type,total_amount,
RANK() OVER(PARTITION BY city_name ORDER BY total_amount DESC) AS rnk1,
RANK() OVER(PARTITION BY city_name ORDER BY total_amount ASC) AS rnk2
FROM city_expenses)
SELECT city_name,
GROUP_CONCAT(DISTINCT(CASE WHEN rnk1=1 THEN Exp_Type ELSE NULL END)) AS highest_expense_type,
GROUP_CONCAT(DISTINCT(CASE WHEN rnk2=1 THEN Exp_Type ELSE NULL END)) AS lowest_expense_type
FROM city_expense_type
GROUP BY city_name;

/*6. write a query to find percentage contribution of spends by females for each expense type*/
SELECT * FROM credit_card_transactions;
WITH gender_spend AS (
SELECT Exp_Type,
SUM(CASE WHEN Gender='M' THEN Amount ELSE 0 END) AS male_spend,
SUM(CASE WHEN Gender='F' THEN Amount ELSE 0 END) AS female_spend,
SUM(Amount) AS total_spend
FROM credit_card_transactions
GROUP BY Exp_Type)
SELECT Exp_Type,ROUND(female_spend*100.0/total_spend,3) AS female_spend_percentage
FROM gender_spend
ORDER BY female_spend_percentage DESC;

/*7. which card and expense type combination saw highest month over month growth in Jan-2014*/
SELECT * FROM credit_card_transactions;
WITH spends AS (
SELECT DATE_FORMAT(date,'%Y-%m') AS spend_month,card_type,exp_type,SUM(amount) AS total_amount
FROM credit_card_transactions
GROUP BY 1,2,3),
mom_spend AS (
SELECT *,LAG(total_amount,1) OVER(PARTITION BY card_type,exp_type ORDER BY spend_month) AS prev_month_amount
FROM spends),
top_spend AS (
SELECT spend_month,card_type,exp_type,total_amount,prev_month_amount,
((total_amount/prev_month_amount)-1)*100.0 AS mom
FROM mom_spend),
top_card_exp AS (
SELECT *,
RANK() OVER(ORDER BY mom DESC) AS rnk 
FROM top_spend
WHERE spend_month='2014-01')
SELECT card_type,exp_type,mom
FROM top_card_exp
WHERE rnk=1;

/*8. during weekends which city has highest total spend to total no of transcations ratio*/
WITH city_ratio AS (
SELECT city_name,SUM(amount)/COUNT(*) AS spend_to_transaction_ratio,
RANK() OVER(ORDER BY SUM(amount)/COUNT(*) DESC) AS rnk
FROM credit_card_transactions
WHERE DAYNAME(date) IN ('Saturday','Sunday')
GROUP BY city_name)
SELECT city_name,spend_to_transaction_ratio
FROM city_ratio
WHERE rnk=1;

/* 9. which city took least number of days to reach its 500th transaction after 
the first transaction in that city*/
SELECT * FROM credit_card_transactions;
WITH transactions AS (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY city_name ORDER BY date) AS rnk
FROM credit_card_transactions),
date_diff AS (
SELECT city_name,
MAX(CASE WHEN rnk=1 THEN date ELSE NULL END) AS first_txn_date,
IFNULL(MAX(CASE WHEN rnk=501 THEN date ELSE NULL END),'9999-12-31') AS txn_date_501
FROM transactions
GROUP BY city_name),
first_city AS (
SELECT city_name,
TIMESTAMPDIFF(DAY,first_txn_date,txn_date_501) AS days_took,
RANK() OVER(ORDER BY TIMESTAMPDIFF(DAY,first_txn_date,txn_date_501)) AS rnk
FROM date_diff
ORDER BY days_took)
SELECT city_name,days_took
FROM first_city
WHERE rnk=1;
