{{
    config(materialized='table')
}}

WITH txn AS (
    SELECT
        from_account AS account_id,
        transaction_dt
    FROM {{ ref('silver_transactions') }}
    UNION ALL
    SELECT
        to_account AS account_id,
        transaction_dt
    FROM {{ ref('silver_transactions') }}
)

SELECT
    ea.account_id,
    ea.is_phishing,

    MIN(t.transaction_dt) AS first_seen_dt,
    MAX(t.transaction_dt) AS last_seen_dt,

    ea.data_dt

FROM {{ ref('bronze_raw_eth_account') }} AS ea
LEFT JOIN txn AS t ON ea.account_id = t.account_id
GROUP BY ea.account_id, ea.is_phishing, ea.data_dt
