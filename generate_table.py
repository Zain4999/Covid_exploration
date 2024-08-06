import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy import text


def infer_sql_type(dtype):
    if pd.api.types.is_integer_dtype(dtype):
        return 'INT'
    elif pd.api.types.is_float_dtype(dtype):
        return 'FLOAT'
    elif pd.api.types.is_bool_dtype(dtype):
        return 'BOOLEAN'
    elif pd.api.types.is_datetime64_any_dtype(dtype):
        return 'TIMESTAMP'
    else:
        return 'TEXT'

def generate_sql_create_table(df, table_name):
    # Start building the CREATE TABLE statement
    sql_create_table = f"CREATE TABLE {table_name} (\n"

    # Add column definitions
    for column in df.columns:
        sql_type = infer_sql_type(df[column].dtype)
        sql_create_table += f"    {column} {sql_type},\n"

    # Remove the last comma and close the statement
    sql_create_table = sql_create_table.rstrip(',\n') + "\n);"

    return sql_create_table

def import_excel_to_postgres(excel_file_path, table_name, db_uri):
    # Read the Excel file
    df = pd.read_excel(excel_file_path)

    # Generate the CREATE TABLE statement
    create_table_sql = generate_sql_create_table(df, table_name)
    print(create_table_sql)

    # Create a connection to the PostgreSQL database
    engine = create_engine(db_uri)
    with engine.connect() as connection:
        # Create the table
        connection.execute(text(create_table_sql))

        # Import the data into the table
        df.to_sql(table_name, con=engine, if_exists='append', index=False)
        print(f"Data imported successfully into {table_name}")

excel_file_path = '/Users/zainsiddiqi/Data Analyst upskilling/CovidDeaths.xlsx'
table_name = 'CovidDeaths'
db_uri = 'postgresql://postgres:hydrogen1@localhost:5432/Covid'

import_excel_to_postgres(excel_file_path, table_name, db_uri)
