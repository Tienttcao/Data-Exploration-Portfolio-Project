SELECT   * 
FROM     ProjectPortfolio..CovidDeaths
ORDER BY 3,4;

SELECT   * 
FROM     ProjectPortfolio..CovidVaccination
ORDER BY 3,4;

--This query select location, date, total cases, new cases, total deaths and population
--order by location and date for an overview look at the data
SELECT location, 
       date, 
       total_cases, 
       new_cases, 
       total_deaths,
       population
FROM   ProjectPortfolio..CovidDeaths
ORDER BY 1,2;

--Looking at total cases vs Total Deaths
-- Show the likelihood of dying if you contract covid in United States
SELECT  location, 
        date, 
        total_cases, 
        total_deaths, 
        (total_deaths/total_cases)*100 as DeathsPercentage
FROM    ProjectPortfolio..CovidDeaths
WHERE   location like '%state%' 
ORDER BY 1,2;


-- Looking at the Total Cases vs Population 
-- Shows what percentage of population got Covid

SELECT location, 
       date, 
       total_cases,
       population, 
       ROUND((total_cases/population)*100,7) as CasesPercentage
FROM   ProjectPortfolio..CovidDeaths
WHERE  location like '%state%' and continent is not NULL
ORDER BY 1,2;

-- Looking at countries with Highest Infection Rate compared to population
SELECT location,
       population, 
       MAX(total_cases) as MaxInfectionRate, 
       MAX((total_cases/population)*100) as PercentagepopulationInfected
FROM     ProjectPortfolio..CovidDeaths
WHERE    Continent is  null
GROUP BY [location], [population]
ORDER BY PercentagepopulationInfected DESC;

-- Showing Countries with Highest Death Count per Population
SELECT location,
       MAX(cast(total_deaths as int)) as TotalDeathCount
FROM     ProjectPortfolio..CovidDeaths
WHERE    Continent is not null
GROUP BY [location], [population]
ORDER BY TotalDeathCount DESC;

-- Looking at Highest Total Death counts by continent

SELECT   continent,MAX(cast(total_deaths as int)) as TotalDeathCount
FROM     ProjectPortfolio..CovidDeaths
WHERE    Continent is not null
GROUP BY [continent]
ORDER BY TotalDeathCount DESC;

-- Global Numbers
SELECT --date, 
       SUM(new_cases) as TotalNewCases, 
       SUM(new_deaths) as TotalNewDeaths,
       SUM(cast(new_deaths as float))/SUM(cast(new_cases as float))*100 as DeathsPercentage
--ROUND((total_cases/population)*100,7) as CasesPercentage
FROM     ProjectPortfolio..CovidDeaths
WHERE    continent is not NULL
--GROUP BY [date]
ORDER BY  1,2;

-- Looking at vacination rate by date globally
SELECT dea.continent,
       dea.[location],
       dea.[date],
       dea.population,
       vac.new_vaccinations,
-- How many total people get vaccinated everyday by country?
       SUM(vac.new_vaccinations) 
       OVER(PARTITION BY dea.location ORDER BY dea.location,dea.Date) as RollingVaccination
FROM   ProjectPortfolio..CovidDeaths as dea
JOIN   ProjectPortfolio..CovidVaccination as vac
       ON dea.[location] = vac.[location]
       AND dea.[date] = vac.[date]
WHERE dea.continent is not NULL
ORDER BY 2,3;


-- Use CTE to calculate vaccination rate per population 
With VacvsPop (continent,location,date,population,new_vaccinations,RollingVaccination) AS 
(SELECT dea.continent,
       dea.[location],
       dea.[date],
       dea.population,
       vac.new_vaccinations,
       SUM(CONVERT(float,vac.new_vaccinations)) 
       OVER(PARTITION BY dea.location ORDER BY dea.location,dea.Date) as RollingVaccination
FROM   ProjectPortfolio..CovidDeaths as dea
JOIN   ProjectPortfolio..CovidVaccination as vac
       ON dea.[location] = vac.[location]
       AND dea.[date] = vac.[date]
WHERE dea.continent is not NULL);
--ORDER BY 2,3)

SELECT *, (RollingVaccination/population)*100 as VaccinatedPerPopulation
FROM VacvsPop;


-- TEMP Table

-- Adding drop table if future alterations needed
DROP TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TABLE PercentPopulationVaccinated(
Continent          NVARCHAR(255),
Location           NVARCHAR(255),
Date               DATE,
Population         NUMERIC,
New_vaccinations   NUMERIC,
RollingVaccination NUMERIC,
)
INSERT INTO PercentPopulationVaccinated
SELECT dea.continent,
       dea.[location],
       dea.[date],
       dea.population,
       vac.new_vaccinations,
-- How many total people get vaccinated everyday by country?
       SUM(CONVERT(float,vac.new_vaccinations)) 
       OVER(PARTITION BY dea.location ORDER BY dea.location,dea.Date) as RollingVaccination
FROM   ProjectPortfolio..CovidDeaths as dea
JOIN   ProjectPortfolio..CovidVaccination as vac
       ON dea.[location] = vac.[location]
       AND dea.[date] = vac.[date];
-- WHERE dea.continent is not NULL
GO

SELECT * ,
       (RollingVaccination/Population) *100
FROM PercentPopulationVaccinated;
GO

--Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as 
SELECT dea.continent,
       dea.[location],
       dea.[date],
       dea.population,
       vac.new_vaccinations,
-- How many total people get vaccinated everyday by country?
       SUM(CONVERT(float,vac.new_vaccinations)) 
       OVER(PARTITION BY dea.location ORDER BY dea.location,dea.Date) as RollingVaccination
FROM   ProjectPortfolio..CovidDeaths as dea
JOIN   ProjectPortfolio..CovidVaccination as vac
       ON dea.[location] = vac.[location]
       AND dea.[date] = vac.[date]
WHERE dea.continent is not NULL;
GO

SELECT * 
FROM   PercentPopulationVaccinated;