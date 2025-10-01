{{
    config(materialized='table')
}}

SELECT
    t.from_account,
    t.to_account,
    t.amount,
    TO_TIMESTAMP(t.transaction_ts) AS transaction_ts,
    TO_TIMESTAMP(t.transaction_ts)::DATE AS transaction_dt,
    t.data_dt
FROM {{ ref('bronze_raw_transactions') }} AS t
