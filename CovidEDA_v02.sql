/*
COVID-19 Data Exploration (current as of 2022 Aug 16)
SKILLS USED: joins, changing data types, aggregates, window functions, CTEs, temp tables, views
*/

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

-- SELECT *
-- FROM PortfolioProject..CovidVaccinations
-- WHERE continent IS NOT NULL
-- ORDER BY 3,4;

-- select data we are using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- in importing the data, several of the columns are given the int or bigint data types
-- converting these data types to floats to facilitate more accurate computation

ALTER TABLE PortfolioProject..CovidDeaths ALTER COLUMN population FLOAT;
ALTER TABLE PortfolioProject..CovidDeaths ALTER COLUMN total_cases FLOAT;
ALTER TABLE PortfolioProject..CovidDeaths ALTER COLUMN new_cases FLOAT;
ALTER TABLE PortfolioProject..CovidDeaths ALTER COLUMN total_deaths FLOAT;
ALTER TABLE PortfolioProject..CovidDeaths ALTER COLUMN new_deaths FLOAT;

-- ANALYSIS BY COUNTRY

-- investigating total cases vs total deaths
-- shows mortality rate of United States citizens due to COVID

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS MortalityRate
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States' AND continent IS NOT NULL
ORDER BY 1,2;

-- creating view for visualization in Tableau

GO
CREATE VIEW USMortalityRate
AS
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS MortalityRate
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States' AND continent IS NOT NULL
--ORDER BY 1,2;
GO 

/*SELECT *
FROM USMortalityRate*/

-- investigating total cases vs population
-- shows the percentage of citizens of the US that have contracted COVID 

SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectionRate
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States' AND continent IS NOT NULL
ORDER BY 1,2;

-- identifying countries with highest infection totals relative to country population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 
    AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- identifying countries with highest death tolls relative to country population

SELECT location, population, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC;

-- ANALYSIS BY CONTINENT

-- investigating continents with highest mortality rates per population

SELECT location, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- creating view to store data for visualizations on Tableau
GO
CREATE VIEW DeathCountByContinent
AS 
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income%'
GROUP BY location
--ORDER BY TotalDeathCount DESC;
GO

-- investigating total cases vs total deaths
-- shows mortality rate of citizens by date due to COVID

SELECT /*date, */SUM(new_cases) AS GlobalTotalCases, SUM(new_deaths) AS GlobalTotalDeaths,
    SUM(new_deaths)/SUM(new_cases)*100 AS GlobalMortalityRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE '%income%'
--GROUP BY date
ORDER BY 1,2;

-- creating view to store data for visualizations on Tableau

GO
CREATE VIEW GlobalMortalityRate
AS
SELECT /*date, */SUM(new_cases) AS GlobalTotalCases, SUM(new_deaths) AS GlobalTotalDeaths,
    SUM(new_deaths)/SUM(new_cases)*100 AS GlobalMortalityRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE '%income%'
--GROUP BY date
--ORDER BY 1,2;
GO

/*SELECT *
FROM GlobalMortalityRate;*/

-- displaying global mortality rate by date

SELECT date, SUM(new_cases) AS GlobalTotalCases, SUM(new_deaths) AS GlobalTotalDeaths,
    SUM(new_deaths)/SUM(new_cases)*100 AS DailyGlobalMortalityRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE '%income%'
GROUP BY date
ORDER BY 1,2;

-- creating view to store for visualizations in Tableau

GO
CREATE VIEW DailyGlobalMortalityRate
AS 
SELECT date, SUM(new_cases) AS GlobalTotalCases, SUM(new_deaths) AS GlobalTotalDeaths,
    SUM(new_deaths)/SUM(new_cases)*100 AS GlobalMortalityRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE '%income%'
GROUP BY date
--ORDER BY 1,2;
GO

SELECT *
FROM DailyGlobalMortalityRate;

-- shows global mortality rate due to COVID

SELECT  SUM(new_cases) AS GlobalTotalCases, SUM(new_deaths) AS GlobalTotalDeaths,
    SUM(new_deaths)/SUM(new_cases)*100 AS GlobalMortalityRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE '%income%'
--GROUP BY date
ORDER BY 1,2;



-- investigating total population vs vaccination totals
-- will show percentage of citizens that have received at least one COVID vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
    AS RollingVaccinationTotal
--    , (RollingVaccinationTotal/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location=vac.location
    AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- creating CTE to investigate global vaccination percentage

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingVaccinationTotal)
AS ( 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
    AS RollingVaccinationTotal
--    , (RollingVaccinationTotal/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location=vac.location
    AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingVaccinationTotal/population)*100 AS RollingVaccinationRate
FROM PopvsVac;

-- creating temporary table to perform calculation on PARTITION BY in previous query

DROP TABLE IF EXISTS #GlobalVaccinationPercentage
CREATE TABLE #GlobalVaccinationPercentage
(
    continent nvarchar(255),
    location nvarchar(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingVaccinationTotal NUMERIC
)

INSERT INTO #GlobalVaccinationPercentage
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationTotal
--    , (RollingVaccinationTotal/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location=vac.location
    AND dea.date=vac.date
-- WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
SELECT *, (RollingVaccinationTotal/population)*100 AS RollingVaccinationRate
FROM #GlobalVaccinationPercentage;

-- creating view to store data for visualizations on Tableau

GO
CREATE VIEW GlobalVaccinationPercentage AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location
, dea.date) AS RollingVaccinationTotal
--    , (RollingVaccinationTotal/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location=vac.location
    AND dea.date=vac.date
WHERE dea.continent IS NOT NULL;
--ORDER BY 2,3
GO

-- SELECT *
-- FROM GlobalVaccinationPercentage;

/*SELECT *
FROM GlobalMortalityRate;*/

-- investigating global total population vs global death and vaccination counts

SELECT dea.location, SUM(dea.population) AS WorldPopulation, SUM(dea.total_deaths) as TotalDeathCount
, SUM(vac.total_vaccinations) as TotalVaccinationCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent IS NULL AND dea.location NOT LIKE '%income%'
GROUP BY dea.location;

-- creating view for visualization in tableau
GO
CREATE VIEW GlobalTotals
AS
SELECT dea.location, SUM(dea.population) AS WorldPopulation, SUM(dea.total_deaths) as TotalDeathCount
, SUM(vac.total_vaccinations) as TotalVaccinationCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent IS NULL AND dea.location NOT LIKE '%income%'
GROUP BY dea.location;
GO

/*SELECT *
FROM GlobalTotals;*/

-- investigating total population vs vaccination totals within United States
-- will show percentage of citizens that have received at least one COVID vaccine
-- using CTE to temporarily store data

WITH PopvsVac (location, date, population, new_vaccinations, RollingVaccinationTotal)
AS ( 
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
    AS RollingVaccinationTotal
--    , (RollingVaccinationTotal/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location=vac.location
    AND dea.date=vac.date
WHERE dea.continent IS NOT NULL AND dea.location LIKE '%States%';
--ORDER BY 2,3
)
SELECT *, (RollingVaccinationTotal/population)*100 AS RollingVaccinationRate
FROM PopvsVac;

-- creating view to store data for visualizations in Tableau

GO
CREATE VIEW USVaccinationPercentage
AS (
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
    AS RollingVaccinationTotal
--    , (RollingVaccinationTotal/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location=vac.location
    AND dea.date=vac.date
WHERE dea.continent IS NOT NULL AND dea.location LIKE '%States%'
    );
GO