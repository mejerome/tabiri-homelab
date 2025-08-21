import os
import json
from datetime import datetime
import requests
import psycopg2
from psycopg2.extras import execute_values

# --- Krux API Configuration ---
API_TOKEN = os.getenv("KRUX_API_TOKEN")
COMPANY_ID = "1513"
QUERY_NAME = "DSR"
BASE_URL = "https://metrixapi.kruxanalytics.com/api/v2/Export/GetData/"

# --- PostgreSQL Configuration ---
# Add these to your .env file
DB_NAME = "krux_data"
DB_USER = "myuser"
DB_PASSWORD = "mysecretpassword"
DB_HOST = "localhost"
DB_PORT = "5432"

def get_db_connection():
  try:
    conn = psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT
    )
    return conn
  except psycopg2.OperationalError as e:
    print(f"Error connecting to the database: {e}")
    return None
  
def create_reports_table(conn):
    """Creates the daily_reports table if it doesn't exist."""
    create_table_query = """
    CREATE TABLE IF NOT EXISTS daily_reports (
        UID VARCHAR(255) PRIMARY KEY,
        DailyReportID INTEGER,
        ContractorCompany VARCHAR(255),
        ContracteeCompany VARCHAR(255),
        Contract VARCHAR(255),
        Project VARCHAR(255),
        Drill VARCHAR(255),
        ReportDate TIMESTAMP,
        Status VARCHAR(50),
        Supervisor VARCHAR(255),
        Shift VARCHAR(50),
        ValidatedBy VARCHAR(255),
        ValidatedDate TIMESTAMP,
        ApprovedBy VARCHAR(255),
        ApprovedDate TIMESTAMP,
        DeletedFlag CHAR(1),
        ExportDateTime TIMESTAMP,
        ContractID INTEGER
    );
    """
    with conn.cursor() as cur:
        cur.execute(create_table_query)
        conn.commit()
    print("Table 'daily_reports' is ready.")  
  
def fetch_krux_data(start_date: str):
  if not API_TOKEN:
    print("Error: KRUX_API_TOKEN is not set in environment variables.")
    return None

  headers = {
      "Authorization": f"Bearer {API_TOKEN}",
      "User-Agent": "PostmanRuntime/7.32.0",
      "Accept": "*/*",
      "Cache-Control": "no-cache"
  }

  params = {
      "companyId": COMPANY_ID,
      "queryName": QUERY_NAME,
      "exportDateTime": start_date,
  }
  print(f"Fetching data from Krux API for start date: {start_date}")

  try:
      response = requests.get(BASE_URL, headers=headers, params=params, timeout=60)
      response.raise_for_status()
      records = response.json().get("Table", [])
      print(f"Fetched {len(records)} records from Krux API.")
      return records
  except requests.RequestException as e:
      print(f"Error fetching data from Krux API: {e}")
      return None
def insert_data_to_postgres(conn, records):
   if not records:
       print("No records to insert into PostgreSQL.")
       return

   # filter out rows that don't have a UID (some rows in your sample only contain ContractID)
   records = [r for r in records if r.get("UID")]
   if not records:
       print("No valid records with UID to insert.")
       return

   # Use a fixed canonical column order that matches the DB schema
   columns = [
       "UID","DailyReportID","ContractorCompany","ContracteeCompany","Contract","Project",
       "Drill","ReportDate","Status","Supervisor","Shift","ValidatedBy","ValidatedDate",
       "ApprovedBy","ApprovedDate","DeletedFlag","ExportDateTime","ContractID"
   ]

   data_tuples = [
      tuple(record.get(column) for column in columns)
      for record in records
   ]

   cols_sql = ', '.join(columns)
   update_sql = ', '.join([f"{column} = EXCLUDED.{column}" for column in columns if column != "UID"])

   upsert_query = f"""
    INSERT INTO daily_reports ({cols_sql}) VALUES %s
    ON CONFLICT (UID) DO UPDATE SET
      {update_sql}
   """

   with conn.cursor() as cursor:
      try:
          execute_values(cursor, upsert_query, data_tuples)
          conn.commit()
          print(f"Inserted/updated {len(data_tuples)} records into PostgreSQL.")
      except psycopg2.Error as e:
          print(f"Error inserting data into PostgreSQL: {e}")
          conn.rollback()


if __name__ == "__main__":
    # use full timestamp format expected by the API
    start_of_july = "2025-07-01"

    records = fetch_krux_data(start_date=start_of_july)

    if records:
        conn = get_db_connection()
        if conn:
            create_reports_table(conn)
            insert_data_to_postgres(conn, records)
            conn.close()

