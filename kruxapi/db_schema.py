import psycopg2

def create_reports_table(conn):
    """Creates the daily_reports table if it doesn't exist."""
    create_table_query = """
    CREATE TABLE IF NOT EXISTS daily_reports (
        UID VARCHAR(255) PRIMARY KEY,
        DailyReportID VARCHAR(255),
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

def create_dsr_activity_table(conn):
    """Creates the dsr_activity table if it doesn't exist."""
    create_table_query = """
    CREATE TABLE IF NOT EXISTS dsr_activity (
        UID VARCHAR(255) PRIMARY KEY,
        DailyReportID INTEGER,
        HoleID INTEGER,
        Hole VARCHAR(255),
        Activity VARCHAR(255),
        Type VARCHAR(255),
        BitSize VARCHAR(50),
        DistanceDrilledFrom FLOAT,
        DistanceDrilledTo FLOAT,
        Distance FLOAT,
        Depth FLOAT,
        Billable CHAR(1),
        ActivityHours FLOAT,
        TotalManHours FLOAT,
        Penetration FLOAT,
        BillingType VARCHAR(50),
        DistanceFromToUnitAbbr VARCHAR(50),
        DistanceUnitAbbr VARCHAR(50),
        DepthUnitAbbr VARCHAR(50),
        TotalCharges FLOAT,
        CurrencyCode VARCHAR(10),
        DeletedFlag CHAR(1),
        ExportDateTime TIMESTAMP,
        WorkSubCategoryID INTEGER,
        WorkSubCategoryTypeID INTEGER,
        DataDeleted CHAR(1),
        ChargeFrom FLOAT,
        ChargeTo FLOAT,
        Comments TEXT,
        BitSizeID INTEGER
    );
    """
    with conn.cursor() as cur:
        cur.execute(create_table_query)
        conn.commit()
    print("Table 'dsr_activity' is ready.")

def create_dsr_activity_equipment_table(conn):
    """Creates the dsr_activity_equipment table if it doesn't exist."""
    create_table_query = """
    CREATE TABLE IF NOT EXISTS dsr_activity_equipment (
        UID VARCHAR(255) PRIMARY KEY,
        DailyReportID INTEGER,
        HoleID INTEGER,
        Hole VARCHAR(255),
        Activity VARCHAR(255),
        Equipment VARCHAR(255),
        EquipmentHours FLOAT,
        EquipmentUnit VARCHAR(50),
        BillingType VARCHAR(50),
        TotalCharges FLOAT,
        CurrencyCode VARCHAR(10),
        DeletedFlag CHAR(1),
        ExportDateTime TIMESTAMP,
        ContractorEquipmentID INTEGER,
        DataDeleted CHAR(1)
    );
    """
    with conn.cursor() as cur:
        cur.execute(create_table_query)
        conn.commit()
    print("Table 'dsr_activity_equipment' is ready.")

def create_dsr_workers_labour_table(conn):
    """Creates the dsr_workers_labour table if it doesn't exist."""
    create_table_query = """
    CREATE TABLE IF NOT EXISTS dsr_workers_labour (
        UID VARCHAR(50) PRIMARY KEY,
        DailyReportID INTEGER,
        Name VARCHAR(255),
        Role VARCHAR(100),
        PayrollHours NUMERIC(10,3),
        BillingType VARCHAR(50),
        TotalCharges NUMERIC(12,2),
        CurrencyCode CHAR(3),
        DeletedFlag CHAR(1),
        ExportDateTime TIMESTAMP,
        DataDeleted CHAR(1)
    );
    """
    with conn.cursor() as cur:
        cur.execute(create_table_query)
        conn.commit()
    print("Table 'dsr_workers_labor' is ready.")