"""
CarLog Database Helper
======================
Provides database connection management and utility functions.
Implements context managers for safe connection handling.
"""

import sqlite3
import os
import logging
from contextlib import contextmanager
from typing import Optional, List, Dict, Any, Union

# Setup logging
logger = logging.getLogger(__name__)

# Database path
DB_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(DB_DIR, "carlog.db")


def get_connection() -> sqlite3.Connection:
    """
    Get a database connection with row factory enabled.
    Returns dict-like rows for easy JSON serialization.
    
    Note: Caller is responsible for closing the connection.
    For automatic handling, use the `connection()` context manager.
    """
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


@contextmanager
def connection():
    """
    Context manager for database connections.
    Automatically handles commit/rollback and closing.
    
    Usage:
        with connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM vehicles")
            results = cursor.fetchall()
    """
    conn = None
    try:
        conn = get_connection()
        yield conn
        conn.commit()
    except Exception as e:
        if conn:
            conn.rollback()
        logger.error(f"Database error: {e}")
        raise
    finally:
        if conn:
            conn.close()


@contextmanager
def transaction():
    """
    Context manager for explicit transactions.
    Use for operations that need atomic commits.
    
    Usage:
        with transaction() as conn:
            conn.execute("INSERT INTO ...")
            conn.execute("UPDATE ...")
            # Auto-commits on success, rolls back on error
    """
    conn = None
    try:
        conn = get_connection()
        conn.execute("BEGIN TRANSACTION")
        yield conn
        conn.commit()
    except Exception as e:
        if conn:
            conn.rollback()
        logger.error(f"Transaction error: {e}")
        raise
    finally:
        if conn:
            conn.close()


def row_to_dict(row: sqlite3.Row) -> Dict[str, Any]:
    """Convert a sqlite3.Row to a dictionary."""
    if row is None:
        return None
    return dict(row)


def rows_to_list(rows: List[sqlite3.Row]) -> List[Dict[str, Any]]:
    """Convert a list of sqlite3.Row objects to a list of dictionaries."""
    return [dict(row) for row in rows]


def execute_query(
    query: str, 
    params: tuple = (), 
    fetch_one: bool = False,
    fetch_all: bool = True
) -> Union[Dict[str, Any], List[Dict[str, Any]], int, None]:
    """
    Execute a query and return results.
    
    Args:
        query: SQL query string
        params: Query parameters
        fetch_one: If True, return single row
        fetch_all: If True, return all rows (default)
        
    Returns:
        - For SELECT with fetch_one: dict or None
        - For SELECT with fetch_all: list of dicts
        - For INSERT/UPDATE/DELETE: affected row count
    """
    with connection() as conn:
        cursor = conn.cursor()
        cursor.execute(query, params)
        
        # Check if it's a SELECT query
        if query.strip().upper().startswith("SELECT"):
            if fetch_one:
                row = cursor.fetchone()
                return row_to_dict(row) if row else None
            else:
                return rows_to_list(cursor.fetchall())
        else:
            # For INSERT, UPDATE, DELETE
            return cursor.rowcount


def execute_insert(
    table: str,
    data: Dict[str, Any],
    return_id: bool = True
) -> Union[int, bool]:
    """
    Insert a row into a table.
    
    Args:
        table: Table name
        data: Dictionary of column -> value
        return_id: If True, return the last inserted row ID
        
    Returns:
        Last inserted row ID if return_id=True, else True on success
    """
    columns = ", ".join(data.keys())
    placeholders = ", ".join(["?" for _ in data])
    query = f"INSERT INTO {table} ({columns}) VALUES ({placeholders})"
    
    with connection() as conn:
        cursor = conn.cursor()
        cursor.execute(query, tuple(data.values()))
        return cursor.lastrowid if return_id else True


def execute_update(
    table: str,
    data: Dict[str, Any],
    where: str,
    where_params: tuple = ()
) -> int:
    """
    Update rows in a table.
    
    Args:
        table: Table name
        data: Dictionary of column -> value to update
        where: WHERE clause (without 'WHERE' keyword)
        where_params: Parameters for WHERE clause
        
    Returns:
        Number of affected rows
    """
    set_clause = ", ".join([f"{k} = ?" for k in data.keys()])
    query = f"UPDATE {table} SET {set_clause}, updated_at = datetime('now') WHERE {where}"
    params = tuple(data.values()) + where_params
    
    with connection() as conn:
        cursor = conn.cursor()
        cursor.execute(query, params)
        return cursor.rowcount


def execute_delete(
    table: str,
    where: str,
    where_params: tuple = ()
) -> int:
    """
    Delete rows from a table.
    
    Args:
        table: Table name
        where: WHERE clause (without 'WHERE' keyword)
        where_params: Parameters for WHERE clause
        
    Returns:
        Number of deleted rows
    """
    query = f"DELETE FROM {table} WHERE {where}"
    
    with connection() as conn:
        cursor = conn.cursor()
        cursor.execute(query, where_params)
        return cursor.rowcount


def table_exists(table_name: str) -> bool:
    """Check if a table exists in the database."""
    query = "SELECT name FROM sqlite_master WHERE type='table' AND name=?"
    result = execute_query(query, (table_name,), fetch_one=True)
    return result is not None


def get_table_columns(table_name: str) -> List[str]:
    """Get list of column names for a table."""
    with connection() as conn:
        cursor = conn.cursor()
        cursor.execute(f"PRAGMA table_info({table_name})")
        return [row[1] for row in cursor.fetchall()]


def count_rows(table: str, where: str = None, params: tuple = ()) -> int:
    """Count rows in a table, optionally with a WHERE clause."""
    query = f"SELECT COUNT(*) as count FROM {table}"
    if where:
        query += f" WHERE {where}"
    result = execute_query(query, params, fetch_one=True)
    return result['count'] if result else 0


# Database initialization check
def ensure_initialized():
    """
    Ensure the database is initialized.
    Call this on app startup.
    """
    if not os.path.exists(DB_PATH) or not table_exists('vehicles'):
        logger.warning("Database not initialized. Running initialization...")
        try:
            from db.init_db import init_database
        except ImportError:
            from .init_db import init_database
        init_database(seed_data=True)
        logger.info("Database initialized successfully")
    return True
