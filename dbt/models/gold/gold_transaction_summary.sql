{{
    config(materialized='table')
}}

SELECT
    t.from_account AS from_id,
    t.to_account AS to_id,
    t.amount AS txn_amount,
    t.transaction_ts AS txn_ts,
    t.transaction_dt AS txn_date,

    -- Sender
    COUNT(*) OVER (
        PARTITION BY t.from_account
        ORDER BY t.transaction_ts
        RANGE BETWEEN INTERVAL 1 HOUR PRECEDING AND CURRENT ROW
    ) AS sender_txn_last_1hr,
    LAG(t.amount) OVER (
        PARTITION BY t.from_account
        ORDER BY t.transaction_ts
    ) AS sender_prev_amount,

    -- Receiver
    COUNT(*) OVER (
        PARTITION BY t.to_account
        ORDER BY t.transaction_ts
        RANGE BETWEEN INTERVAL 1 HOUR PRECEDING AND CURRENT ROW
    ) AS receiver_txn_last_1hr,
    LAG(t.amount) OVER (
        PARTITION BY t.to_account
        ORDER BY t.transaction_ts
    ) AS receiver_prev_amount

FROM {{ ref('silver_transactions') }} AS t
ORDER BY t.transaction_ts
