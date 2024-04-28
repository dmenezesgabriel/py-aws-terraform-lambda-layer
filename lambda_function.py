import logging

import duckdb


def lambda_handler(context, event):
    return {"duckdb": duckdb.sql("SELECT 42").fetchall()}
