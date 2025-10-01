{{
    config(
        materialized='incremental',
        incremental_strategy= 'merge',
        unique_key=['txn_date', 'hour_ts'],
        partition_by=['txn_date']
    )
}}

SELECT
    t.transaction_dt AS txn_date,
    DATE_TRUNC('hour', t.transaction_ts) AS hour_ts,

    COUNT(*) AS txn_count,
    COUNT(DISTINCT t.from_account) AS unique_senders,
    COUNT(DISTINCT t.to_account) AS unique_receivers,
    COUNT(DISTINCT t.from_account) + COUNT(DISTINCT t.to_account) AS active_accounts,

    SUM(t.amount) AS total_volume,
    AVG(t.amount) AS avg_txn_amount,
    STDDEV(t.amount) AS stddev_txn_amount,
    QUANTILE_CONT(t.amount, 0.5) AS median_txn_amount,
    QUANTILE_CONT(t.amount, 0.95) AS p95_txn_amount,
    MAX(t.amount) AS max_txn_amount,

    SUM(CASE WHEN t.sender_is_phishing THEN 1 ELSE 0 END) AS phishing_sender_txn_count,
    SUM(CASE WHEN t.receiver_is_phishing THEN 1 ELSE 0 END) AS phishing_receiver_txn_count,
    SUM(CASE WHEN t.sender_is_phishing THEN t.amount ELSE 0 END) AS phishing_sender_volume,
    SUM(CASE WHEN t.receiver_is_phishing THEN t.amount ELSE 0 END) AS phishing_receiver_volume

FROM {{ ref('silver_transaction_enriched') }} AS t
{% if is_incremental() %}

    WHERE t.transaction_dt >= CURRENT_DATE - INTERVAL '7 days'

{% endif %}
GROUP BY t.transaction_dt, DATE_TRUNC('hour', t.transaction_ts)
