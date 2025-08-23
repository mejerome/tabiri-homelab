import os
import json
from datetime import datetime
import requests
import psycopg2
from psycopg2.extras import execute_values
from db_schema import create_reports_table, create_dsr_activity_table, create_dsr_activity_equipment_table, create_dsr_workers_labour_table    

 # --- Krux API Configuration ---
API_TOKEN = os.getenv("KRUX_API_TOKEN")
COMPANY_ID = "1513"
BASE_URL = "https://metrixapi.kruxanalytics.com/api/v2/Export/GetData/"
DSR_QUERY_NAME = "DSR"
DSRACTIVITY_QUERY_NAME = "DSRActivity"
DSRACTIVITYEQUIPMENT_QUERY_NAME = "DSRActivityEquipment"
DSRWORKERSLABOUR_QUERY_NAME = "DSRWorkersLabour"

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


def _get_existing_uids_with_export(conn, table: str, uids: list):
    """Return a dict of {UID: ExportDateTime} for rows that already exist in `table`.
    Used to skip inserting records that are identical by UID and ExportDateTime.
    """
    if not uids:
        return {}
    # Ensure we pass a list to psycopg2
    with conn.cursor() as cur:
        try:
            cur.execute(f"SELECT UID, ExportDateTime FROM {table} WHERE UID = ANY(%s)", (uids,))
            rows = cur.fetchall()
            return {row[0]: row[1] for row in rows}
        except Exception as e:
            try:
                conn.rollback()
            except Exception:
                pass
            print(f"Error checking existing UIDs for {table}: {e}")
            return {}
  

def fetch_krux_data(start_date: str, query_name: str):
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
        "queryName": query_name,
        "exportDateTime": start_date,
    }
    print(f"Fetching data from Krux API for query '{query_name}' and start date: {start_date}")

    try:
        response = requests.get(BASE_URL, headers=headers, params=params, timeout=60)
        response.raise_for_status()
        records = response.json().get("Table", [])
        print(f"Fetched {len(records)} records from Krux API for query '{query_name}'.")
        return records
    except requests.RequestException as e:
        print(f"Error fetching data from Krux API: {e}")
        return None

def insert_dsr_activity_to_postgres(conn, records):
    if not records:
        print("No DSRActivity records to insert into PostgreSQL.")
        return

    records = [r for r in records if r.get("UID")]
    if not records:
        print("No valid DSRActivity records with UID to insert.")
        return

    columns = [
        "UID", "DailyReportID", "HoleID", "Hole", "Activity", "Type", "BitSize",
        "DistanceDrilledFrom", "DistanceDrilledTo", "Distance", "Depth", "Billable",
        "ActivityHours", "TotalManHours", "Penetration", "BillingType", "DistanceFromToUnitAbbr",
        "DistanceUnitAbbr", "DepthUnitAbbr", "TotalCharges", "CurrencyCode", "DeletedFlag",
        "ExportDateTime", "WorkSubCategoryID", "WorkSubCategoryTypeID", "DataDeleted",
        "ChargeFrom", "ChargeTo", "Comments", "BitSizeID"
    ]

    # Avoid inserting records that already exist with identical ExportDateTime
    uids = [r.get("UID") for r in records if r.get("UID")]
    existing = _get_existing_uids_with_export(conn, 'dsr_activity', uids)

    filtered = []
    for r in records:
        uid = r.get("UID")
        if not uid:
            continue
        existing_export = existing.get(uid)
        record_export = r.get("ExportDateTime")
        # if both exist and are equal, skip to avoid duplicate insert/update
        if existing_export is not None and record_export is not None and str(existing_export) == str(record_export):
            continue
        filtered.append(r)

    if not filtered:
        print("No new or changed DSRActivity records to insert.")
        return

    data_tuples = [
        tuple(record.get(column) for column in columns)
        for record in filtered
    ]

    cols_sql = ', '.join(columns)
    update_sql = ', '.join([f"{column} = EXCLUDED.{column}" for column in columns if column != "UID"])

    upsert_query = f"""
        INSERT INTO dsr_activity ({cols_sql}) VALUES %s
        ON CONFLICT (UID) DO UPDATE SET
          {update_sql}
    """

    with conn.cursor() as cursor:
        try:
            execute_values(cursor, upsert_query, data_tuples)
            conn.commit()
            print(f"Inserted/updated {len(data_tuples)} DSRActivity records into PostgreSQL.")
        except Exception as e:
            print(f"Error inserting DSRActivity data into PostgreSQL: {e}")
            try:
                conn.rollback()
            except Exception:
                pass

