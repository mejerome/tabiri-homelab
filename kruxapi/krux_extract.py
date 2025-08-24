import os
import json
from datetime import datetime
import os
import logging
import requests
import psycopg2
from psycopg2.extras import execute_values
from db_schema import create_all_tables
from dotenv import load_dotenv # type: ignore
# import .env before loading environment variables
load_dotenv()

# --- Krux API Configuration ---
API_TOKEN = os.getenv("KRUX_API_TOKEN")
COMPANY_ID = os.getenv("KRUX_COMPANY_ID", "1513")
BASE_URL = os.getenv("KRUX_BASE_URL", "https://metrixapi.kruxanalytics.com/api/v2/Export/GetData/")

# --- PostgreSQL Configuration ---
DB_NAME = os.getenv("KRUX_DB_NAME", "krux_data")
DB_USER = os.getenv("KRUX_DB_USER", "myuser")
DB_PASSWORD = os.getenv("KRUX_DB_PASSWORD", "mysecretpassword")
DB_HOST = os.getenv("KRUX_DB_HOST", "localhost")
DB_PORT = os.getenv("KRUX_DB_PORT", "5432")


# --- Logging ---
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)


def get_db_connection():
    try:
        conn = psycopg2.connect(dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD, host=DB_HOST, port=DB_PORT)
        logger.info("Connected to PostgreSQL database")
        return conn
    except psycopg2.OperationalError as e:
        logger.error("Error connecting to the database: %s", e)
        return None


def _get_existing_uids_with_export(conn, table: str, uids: list):
    if not uids:
        return {}
    with conn.cursor() as cur:
        try:
            cur.execute(f"SELECT UID, ExportDateTime FROM {table} WHERE UID = ANY(%s)", (uids,))
            rows = cur.fetchall()
            return {row[0]: row[1] for row in rows}
        except Exception:
            try:
                conn.rollback()
            except Exception:
                pass
            logger.exception("Error checking existing UIDs for %s", table)
            return {}


def fetch_krux_data(start_date: str, query_name: str):
    if not API_TOKEN:
        logger.error("KRUX_API_TOKEN is not set in environment variables.")
        return []

    headers = {
        "Authorization": f"Bearer {API_TOKEN}",
        "User-Agent": "TabiriETL/1.0",
        "Accept": "*/*",
        "Cache-Control": "no-cache",
    }

    params = {"companyId": COMPANY_ID, "queryName": query_name, "exportDateTime": start_date}
    logger.info("Fetching data from Krux API for query '%s' and start date: %s", query_name, start_date)

    try:
        response = requests.get(BASE_URL, headers=headers, params=params, timeout=60)
        response.raise_for_status()
        records = response.json().get("Table", [])
        logger.info("Fetched %d records from Krux API for query '%s'.", len(records), query_name)
        return records
    except requests.RequestException:
        logger.exception("Error fetching data from Krux API for %s", query_name)
        return []


def upsert_records(conn, table_name: str, columns: list, records: list):
    if not records:
        logger.debug("No records provided for table %s", table_name)
        return

    records = [r for r in records if r.get("UID")]
    if not records:
        logger.debug("No valid records with UID to insert for table %s", table_name)
        return

    uids = [r.get("UID") for r in records]
    existing = _get_existing_uids_with_export(conn, table_name, uids)

    filtered = []
    for r in records:
        uid = r.get("UID")
        existing_export = existing.get(uid)
        record_export = r.get("ExportDateTime")
        if existing_export is not None and record_export is not None and str(existing_export) == str(record_export):
            continue
        filtered.append(r)

    if not filtered:
        logger.info("No new or changed records to insert for %s", table_name)
        return

    data_tuples = [tuple(record.get(column) for column in columns) for record in filtered]

    cols_sql = ", ".join(columns)
    update_sql = ", ".join([f"{column} = EXCLUDED.{column}" for column in columns if column != "UID"])

    upsert_query = f"""
        INSERT INTO {table_name} ({cols_sql}) VALUES %s
        ON CONFLICT (UID) DO UPDATE SET
          {update_sql}
    """

    with conn.cursor() as cursor:
        try:
            execute_values(cursor, upsert_query, data_tuples)
            conn.commit()
            logger.info("Inserted/updated %d records into %s.", len(data_tuples), table_name)
        except Exception:
            logger.exception("Error inserting data into %s", table_name)
            try:
                conn.rollback()
            except Exception:
                pass


# Table-specific wrappers (define column order to match DB schema)
def insert_dsr_to_postgres(conn, records):
    columns = [
        "UID",
        "DailyReportID",
        "ContractorCompany",
        "ContracteeCompany",
        "Contract",
        "Project",
        "Drill",
        "ReportDate",
        "Status",
        "Supervisor",
        "Shift",
        "ValidatedBy",
        "ValidatedDate",
        "ApprovedBy",
        "ApprovedDate",
        "DeletedFlag",
        "ExportDateTime",
        "ContractID",
    ]
    upsert_records(conn, "daily_reports", columns, records)


