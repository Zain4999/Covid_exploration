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
I wanted to find the most recent case fatality rate in the UK, and for this I filtered by total deaths, total cases, and then by the most recent date in the databse and then used this to calculate the case fatality rate in the UK.

```sql
select
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 as case_fatality_rate
from public."CovidDeaths"
where location = 'United Kingdom' and date = '2024-07-07'
```
I then found these results:

| Location       | Date       | Total Cases | Total Deaths | Case Fatality Rate (%) |
|----------------|------------|-------------|--------------|------------------------|
| United Kingdom | 2024-07-07 | 24,956,066  | 232,112      | 0.93    

I then also wanted to find the countries with the top 10 case mortality rates, and for this I did not filter for the UK

```sql
select
	location,
	continent,
	date,
	population,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 as case_fatality_rate
	row_number() over (order by (total_deaths/total_cases)*100 desc) as rank
from public."CovidDeaths"
where date = '2024-07-07' and total_cases is not null and total_deaths is not null and continent is not null
order by case_fatality_rate desc
limit 10
```

| Location                    | Continent       | Date       | Total Cases | Total Deaths | Total Recovered | Case Fatality Rate (%) |
|-----------------------------|-----------------|------------|-------------|--------------|-----------------|------------------------|
| Yemen                       | Asia            | 2024-07-07 | 33,696,612  | 11,945       | 2,159           | 18.07                  |
| Sudan                       | Africa          | 2024-07-07 | 46,874,200  | 63,993       | 5,046           | 7.89                   |
| Syria                       | Asia            | 2024-07-07 | 22,125,242  | 57,423       | 3,163           | 5.51                   |
| Somalia                     | Africa          | 2024-07-07 | 17,597,508  | 27,334       | 1,361           | 4.98                   |
| Peru                        | South America   | 2024-07-07 | 34,049,588  | 4,526,977    | 220,975         | 4.88                   |
| Egypt                       | Africa          | 2024-07-07 | 110,990,096 | 516,023      | 24,830          | 4.81                   |
| Mexico                      | North America   | 2024-07-07 | 127,504,120 | 7,616,491    | 334,501         | 4.39                   |
| Bosnia and Herzegovina      | Europe          | 2024-07-07 | 3,233,530   | 403,652      | 16,388          | 4.06                   |
| Liberia                     | Africa          | 2024-07-07 | 5,302,690   | 7,930        | 294             | 3.71                   |
| Afghanistan                 | Asia            | 2024-07-07 | 41,128,772  | 235,214      | 7,998           | 3.40                   |

I was interested to see how the UK ranked in terms of its CFR, so I assigned a row number to each row using the row_number function(). The I ordered this function to assign rows in the order of the CFR

UK came 108