def insert_dsr_to_postgres(conn, records):
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

   # Avoid inserting records that already exist with identical ExportDateTime
   uids = [r.get("UID") for r in records if r.get("UID")]
   existing = _get_existing_uids_with_export(conn, 'daily_reports', uids)

   filtered = []
   for r in records:
       uid = r.get("UID")
       if not uid:
           continue
       existing_export = existing.get(uid)
       record_export = r.get("ExportDateTime")
       if existing_export is not None and record_export is not None and str(existing_export) == str(record_export):
           continue
       filtered.append(r)

   if not filtered:
       print("No new or changed daily_reports records to insert.")
       return

   data_tuples = [
      tuple(record.get(column) for column in columns)
      for record in filtered
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
      except Exception as e:
          print(f"Error inserting data into PostgreSQL: {e}")
          try:
              conn.rollback()
          except Exception:
              pass

def insert_dsr_activity_equipment_to_postgres(conn, records):
    if not records:
        print("No DSRActivityEquipment records to insert into PostgreSQL.")
        return

    records = [r for r in records if r.get("UID")]
    if not records:
        print("No valid DSRActivityEquipment records with UID to insert.")
        return

    columns = [
    "UID", "DailyReportID", "HoleID", "Hole", "Activity", "Equipment",
    "EquipmentHours", "EquipmentUnit", "BillingType", "TotalCharges", "CurrencyCode",
    "DeletedFlag", "ExportDateTime", "ContractorEquipmentID", "DataDeleted"
    ]

    # Avoid inserting records that already exist with identical ExportDateTime
    uids = [r.get("UID") for r in records if r.get("UID")]
    existing = _get_existing_uids_with_export(conn, 'dsr_activity_equipment', uids)

    filtered = []
    for r in records:
        uid = r.get("UID")
        if not uid:
            continue
        existing_export = existing.get(uid)
        record_export = r.get("ExportDateTime")
        if existing_export is not None and record_export is not None and str(existing_export) == str(record_export):
            continue
        filtered.append(r)

    if not filtered:
        print("No new or changed DSRActivityEquipment records to insert.")
        return

    data_tuples = [
        tuple(record.get(column) for column in columns)
        for record in filtered
    ]

    cols_sql = ', '.join(columns)
    update_sql = ', '.join([f"{column} = EXCLUDED.{column}" for column in columns if column != "UID"])

    upsert_query = f"""
        INSERT INTO dsr_activity_equipment ({cols_sql}) VALUES %s
        ON CONFLICT (UID) DO UPDATE SET
          {update_sql}
    """

    with conn.cursor() as cursor:
        try:
            execute_values(cursor, upsert_query, data_tuples)
            conn.commit()
            print(f"Inserted/updated {len(data_tuples)} DSRActivityEquipment records into PostgreSQL.")
        except Exception as e:
            print(f"Error inserting DSRActivityEquipment data into PostgreSQL: {e}")
            try:
                conn.rollback()
            except Exception:
                pass

def insert_dsr_workers_labour_to_postgres(conn, records):
    if not records:
        print("No DSRWorkersLabor records to insert into PostgreSQL.")
        return

    records = [r for r in records if r.get("UID")]
    if not records:
        print("No valid DSRWorkersLabour records with UID to insert.")
        return

    # DB schema columns (from db_schema.create_dsr_workers_labour_table)
    columns = [
        "UID", "DailyReportID", "Name", "Role", "PayrollHours",
        "BillingType", "TotalCharges", "CurrencyCode", "DeletedFlag",
        "ExportDateTime", "DataDeleted"
    ]

    # Avoid inserting records that already exist with identical ExportDateTime
    uids = [r.get("UID") for r in records if r.get("UID")]
    existing = _get_existing_uids_with_export(conn, 'dsr_workers_labour', uids)

    filtered = []
    for r in records:
        uid = r.get("UID")
        if not uid:
            continue
        existing_export = existing.get(uid)
        record_export = r.get("ExportDateTime")
        if existing_export is not None and record_export is not None and str(existing_export) == str(record_export):
            continue
        filtered.append(r)

    if not filtered:
        print("No new or changed DSRWorkersLabour records to insert.")
        return

    data_tuples = []
    for record in filtered:
        row = tuple(record.get(column) for column in columns)
        data_tuples.append(row)

    cols_sql = ', '.join(columns)
    update_sql = ', '.join([f"{column} = EXCLUDED.{column}" for column in columns if column != "UID"])

    upsert_query = f"""
        INSERT INTO dsr_workers_labour ({cols_sql}) VALUES %s
        ON CONFLICT (UID) DO UPDATE SET
          {update_sql}
    """

    with conn.cursor() as cursor:
        try:
            execute_values(cursor, upsert_query, data_tuples)
            conn.commit()
            print(f"Inserted/updated {len(data_tuples)} DSRWorkersLabour records into PostgreSQL.")
        except Exception as e:
            print(f"Error inserting DSRWorkersLabour data into PostgreSQL: {e}")
            try:
                conn.rollback()
            except Exception:
                pass

if __name__ == "__main__":
    # use full timestamp format expected by the API
    start_of_july = "2025-07-01"

    conn = get_db_connection()
    if conn:
        # DSR extraction
        dsr_records = fetch_krux_data(start_date=start_of_july, query_name=DSR_QUERY_NAME)
        create_reports_table(conn)
        if dsr_records:
            insert_dsr_to_postgres(conn, dsr_records)

        # DSRActivity extraction
        dsr_activity_records = fetch_krux_data(start_date=start_of_july, query_name=DSRACTIVITY_QUERY_NAME)
        create_dsr_activity_table(conn)
        if dsr_activity_records:
            insert_dsr_activity_to_postgres(conn, dsr_activity_records)

        # DSRActivityEquipment extraction
        dsr_activity_equipment_records = fetch_krux_data(start_date=start_of_july, query_name=DSRACTIVITYEQUIPMENT_QUERY_NAME)
        create_dsr_activity_equipment_table(conn)
        if dsr_activity_equipment_records:
            insert_dsr_activity_equipment_to_postgres(conn, dsr_activity_equipment_records)

        # DSRWorkersLabour extraction
        dsr_workers_labour_records = fetch_krux_data(start_date=start_of_july, query_name=DSRWORKERSLABOUR_QUERY_NAME)
        create_dsr_workers_labour_table(conn)
        if dsr_workers_labour_records:
            insert_dsr_workers_labour_to_postgres(conn, dsr_workers_labour_records)

        conn.close()

