SELECT 
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM public."CovidDeaths"
order by 1, 2

-- Looking at Total Cases vs Total deaths
-- Shows the likelihood of dying if you contracted Covid in the UK
select
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 as case_fatality_rate
from public."CovidDeaths"
where location = 'United Kingdom'
order by 1,2

-- Finding the 10 countries with the highest case fatality rate
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

-- Looking at Total Cases vs Population
-- Shows percentage of population that got covid in the UK
select
	location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 as percentage_affected
from public."CovidDeaths"
where location = 'United Kingdom'
order by 1,2

-- Looking at countries with highest percentage_affected
select
	location,
	population,
	MAX(total_cases),
	MAX(total_cases/population)*100 as percentage_affected
from public."CovidDeaths"
group by population, location
order by percentage_affected desc

-- Looking at the death count in each country
select
	location,
	population,
	MAX(total_deaths) as total_death_count
from public."CovidDeaths"
where continent is not null 
-- I have put this condition because without this, the query pulls up results like 'World' and 'Africa'. We get regions and contienents. 
-- Entries which do not have a continent attached to it are regions and continents
group by population, location
having MAX(total_deaths) is not null
-- Removed blank entries 
order by total_death_count desc

-- Countries with the 10 highest death counts
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

-- Death count in each continent
select
	continent,
	MAX(total_deaths) as total_death_count
from public."CovidDeaths"
where continent is not null 
group by continent
having MAX(total_deaths) is not null
-- Removed blank entries 
order by total_death_count desc

-- Death count in each group, including continents and income group 
select
	location,
	population,
	MAX(total_deaths) as total_death_count
from public."CovidDeaths"
where continent is null 
group by location, population
having MAX(total_deaths) is not null
-- Removed blank entries 
order by total_death_count desc


-- Daily global cases and deaths
select 
	date,
	sum(new_cases) as daily_global_cases,
	sum(new_deaths) as daily_global_deaths,
from public."CovidDeaths"
where continent is not null and new_cases != 0 and new_deaths != 0
group by date
order by 1,2

-- Cumulative cases and deaths, and cumulative fatailty rate over time
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

-- Total vaccinations
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

-- Vaccinations over time
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

-- Vaccination rate
-- We're unable to do this in the previous query as we can't just do cumulative_total_vaccinations/Population
-- Therefore, we must use a CTE
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
