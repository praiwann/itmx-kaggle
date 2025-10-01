{{
    config(materialized='table')
}}

SELECT
    t.from_account,
    t.to_account,
    t.amount,
    t.transaction_ts,
    t.transaction_dt,

    s.is_phishing AS sender_is_phishing,
    s.first_seen_dt AS sender_first_seen,

    r.is_phishing AS receiver_is_phishing,
    r.first_seen_dt AS receiver_first_seen,

    (s.is_phishing OR r.is_phishing) AS involves_phishing,

    t.data_dt
FROM {{ ref('silver_transactions') }} AS t
LEFT JOIN {{ ref('silver_account_masters') }} AS s ON t.from_account = s.account_id
LEFT JOIN {{ ref('silver_account_masters') }} AS r ON t.to_account = r.account_id
