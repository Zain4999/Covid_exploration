# Introduction 
An exploration into Covid-19 data, with emphasis on UK Covid data compared to the rest of the world. I delve into Covid cases, deaths and vaccinations.
[Click here for the repository](https://github.com/Zain4999/Covid_exploration/blob/main/Covid%20Project.sql)

# Background
After the pandemic stopped the world in its tracks, I was interested to reflect on the impact it had globally, and how the UK statistics compared to other countries and regions. 

All data comes from [Our World In Data](https://ourworldindata.org/covid-deaths)

# Tools I used
I used several key tools to help me with this analysis:

- **SQL**: The backbone of my analysis, allowing me to query the database and discover crucial insights.
- **PostgreSQL/pgadmin4**: My preferred database management system (DBMS) and what I used to write and run queries
- **Python**: Imperative in helping me create tables in my DBMS and import the data into the DBMS.
- **Github**: For allowing me to share my project

# The Analysis 
Before starting this analysis I had to create my tables and import my data into PostgreSQL
I used Python to help me create these tables and then import these tables into my DBMS. 

```python
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
```

