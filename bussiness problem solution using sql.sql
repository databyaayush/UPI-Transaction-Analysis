-- SOLVING THE BUSSINESS PROBLEMS USING SQL --

-- Q1. How reliable is our payment system? What share of all transactions fail, and how much money is stuck in failed payments? --
SELECT
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS failure_rate_percent,
    SUM(CASE WHEN status = 'FAILED' THEN amount ELSE 0 END) AS money_stuck_in_failed_payments
FROM transactions;

-- Q2. Which bank causes the most failures? Do some sender banks (SBI, ICICI, YBL, Axis, HDFC) fail more often than others? --
SELECT
    SUBSTR(sender_upi_id, INSTR(sender_upi_id, '@') + 1) AS sender_bank,
    COUNT(*) AS total_txns,
    SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) AS failed_txns,
    ROUND(100.0 * SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) / COUNT(*), 2) AS failure_rate_pct
FROM transactions
GROUP BY sender_bank
ORDER BY failure_rate_pct DESC;

-- Q3. When do people pay the most? Which hours of the day and which days of the week see the highest transaction volume? --
SELECT
    HOUR(timestamp) AS hour_of_day,
    COUNT(*) AS total_txns
FROM transactions
GROUP BY hour_of_day
ORDER BY total_txns DESC;

SELECT
    DAYNAME(`timestamp`) AS day_of_week,
    COUNT(*) AS total_txns,
    ROUND(
        SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END),
        2
    ) AS success_amount
FROM transactions
GROUP BY DAYNAME(`timestamp`)
ORDER BY total_txns DESC;

-- Q4. When do payments fail the most? Are failures higher at certain hours, such as late night or peak time? --
SELECT
    HOUR(timestamp) AS hour_of_day, -- I did the firstly you nedd to divide the time and hour in table -- 
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS failure_rate_percent
FROM transactions
GROUP BY hour_of_day
ORDER BY failure_rate_percent DESC;

-- Q5. Does the amount affect failure? Do high-value payments (above ₹7,500, say) fail more often than small ones? --
SELECT
    CASE
        WHEN amount <  2500 THEN '1. 0 - 2,500'
        WHEN amount <  5000 THEN '2. 2,500 - 5,000'
        WHEN amount <  7500 THEN '3. 5,000 - 7,500'
        ELSE                         '4. 7,500+'
    END                                                         AS amount_bucket,
    COUNT(*)                                                    AS total_txns,
    SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END)          AS failed_txns,
    ROUND(100.0 * SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) / COUNT(*), 2) AS failure_rate_pct
FROM transactions
GROUP BY amount_bucket
ORDER BY amount_bucket;

-- Q6. How much money actually moved? What is the total successful amount, the average ticket size and the largest single payment? --
SELECT
    COUNT(*) AS successful_txns,
    ROUND(SUM(amount), 2) AS total_amount_inr,
    ROUND(AVG(amount), 2) AS avg_ticket_size_inr,
    ROUND(MIN(amount), 2) AS smallest_payment_inr,
    ROUND(MAX(amount), 2) AS largest_payment_inr
FROM transactions
WHERE status = 'SUCCESS';

-- Q7. Which banks do money flow between? Which sender bank to receiver bank pair has the most transactions and the highest value? --
SELECT
    SUBSTRING_INDEX(sender_upi_id, '@', -1) AS sender_bank,
    SUBSTRING_INDEX(reciver_upi_id, '@', -1) AS receiver_bank,
    COUNT(*) AS total_txns,
    ROUND(
        SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END),
        2
    ) AS success_amount_inr,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS success_rate_pct
FROM transactions
GROUP BY
    sender_bank,
    receiver_bank
ORDER BY total_txns DESC, success_amount_inr DESC
LIMIT 10;

-- Q8. Who are the repeat users? Which senders transact more than once, and how much have they sent in total? --
SELECT
    sender_name,
    COUNT(*) AS txn_count,
    ROUND(SUM(amount), 2) AS total_sent_inr
FROM transactions
GROUP BY sender_name
HAVING COUNT(*) > 1
ORDER BY txn_count DESC, total_sent_inr DESC; 

-- Q9. Is business growing or flat? How do daily transactions and amounts trend across the month, and which day had the biggest spike or drop? --
WITH daily AS(SELECT
        DATE(timestamp) AS txn_date,
        COUNT(*) AS total_txns,
        ROUND(SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END), 2) AS success_amount_inr
    FROM transactions
    GROUP BY DATE(timestamp)
) 
SELECT
    txn_date,
    total_txns,
    success_amount_inr,
    total_txns - LAG(total_txns) OVER (ORDER BY txn_date)       AS txn_change_vs_prev_day,
    ROUND(success_amount_inr - LAG(success_amount_inr) OVER (ORDER BY txn_date), 2) AS amount_change_vs_prev_day
FROM daily
ORDER BY txn_date;

-- Q10. Are there any suspicious patterns? Are there duplicate transaction IDs, self-payments or unusually large amounts that need a closer look? --
-- 10a. Duplicate transaction IDs --
SELECT transaction_id, COUNT(*) AS cnt
FROM transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1; -- if output is null "EVERYTHING IS GOOD" 
 
-- 10b. Self-payments (same sender and receiver) --
SELECT *
FROM transactions
WHERE sender_upi_id = reciver_upi_id
   OR sender_name   = reciver_name; -- if it null "EVERYTHING SAFE" 
 
-- 10c. Unusually large amounts (above mean + 2 standard deviations) --
WITH stats AS (
    SELECT
        AVG(amount) AS mean_amt,
        SQRT(AVG(amount * amount) - AVG(amount) * AVG(amount)) AS std_amt
    FROM transactions
)
SELECT t.*
FROM transactions t, stats s
WHERE t.amount > s.mean_amt + 2 * s.std_amt
ORDER BY t.amount DESC; -- IF OUTPUT IS NULL "eVERYTHING SAFE" 
-- IF ALL THREE OUTPUT IS NULL EVERYTHING IS FINE AND SAFE 