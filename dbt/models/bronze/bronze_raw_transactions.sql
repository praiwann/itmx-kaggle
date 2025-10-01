{{
    config(materialized='table')
}}

SELECT
    t.from_account,
    t.to_account,
    t.amount,
    t.transaction_ts,
    t.data_ts::DATE as data_dt
FROM {{ source('staging_data', 'eth_transaction') }} AS t
