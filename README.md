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

### Importing the data
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
### UK case fatality rate 
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

### Top 10 case fatality rates
I then also wanted to find the countries with the top 10 case fatality rates, and for this I did not filter for the UK

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

| Country                   | Continent      | Date       | Population | Cases     | Deaths | Case Fatality Rate (%) | Rank |
|---------------------------|----------------|------------|------------|-----------|--------|------------------------|------|
| Yemen                     | Asia           | 2024-07-07 | 33,696,612 | 11,945    | 2,159  | 18.07                  | 1    |
| Sudan                     | Africa         | 2024-07-07 | 46,874,200 | 63,993    | 5,046  | 7.88                   | 2    |
| Syria                     | Asia           | 2024-07-07 | 22,125,242 | 57,423    | 3,163  | 5.51                   | 3    |
| Somalia                   | Africa         | 2024-07-07 | 17,597,508 | 27,334    | 1,361  | 4.98                   | 4    |
| Peru                      | South America  | 2024-07-07 | 34,049,588 | 4,526,977 | 220,975 | 4.88                  | 5    |
| Egypt                     | Africa         | 2024-07-07 | 110,990,096 | 516,023  | 24,830 | 4.81                   | 6    |
| Mexico                    | North America  | 2024-07-07 | 127,504,120 | 7,616,491 | 334,501 | 4.39                  | 7    |
| Bosnia and Herzegovina    | Europe         | 2024-07-07 | 3,233,530   | 403,652  | 16,388 | 4.06                   | 8    |
| Liberia                   | Africa         | 2024-07-07 | 5,302,690   | 7,930    | 294    | 3.71                   | 9    |
| Afghanistan               | Asia           | 2024-07-07 | 41,128,772  | 235,214  | 7,998  | 3.40                   | 10   |


I was interested to see how the UK ranked in terms of its CFR, so I assigned a row number to each row using the row_number function(). The I ordered this function to assign rows in the order of the CFR

UK came 108th highest for CFR out of 226 countries.

### Total death count
I then wanted to find the total death count in each country. For this I filtered by location and total death. However, as each country has a different death count for each date, I had to find the maximum death count for each country and group it by location and population. We need to use a group by clause as there are multiple rows with the same value that SQL needs to aggregate.
I also wanted to show the percentage of the population that had died from covid.

```sql
select
	location,
	population,
	MAX(total_deaths) as total_death_count,
	ROUND((MAX(total_deaths)/population*100)::numeric,3) as population_death_percentage
from public."CovidDeaths"
where continent is not null 
-- I have put this condition because without this, the query pulls up results like 'World' and 'Africa'. We get regions and contienents. 
-- Entries which do not have a continent attached to it are regions and continents
group by population, location
having MAX(total_deaths) is not null
-- Removed blank entries 
order by total_death_count desc
limit 10
```

| Location       | Population  | Total Death Count | Population Death Percentage |
|----------------|-------------|-------------------|-----------------------------|
| United States  | 338289856   | 1190579           | 0.352                       |
| Brazil         | 215313504   | 702116            | 0.326                       |
| India          | 1417173120  | 533622            | 0.038                       |
| Russia         | 144713312   | 403108            | 0.279                       |
| Mexico         | 127504120   | 334501            | 0.262                       |
| United Kingdom | 67508936    | 232112            | 0.344                       |
| Peru           | 34049588    | 220975            | 0.649                       |
| Italy          | 59037472    | 197081            | 0.334                       |
| Germany        | 83369840    | 174979            | 0.210                       |
| France         | 67813000    | 168091            | 0.248                       |

I was very surpised to learn that the UK had the 6th highest death count considering that it has the 21st highest population count in the world. 

### Rolling case fatality rate 

I was interested in calcualting the global rolling case fatality rate. I filtered by each country's total cases and deaths and took the sum of those for each day to find an ongoing global case fatality rate.

```sql
select distinct 
	date,
	sum(total_cases) over (partition by date) as total_global_cases,
	sum(total_deaths) over (partition by date) as total_global_deaths,
	(sum(total_deaths) over (partition by date))/(sum(total_cases) over (order by date))*100 as ongoing_case_fatality_rate
from public."CovidDeaths"
where continent is not null and total_cases != 0 and total_deaths != 0
-- Only getting countries and removing the blank entrjes 
group by date, total_cases, total_deaths
order by date
```

I downloaded the result as a CSV and used python to plot date vs rolling case fatality rate