def insert_dsr_activity_to_postgres(conn, records):
    columns = [
        "UID",
        "DailyReportID",
        "HoleID",
        "Hole",
        "Activity",
        "Type",
        "BitSize",
        "DistanceDrilledFrom",
        "DistanceDrilledTo",
        "Distance",
        "Depth",
        "Billable",
        "ActivityHours",
        "TotalManHours",
        "Penetration",
        "BillingType",
        "DistanceFromToUnitAbbr",
        "DistanceUnitAbbr",
        "DepthUnitAbbr",
        "TotalCharges",
        "CurrencyCode",
        "DeletedFlag",
        "ExportDateTime",
        "WorkSubCategoryID",
        "WorkSubCategoryTypeID",
        "DataDeleted",
        "ChargeFrom",
        "ChargeTo",
        "Comments",
        "BitSizeID",
    ]
    upsert_records(conn, "dsr_activity", columns, records)


def insert_dsr_activity_equipment_to_postgres(conn, records):
    columns = [
        "UID",
        "DailyReportID",
        "HoleID",
        "Hole",
        "Activity",
        "Equipment",
        "EquipmentHours",
        "EquipmentUnit",
        "BillingType",
        "TotalCharges",
        "CurrencyCode",
        "DeletedFlag",
        "ExportDateTime",
        "ContractorEquipmentID",
        "DataDeleted",
    ]
    upsert_records(conn, "dsr_activity_equipment", columns, records)


def insert_dsr_workers_labour_to_postgres(conn, records):
    columns = [
        "UID",
        "DailyReportID",
        "Name",
        "Role",
        "PayrollHours",
        "BillingType",
        "TotalCharges",
        "CurrencyCode",
        "DeletedFlag",
        "ExportDateTime",
        "DataDeleted",
    ]
    upsert_records(conn, "dsr_workers_labour", columns, records)


def insert_dsr_activity_labour_to_postgres(conn, records):
    columns = [
        "UID",
        "DailyReportID",
        "Activity",
        "Name",
        "Role",
        "ManHours",
        "BillingType",
        "TotalCharges",
        "CurrencyCode",
        "DeletedFlag",
        "ExportDateTime",
        "DataDeleted",
    ]
    upsert_records(conn, "dsr_activity_labour", columns, records)

def insert_holes_to_postgres(conn, records):
    columns = [
        "UID", "HoleID", "HoleName", "HoleStatus", "CompleteDateTime", "HoleType",
        "ContractorCompany", "ContracteeCompany", "Contract", "Project", "Plan",
        "FirstActivityDate", "LastActivityDate", "MaxDepth", "PlannedDepth",
        "DepthUnit", "TotalDistanceDrilled", "TotalActivityHours", "TotalDrillingHours",
        "Penetration", "Easting", "Northing", "UTMZone", "MineGridEasting",
        "MineGridNorthing", "Elevation", "ElevationUnit", "PlannedAzimuth",
        "PlannedDip", "DeletedFlag", "ExportDateTime", "FirstDrillingActivityDate",
        "ParentHoleID"
    ]
    upsert_records(conn, "holes", columns, records)

if __name__ == "__main__":
    # use full timestamp format expected by the API
    start_of_july = "2025-07-01"

    conn = get_db_connection()
    if conn:
        # create all tables first
        create_all_tables(conn)

        # DSR extraction
        dsr_records = fetch_krux_data(start_date=start_of_july, query_name="DSR")
        if dsr_records:
            insert_dsr_to_postgres(conn, dsr_records)

        # DSRActivity extraction
        dsr_activity_records = fetch_krux_data(start_date=start_of_july, query_name="DSRActivity")
        if dsr_activity_records:
            insert_dsr_activity_to_postgres(conn, dsr_activity_records)

        # DSRActivityEquipment extraction
        dsr_activity_equipment_records = fetch_krux_data(start_date=start_of_july, query_name="DSRActivityEquipment")
        if dsr_activity_equipment_records:
            insert_dsr_activity_equipment_to_postgres(conn, dsr_activity_equipment_records)

        # DSRWorkersLabour extraction
        dsr_workers_labour_records = fetch_krux_data(start_date=start_of_july, query_name="DSRWorkersLabour")
        if dsr_workers_labour_records:
            insert_dsr_workers_labour_to_postgres(conn, dsr_workers_labour_records)

        # DSRActivityLabour extraction
        dsr_activity_labour_records = fetch_krux_data(start_date=start_of_july, query_name="DSRActivityLabour")
        if dsr_activity_labour_records:
            insert_dsr_activity_labour_to_postgres(conn, dsr_activity_labour_records)

        # Holes extraction
        holes_records = fetch_krux_data(start_date=start_of_july, query_name="Holes")
        if holes_records:
            insert_holes_to_postgres(conn, holes_records)

        conn.close()

