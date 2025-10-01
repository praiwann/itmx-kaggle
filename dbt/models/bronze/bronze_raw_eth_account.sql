{{
    config(materialized='table')
}}

SELECT
    ea.account_id,
    ea.is_phishing,
    ea.data_ts::DATE as data_dt

FROM {{ source('staging_data', 'mst_eth_account') }} ea
