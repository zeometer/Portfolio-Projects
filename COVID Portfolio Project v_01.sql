-- SELECT * 
-- FROM PortfolioProject.dbo.CovidDeaths
-- ORDER BY 3,4

-- SELECT * 
-- FROM PortfolioProject.dbo.CovidVaccinations
-- ORDER BY 3,4

-- select data we're using

SELECT [location],[date], total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1,2;

--altering column to float for additional computation
ALTER TABLE PortfolioProject.dbo.CovidDeaths
ALTER COLUMN total_cases float;

-- looking at total cases vs total deaths
-- shows likelihood of dying if a person contracts covid in a given country
SELECT [location],[date], total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%States%'
ORDER BY 1,2;

-- looking at total cases vs population
-- shows what percentage of population got COVID
SELECT [location],[date], population, total_cases, (total_deaths/population)*100 AS InfectionRate
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%States%' AND Continent IS NOT NULL
ORDER BY 1,2;

-- looking at countries with highest infection rate compared to population

SELECT location,population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
-- WHERE location LIKE '%States%'
WHERE CONTINENT IS NOT NULL AND continent LIKE '%North%'
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC;

-- showing countries with highest death count compared to population

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
-- WHERE location LIKE '%States%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- LET'S BREAK THINGS DOWN BY CONTINENT
-- thing to consider: reporting trends (total death count as percentage of population vs mortality rate as given by externa lsources)



-- Showing continents with the highest death count per population

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
-- WHERE location LIKE '%States%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS

SELECT date, SUM(new_cases), SUM(CAST(new_deaths AS float)), SUM(CAST(new_deaths AS float))/SUM(new_cases)*100--, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location LIKE '%States%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

-- ! can use this to compare global mortality rates to country rates
SELECT SUM(new_cases), SUM(CAST(new_deaths AS float)), SUM(CAST(new_deaths AS float))/SUM(new_cases)*100--, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location LIKE '%States%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;

-- looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,   SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
    dea.date) AS RollingPeopleVaccinated
--,   (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location=vac.location 
    AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- USE CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,   SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
    dea.date) AS RollingPeopleVaccinated
--,   (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location=vac.location 
    AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac

-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPeopleVaccinated
CREATE TABLE #PercentPeopleVaccinated
(
    continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population numeric,
    new_vaccinations numeric,
    RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPeopleVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,   SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
    dea.date) AS RollingPeopleVaccinated
--,   (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location=vac.location 
    AND dea.date=vac.date
-- WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPeopleVaccinated

-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW PercentagePopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,   SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
    dea.date) AS RollingPeopleVaccinated
--,   (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location=vac.location 
    AND dea.date=vac.date
-- WHERE dea.continent IS NOT NULL
--ORDER BY 2,3


-- it's a view!
SELECT *
FROM PercentagePopulationVaccinated