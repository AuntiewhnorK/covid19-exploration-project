-- Author: Auntiewhnor Kpolie
-- Data Tables: CovidDeaths, CovidVaccinations (imported from Excel)
-- Last Updated: 01/08/2022

Select *
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
order by location, date

--Select *
--FROM PortfolioProject..CovidVaccinations
--order by 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY location, date

-- Total Cases vs Total Deaths
-- Likelihood of dying if you contract COVID in a country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY location, date


-- Total Cases vs Population
-- Percentage of population that got Covid
SELECT sub.Location, MAX(sub.CasePercentage) as MaxCasePercentage
FROM (SELECT Location, date, total_cases, population, (total_cases/population)*100 AS CasePercentage
	  FROM PortfolioProject..CovidDeaths) sub
GROUP BY sub.location
ORDER BY sub.location


-- What countries have the highest infection rates (compared to Population)?
SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases)/population)*100 AS PercentPopulationInfection
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfection DESC


-- Highest infection rated by given continent
SELECT location, continent, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases)/population)*100 AS PercentPopulationInfection
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location, continent, population
ORDER BY PercentPopulationInfection DESC, continent


-- Show which countries with the Highest Death Count per Population

-- we cast total_deaths as integer (the data type is nvarchar )
SELECT Location,  MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
GROUP BY Location
ORDER BY TotalDeathCount DESC


-- Result: we see continents like Asia and Africa shown in the Location column
-- In Covid Deaths: Asia is listed as both a continent and a location (where continent column is null)
-- Fix: Only use data where continent is not NULL


-- Break things down by continent

-- Showing continents with the highest death count per population
SELECT continent,  MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL  
GROUP BY continent
ORDER BY TotalDeathCount DESC



-- GLOBAL STATS

-- total_cases, total_deaths, death percentage per day
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY date

-- death percentage across the world
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL


-- Total popluation vs vaccination
-- total amount of people in the world that have been vaccinated

-- Creating a Rolling Count of People Vaccinated per location

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) as Rolling_New_Vaccinations
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY dea.location, dea.date



-- TEMP TABLE (Getting a max for each location's Rolling_New_Vaccinations)

DROP Table if EXISTS #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_New_Vaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) as Rolling_New_Vaccinations
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY dea.location, dea.date

 -- The max percent vaccinated in each location
SELECT sub.Continent, sub.Location, sub.Population, MAX(sub.PercentVaccinated) as MaxPercentVaccinated
FROM (SELECT *, (Rolling_New_Vaccinations/Population)*100 as PercentVaccinated
		FROM #PercentPopulationVaccinated) sub
GROUP BY sub.Continent, sub.Location, sub.Population
ORDER BY sub.Location


-- Create a View for Tableau Visualization
GO

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
	OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) as Rolling_New_Vaccinations
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL

GO 
CREATE VIEW ContinentDeathCount AS
SELECT continent,  MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL  
GROUP BY continent




-- (extra) MAX Percent Vaccinated Per Location using CTE

--WITH PopVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_New_Vaccinations) AS

--(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
--	SUM(CONVERT(bigint, vac.new_vaccinations)) 
--	OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) as Rolling_New_Vaccinations
--FROM PortfolioProject..CovidDeaths as dea
--JOIN PortfolioProject..CovidVaccinations as vac
--	ON dea.location = vac.location
--	AND dea.date = vac.date
--WHERE dea.continent is not NULL
----ORDER BY dea.location, dea.date
--)


----Max vaccinations
--SELECT sub.Location, MAX(sub.PopVaccinated) as MaxPopVacc
--FROM (SELECT *, (Rolling_New_Vaccinations/population)*100 as PopVaccinated
--		FROM PopVac
--		WHERE PopVac.Location = 'Albania') sub
--GROUP BY sub.Location