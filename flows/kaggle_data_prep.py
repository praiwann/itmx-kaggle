import duckdb
import pandas as pd
import numpy as np
import pickle
import networkx as nx
from datetime import datetime
from prefect import flow, task
from prefect.task_runners import SequentialTaskRunner
from pathlib import Path
from config import DUCKDB_PATH, KAGGLE_DATA_PATH
from contextlib import contextmanager
import time
import os

@contextmanager
def get_duckdb_connection(read_only=False, retries=3):
    """Get DuckDB connection with retry logic and proper cleanup"""
    conn = None
    for attempt in range(retries):
        try:
            if read_only:
                conn = duckdb.connect(DUCKDB_PATH, read_only=True)
            else:
                conn = duckdb.connect(DUCKDB_PATH)
            yield conn
            break
        except duckdb.IOException as e:
            if "lock" in str(e).lower() and attempt < retries - 1:
                print(f"Lock conflict, retrying in 2 seconds... (attempt {attempt + 1}/{retries})")
                time.sleep(2)
            else:
                raise
        finally:
            if conn:
                try:
                    conn.close()
                except:
                    pass


def load_pickle(fname):
    with open(fname, "rb") as f:
        return pickle.load(f)


@task
def create_staging_schema():
    with get_duckdb_connection() as conn:
        conn.execute("CREATE SCHEMA IF NOT EXISTS staging")

    print("Successfully created staging schema.")
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

    with get_duckdb_connection() as conn:
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

    with get_duckdb_connection() as conn:
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
