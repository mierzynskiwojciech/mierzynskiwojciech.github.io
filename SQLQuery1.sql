/*
Covid 19 Data Exploration 
Skills used: Joins, Table Alteration, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types, CTE's, Temp Tables, NULLIF
*/
USE covid_portfolio;

-- Change data format of total_cases and total_deaths to FLOAT

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases FLOAT;

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths FLOAT;


-- Select Data that we are going to be starting with

SELECT continent, location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL;



-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select location, date, total_cases, total_deaths, total_deaths/NULLIF(total_cases,0)*100 AS DeathPercentage
From CovidDeaths

-- Death Count per country

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From CovidDeaths
WHERE location NOT IN ('European Union', 'World', 'North America', 'South America', 'Asia', 'Europe', 'Oceania', 'High income', 'Upper middle income', 'Lower middle income')
Group by location
order by TotalDeathCount desc

-- Average likelihood of dying if you contract covid in your country 
-- Shows countries with highest death rate

SELECT location, avg(total_deaths/NULLIF(total_cases,0)*100) AS AverageDeathPercentage
FROM CovidDeaths
WHERE location NOT IN ('World', 'North America', 'South America', 'Asia', 'Europe', 'Oceania', 'High income', 'Upper middle income', 'Lower middle income')
GROUP BY location
ORDER BY AverageDeathPercentage DESC

-- Average likelihood of dying if you contract covid in your country in year 2023
-- Shows countries with highest death rate

SELECT location, avg(total_deaths/NULLIF(total_cases,0)*100) AS AverageDeathPercentage
FROM CovidDeaths
WHERE YEAR(date) = 2023
AND location NOT IN ('World', 'North America', 'South America', 'Asia', 'Africa', 'Europe', 'Oceania', 'High income', 'Upper middle income', 'Lower middle income')
GROUP BY location
ORDER BY AverageDeathPercentage DESC


-- Total Cases vs Population
-- Shows what percentage of population has been infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths

-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
WHERE location NOT IN ('World', 'North America', 'South America', 'Asia', 'Africa', 'Europe', 'Oceania', 'High income', 'Upper middle income', 'Lower middle income')
and YEAR(date) = 2023
Group by Location, Population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
WHERE location NOT IN ('World', 'North America', 'South America', 'Africa', 'Asia', 'Europe', 'Oceania', 'High income', 'Upper middle income', 'Lower middle income') 
Group by Location
ORDER BY TotalDeathCount DESC

-- TABLOU TABLE GRAPH 4

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Group by Location, Population, date
order by PercentPopulationInfected desc


-- Showing contintents with the highest death count per population

Select continent, SUM(cast(new_deaths as int)) as TotalDeathCount
From CovidDeaths
Group by continent
order by TotalDeathCount desc


-- GLOBAL TOTAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
WHERE location IN ('North America', 'South America', 'Asia', 'Europe','Africa', 'Oceania') 
order by 1,2


-- Total Population vs New Deaths
-- Creating a new table with with rolling new deaths

SELECT location,date, population,new_deaths, SUM(new_deaths) OVER (Partition by location ORDER BY location, date) AS RollingNewDeaths
From CovidDeaths

-- Saving the table under PopvsNewdeath

With PopvsNewdeath (location, Date, Population, new_deaths, RollingNewDeaths)
as
(
SELECT location,date, population,new_deaths, SUM(new_deaths) OVER (Partition by location ORDER BY location, date) AS RollingNewDeaths
From CovidDeaths
)

SELECT * FROM PopvsNewdeath

-- Creating a new table with with rolling new deaths

DROP Table if exists #PercentPopulationDeathCases
Create Table PercentPopulationDeathCases
(
Location nvarchar(255),
Date datetime,
Population numeric,
new_deaths numeric,
RollingNewDeaths numeric
)

INSERT INTO PercentPopulationDeathCases
SELECT location,date, population,new_deaths, SUM(new_deaths) OVER (Partition by location ORDER BY location, date) AS RollingNewDeaths
From CovidDeaths

-- Death Count Percentage vs. The total population

SELECT *, (RollingNewDeaths/population)*100 AS DeathCountVSPopulation
FROM PercentPopulationDeathCases

-- Death Count Percentage vs. The total number of cases

