/* Exploratory Data Analysis on Covid Vaccinations
Data obtained from https://ourworldindata.org/explorers/coronavirus-data-explorer
Data is classified as open access under the Creative Commons BY license
Data current as of 14 August 2022. 

Skills used: joins, aggregates, CTEs, views, partitions */

-- GLOBAL VACCINATION ANALYSIS

-- investigating population vs vaccination counts by continent

SELECT dea.location, /*dea.continent,*/ MAX(dea.population) AS CountryPopulation, MAX(vac.people_vaccinated) AS VaccinationCount
FROM CovidDeaths dea LEFT JOIN CovidVaccinations vac 
    ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NULL AND dea.location NOT IN ('International', 'European Union') AND dea.location NOT LIKE '%income'
GROUP BY dea.location, dea.continent
ORDER BY 2,3;

-- 1. creating view to generate visualization in Tableau

GO
CREATE VIEW GlobalVaccinationCount
AS 
SELECT dea.location, /*dea.continent,*/ MAX(dea.population) AS CountryPopulation, MAX(vac.people_vaccinated) AS VaccinationCount
FROM CovidDeaths dea LEFT JOIN CovidVaccinations vac 
    ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NULL AND dea.location NOT IN ('International', 'European Union') AND dea.location NOT LIKE '%income'
GROUP BY dea.location, dea.continent
-- ORDER BY 2,3;
GO 

-- investigating population vs vaccination count by country

SELECT dea.location, dea.continent, MAX(dea.population) AS CountryPopulation, MAX(vac.people_vaccinated) AS VaccinationCount
FROM CovidDeaths dea LEFT JOIN CovidVaccinations vac 
    ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.continent
ORDER BY 1;

-- creating CTE to calculate percentage of population vaccinated

WITH VaccinationPercentage(location, continent, CountryPopulation, VaccinationCount, VaccinationRate)
AS (
SELECT dea.location, dea.continent, MAX(dea.population) AS CountryPopulation, MAX(vac.people_vaccinated) AS VaccinationCount
    , (CAST(MAX(vac.people_vaccinated) AS float)/MAX(dea.population))*100 AS VaccinationRate
FROM CovidDeaths dea LEFT JOIN CovidVaccinations vac 
    ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.continent
--ORDER BY 1
)
SELECT *
FROM VaccinationPercentage

-- 2. creating view to generate visualization in Tableau

GO
CREATE VIEW GlobalVaccinationRates AS
    WITH VaccinationPercentage(location, continent, CountryPopulation, VaccinationCount, VaccinationRate)
    AS (
        SELECT dea.location, dea.continent, MAX(dea.population) AS CountryPopulation, MAX(vac.people_vaccinated) AS VaccinationCount
        , (CAST(MAX(vac.people_vaccinated) AS float)/MAX(dea.population))*100 AS VaccinationRate
        FROM CovidDeaths dea LEFT JOIN CovidVaccinations vac 
         ON dea.location = vac.location AND dea.date = vac.date
         WHERE dea.continent IS NOT NULL
         GROUP BY dea.location, dea.continent
--ORDER BY 1
)
GO

-- investigating the count of new cases compared to the count of new vaccinations 
SELECT dea.date, AVG(new_cases) AS DailyNewCases, AVG(new_vaccinations) AS DailyNewVaccinations
FROM CovidDeaths dea JOIN CovidVaccinations vac 
    ON dea.date=vac.date
WHERE new_cases IS NOT NULL AND new_vaccinations IS NOT NULL
GROUP BY dea.date
--ORDER BY 1

-- 3. creating view for visualization in Tableau

GO
CREATE VIEW DailyCasesVsVaccinations 
AS 
SELECT dea.date, AVG(new_cases) AS DailyNewCases, AVG(new_vaccinations) AS DailyNewVaccinations
FROM CovidDeaths dea JOIN CovidVaccinations vac 
    ON dea.date=vac.date
WHERE new_cases IS NOT NULL AND new_vaccinations IS NOT NULL
GROUP BY dea.date
--ORDER BY 1
GO

-- ANALYSIS BY INCOME

-- vaccination totals by income level

SELECT dea.location, MAX(dea.population) AS Population, MAX(people_vaccinated) AS PeopleVaccinated
, MAX(people_fully_vaccinated) AS PeopleFullyVaccinated
FROM CovidDeaths dea JOIN CovidVaccinations vac 
    ON dea.date = vac.date AND dea.location = vac.location
WHERE dea.location LIKE '%income'
GROUP BY dea.location

-- 4. creating view for visualization in Tableau

GO
CREATE VIEW VaccinationTotalsByIncome
AS
SELECT dea.location, MAX(dea.population) AS Population, MAX(people_vaccinated) AS PeopleVaccinated
, MAX(people_fully_vaccinated) AS PeopleFullyVaccinated
FROM CovidDeaths dea JOIN CovidVaccinations vac 
    ON dea.date = vac.date AND dea.location = vac.location
WHERE dea.location LIKE '%income'
GROUP BY dea.location
GO

-- investigating daily rolling total of vaccinations by income level

SELECT date, location, new_vaccinations
    ,SUM(people_vaccinated) OVER (PARTITION BY location ORDER BY location, date) AS RollingPeopleVaccinated 
FROM CovidVaccinations 
WHERE location LIKE '%income'
ORDER BY date, location

-- 5. creating view for visualization in Tableau

GO
CREATE VIEW RollingTotalsByIncome
AS
SELECT date, location, new_vaccinations
    ,SUM(people_vaccinated) OVER (PARTITION BY location ORDER BY location, date) AS RollingPeopleVaccinated 
FROM CovidVaccinations 
WHERE location LIKE '%income'
--ORDER BY date, location
GO

-- investigating share of population in extreme poverty (expressed as percentage of population) by location

SELECT dea.location, MIN(extreme_poverty) AS PopulationInExtremePoverty
-- , (MIN(population)-MAX(people_vaccinated)) AS PopulationNotVaccinated
-- , MIN(population) AS Population
, (MIN(population)-MAX(people_vaccinated))/CAST(MIN(population) AS float)*100 AS PercentageNotVaccinated 
FROM CovidDeaths dea JOIN CovidVaccinations vac 
    ON dea.location = vac.location
WHERE extreme_poverty IS NOT NULL AND dea.location NOT IN ('European Union', 'International')
GROUP BY dea.location
ORDER BY dea.location

-- 6. creating view for visualization in Tableau

GO
CREATE VIEW ExtremePovertyVsUnvaccinated 
AS 
SELECT dea.location, MIN(extreme_poverty) AS PopulationInExtremePoverty
-- , (MIN(population)-MAX(people_vaccinated)) AS PopulationNotVaccinated
-- , MIN(population) AS Population
, (MIN(population)-MAX(people_vaccinated))/CAST(MIN(population) AS float)*100 AS PercentageNotVaccinated 
FROM CovidDeaths dea JOIN CovidVaccinations vac 
    ON dea.location = vac.location
WHERE extreme_poverty IS NOT NULL AND dea.location NOT IN ('European Union', 'International')
GROUP BY dea.location
--ORDER BY dea.location
GO
