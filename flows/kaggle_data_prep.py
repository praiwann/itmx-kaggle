import duckdb
import pandas as pd
import numpy as np
import pickle
import networkx as nx
from datetime import datetime
from prefect import flow, task
from prefect.task_runners import SequentialTaskRunner
from pathlib import Path
import sys
import os

# Add parent directory to path to import config
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from config import DUCKDB_PATH, KAGGLE_DATA_PATH


def load_pickle(fname):
    with open(fname, "rb") as f:
        return pickle.load(f)


@task
def create_staging_schema():
    conn = duckdb.connect(DUCKDB_PATH)
    conn.execute("CREATE SCHEMA IF NOT EXISTS staging")
    conn.close()

    print("Successfully create staging schema.")
    return None


@task
def load_ethereum() -> nx.classes.MultiDiGraph:
    pkl_file = Path(KAGGLE_DATA_PATH) / "MulDiGraph.pkl"
    G = load_pickle(str(pkl_file))
    print("Successfully load MulDiGraph")
    return G


@task
def save_ethereum_account_into_wh(G: nx.classes.MultiDiGraph) -> None:
    now = datetime.now()

    conn = duckdb.connect(DUCKDB_PATH)

    data = []
    for _, nd in enumerate(G.nodes):
        data.append((nd, True if G.nodes[nd]["isp"] == 1 else False, now))

    schema = {"account_id": str, "is_phishing": bool, "data_ts": "datetime64[ns]"}

    df = pd.DataFrame(data, columns=schema.keys()).astype(schema)
    conn.execute("CREATE OR REPLACE TABLE staging.mst_eth_account as SELECT * FROM df")

    result = conn.execute("SELECT COUNT(*) FROM staging.mst_eth_account").fetchone()

    print(f"Created staging.mst_eth_account table with {result[0]} records")

    return None


@task
def save_transaction_into_wh(G: nx.classes.MultiDiGraph) -> None:
    now = datetime.now()

    conn = duckdb.connect(DUCKDB_PATH)

    data = []
    for _, edge in enumerate(nx.edges(G)):
        # gets the nodes on both sides of the edge.
        (u, v) = edge
        # gets the first edge from node u to node v.
        eg = G[u][v][0]
        # gets the properties of the directed edge: the amount and timestamp of the transaction.
        amo, tim = eg["amount"], eg["timestamp"]

        data.append((u, v, amo, tim, now))

    schema = {
        "from_account": str,
        "to_account": str,
        "amount": np.double,
        "transaction_ts": np.double,
        "data_ts": "datetime64[ns]",
    }

    df = pd.DataFrame(data, columns=schema.keys()).astype(schema)
    conn.execute("CREATE OR REPLACE TABLE staging.eth_transaction as SELECT * FROM df")

    result = conn.execute("SELECT COUNT(*) FROM staging.eth_transaction").fetchone()

    print(f"Created staging.eth_transaction table with {result[0]} records")

    return None


@flow(name="kaggle_data_prep", task_runner=SequentialTaskRunner())
def etl_pipeline():
    print("Starting ETL Pipeline...")

    create_staging_schema()

    graph = load_ethereum()

    save_ethereum_account_into_wh(graph)

    save_transaction_into_wh(graph)

    print("Pipeline completed successfully!")

    return None


if __name__ == "__main__":
    etl_pipeline()