SELECT dea.date, dea.population, dea.location, dea.total_cases, rol.RollingNewDeaths, (rol.RollingNewDeaths/NULLIF(dea.total_cases,0)*100) AS DeathCountVSTotalcases
FROM PercentPopulationDeathCases rol
Join CovidDeaths dea
On rol.location = dea.location
and rol.date = dea.date
ORDER BY DeathCountVSTotalcases DESC

-- Countries with the average highest Death Count Percentage vs. The total number of cases

SELECT dea.location, avg(rol.RollingNewDeaths/NULLIF(dea.total_cases,0)*100) AS DeathCountVSTotalcases
FROM PercentPopulationDeathCases rol
Join CovidDeaths dea
On rol.location = dea.location
and rol.date = dea.date
group by dea.location
order by DeathCountVSTotalcases DESC


--A country with a highest DeathCountVSPopulation

SELECT location, max((RollingNewDeaths/Population)*100) AS DeathCountVSPopulation
from PercentPopulationDeathCases
group by location
order by DeathCountVSPopulation DESC

-- Shows Percentage of Population that was vaccinated

SELECT vac.location, MAX(vac.people_vaccinated/dea.population*100) AS Populationvaccinated
FROM CovidVaccinations vac
    Join CovidDeaths dea
        On dea.location = vac.location
        and dea.date = vac.date
GROUP BY vac.location
ORDER BY MAX(vac.people_vaccinated/dea.population*100) DESC

-- Create VIEWS to store data for visualizations

-- Showing contintents with the highest death count per population

CREATE VIEW DeathCount_Continents AS
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
Group by continent

-- Average likelihood of dying if you contract covid in your country in year 2023
-- Shows countries with highest death rate

CREATE VIEW Deathrate_2023 AS
SELECT location, avg(total_deaths/NULLIF(total_cases,0)*100) AS AverageDeathPercentage
FROM CovidDeaths
WHERE YEAR(date) = 2023
AND location NOT IN ('World', 'North America', 'South America', 'Asia', 'Europe', 'Oceania', 'High income', 'Upper middle income', 'Lower middle income')
GROUP BY location

-- Average likelihood of dying if you contract covid in your country year 2022
-- Shows countries with highest death rate

CREATE VIEW Deathrate_2022 AS
SELECT location, avg(total_deaths/NULLIF(total_cases,0)*100) AS AverageDeathPercentage
FROM CovidDeaths
WHERE YEAR(date) = 2022
AND location NOT IN ('World', 'North America', 'South America', 'Asia', 'Europe', 'Oceania', 'High income', 'Upper middle income', 'Lower middle income')
GROUP BY location

-- Countries with Highest Infection Rate compared to Population
CREATE VIEW InfectionRate AS
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
WHERE location NOT IN ('World', 'North America', 'South America', 'Asia', 'Europe', 'Oceania', 'High income', 'Upper middle income', 'Lower middle income')
Group by Location, Population

-- Countries with Highest Death Count per Population

CREATE VIEW DeathCount AS
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
WHERE location NOT IN ('World', 'North America', 'South America', 'Asia', 'Europe', 'Oceania', 'High income', 'Upper middle income', 'Lower middle income') 
Group by Location

-- Showing contintents with the highest death count per population

CREATE VIEW DeathCount_Continents AS
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
Group by continent

-- Death Count Percentage vs. The total population

CREATE VIEW DeathCountVSPopulation AS
SELECT *, (RollingNewDeaths/population)*100 AS DeathCountVSPopulation
FROM PercentPopulationDeathCases

-- Countries with the average highest Death Count Percentage vs. The total number of cases

CREATE VIEW DeathCountVSTotalcases AS
SELECT dea.location, avg(rol.RollingNewDeaths/NULLIF(dea.total_cases,0)*100) AS DeathCountVSTotalcases
FROM PercentPopulationDeathCases rol
Join CovidDeaths dea
On rol.location = dea.location
and rol.date = dea.date
group by dea.location

--A country with a highest DeathCountVSPopulation

CREATE VIEW MaxDeathCountVSPopulation AS
SELECT location, max((RollingNewDeaths/Population)*100) AS DeathCountVSPopulation
from PercentPopulationDeathCases
group by location


-- Shows Percentage of Population that was vaccinated

CREATE VIEW PercentageofPopVaccinated AS
SELECT vac.location, MAX(vac.people_vaccinated/dea.population*100) AS PercentageofPopVaccinated
FROM CovidVaccinations vac
    Join CovidDeaths dea
        On dea.location = vac.location
        and dea.date = vac.date
GROUP BY vac.location