```python
import pandas as pd
import matplotlib.pyplot as plt
df = pd.read_csv('/Users/zainsiddiqi/Data Analyst upskilling/CovidData/rolling CFR.csv')
df['date'] = pd.to_datetime(df['date'])
df[['date', 'rolling_case_fatality_rate']]
date = df['date']
rolling_case_fatality_rate = df['rolling_case_fatality_rate']
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.ticker import MultipleLocator
plt.plot(date, rolling_case_fatality_rate)
plt.ylim(0,2)
plt.gca().xaxis.set_major_locator(mdates.YearLocator())
plt.gca().xaxis.set_minor_locator(mdates.MonthLocator())
plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))
plt.gca().yaxis.set_major_locator(MultipleLocator(0.2))  # Set y-axis major ticks at intervals of 0.1
plt.ylabel('Global case fatality rate', fontfamily = 'Arial')
plt.xlabel('Date', fontfamily = 'Arial')
plt.title('Global case fatality rate over time', fontweight = 'bold', fontfamily = 'Arial')
plt.show()
```
![CFR over time](https://github.com/Zain4999/Covid_exploration/blob/main/CFR%20over%20time.png))

We can see that over time the case fatality rate falls.

### Vaccinations
I wanted to have a look at the vaccinations in each country over time. I joined the CovidVaccinations table to the CovidDeaths data, and used this to find the total vaccinations and compare this with other statistics. 

```python
select 
	cd.continent,
	cd.location, 
	cd.date,
	cd.population,
	cv.total_vaccinations
from public."CovidDeaths" as cd
inner join public."CovidVaccinations" as cv on cd.location = cv.location and cd.date = cv.date
where cd.continent is not null and total_vaccinations is not null
order by 2,3
```
With this, I was interested to see the cumulative veccaintions compared to the cumulative cases.

```sql
select 
	cd.continent,
	cd.location, 
	cd.date,
	cd.population,
	sum(coalesce(cd.new_cases, 0)) over (partition by cd.location order by cd.date) as cumulative_cases,
	sum(coalesce(cv.new_vaccinations,0)) over (partition by cd.location order by cd.date) as cumulative_vaccinations
from public."CovidDeaths" as cd
inner join public."CovidVaccinations" as cv on cd.location = cv.location and cd.date = cv.date
where cd.continent is not null and cd.location = 'United Kingdom'
order by 2,3
```
I used python to plot both of these 

```python
import pandas as pd
import matplotlib.pyplot as plt
df = pd.read_csv('/Users/zainsiddiqi/Data Analyst upskilling/CovidData/CasesVsVaccinations.csv')
df['date'] = pd.to_datetime(df['date'])
df_UK = df[df['location'] == 'United Kingdom'].copy()
df_UK[['date', 'cumulative_cases', 'cumulative_vaccinations']]
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.ticker import MultipleLocator, ScalarFormatter, FuncFormatter
date = df_UK['date']
cumulative_deaths = df_UK['cumulative_deaths']
cumulative_vaccinations = df_UK['cumulative_vaccinations']'''
ax = df_UK.plot(x = 'date', y = 'cumulative_cases', label = 'Cumulative cases', color = 'r')
df_UK.plot(x = 'date', y = 'cumulative_vaccinations', label = 'Cumulative Vaccinations', color = 'b', secondary_y = True, ax = ax)
ax.set_xlabel('Date')
ax.set_ylabel('Cumulative Cases (Millions)', color='r')
ax.right_ax.set_ylabel('Cumulative Vaccinations (Millions)', color='b')
ax.set_ylim(0, 50000000)
ax.right_ax.set_ylim(0, 200000000)
ax.set_xlim([pd.Timestamp('2020-01'),df_UK['date'].max()])

def millions(x, pos):
    'The two args are the value and tick position'
    return '%d' % (x * 1e-6)

formatter = FuncFormatter(millions)
plt.gca().xaxis.set_major_locator(mdates.YearLocator())
plt.gca().xaxis.set_minor_locator(mdates.MonthLocator())
plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m'))
ax.yaxis.set_major_formatter(formatter)
ax.right_ax.yaxis.set_major_formatter(formatter)
plt.title('UK cumulative cases and Vaccinations')
plt.show()
```
![UK cumulative cases vs vaccinations](https://github.com/Zain4999/Covid_exploration/blob/main/CasesVsVaccinationsV2.png)

Comparing this with Deaths vs Vaccinations:

![UK cumulative deaths vs vaccinations](https://github.com/Zain4999/Covid_exploration/blob/main/DeathsVsVaccinations.png)

The result here is very interesting. We can see visually as the total vaccinations adminstered increased in the UK, the number of cases continued to rise quite rapidly which at first glance can seem as if the vaccines are not successful at preveneting new covid cases. It's a different story when it comes to deaths, however. The data shows that when the vaccines were first rolling out in January 2021 the number of new deaths per day was still high up until March/April 2021. It then began to stabilise after that, suggesting it took time for the effects of the vaccine to take place.

Finding the percentage of the population vaccinated over time for each country:

```sql
with PopvsVac as (
select 
	cd.continent,
	cd.location, 
	cd.date,
	cd.population,
	cv.new_vaccinations,
	sum(cv.new_vaccinations) over (partition by cd.location order by cd.date) as cumulative_total_vaccinations
from public."CovidDeaths" as cd
inner join public."CovidVaccinations" as cv on cd.location = cv.location and cd.date = cv.date
where cd.continent is not null
order by 2,3
)
select *,
	(cumulative_total_vaccinations/population)*100 as rolling_vaccination_rate
from PopvsVac
```
This percentage naturally goes up as more people get vaccinated. I had to use a CTE to calculate this.

# What I learned

Throughout this project, I've been able to level up my SQL and Python skills to explore covid data.

- **Complex query crafting**: I became comfortable using advanced SQL queries to filter specific data and to idenitfy trends by using the WITH, ORDER BY and GROUP BY.
- **Rolling statistics**: Learned how to produce rolling stastics like the ongoing case fatality rate using SUM, PARTITION BY and ORDER BY.
- **Python visualisation**: Became confident loading CSVs into python and visaulisfing it using modules such as Pandas and Matplotlib. 
- **Analytical thinking**: Enhanced my real world analytical and problem solving skills.

# Conclusions

### Insights

There were 2 main insights I got from this data:
1. The UK had the 6th highest total death count in the world while having the 21st largest population in the world. This is very significant and requires further analysis into why so many people were lost to covid in the UK.
2. Vaccinations may not reduce the chance of someone contracting covid-19 but it does reduce the chance of death, and it takes time for the benefits of vaccinnes to be seen. The rapid rollout of the vaccines was crucial in lowering the number of new deaths per day. This may suggest that vaccines should be advised by government bodies to reduce severity of symptoms instead of completely eliminate the chance of contracting the disease.

### Closing thoughts

This project enhanced my SQL and Python skills and provided valuable insights into the effect covid-19 had on the world. 
