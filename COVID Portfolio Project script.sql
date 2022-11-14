/* 
COVID 19 Data Exploration

Skills used:  Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM PortfolioProject..['covid-deaths$']
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..['covid-vaccinations$']
--ORDER BY 3,4

-- Select Data that we are going to be starting with

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..['covid-deaths$']
ORDER BY 1,2

--Looking at Total Cases vs. Total Deaths
--Shows likelihood of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..['covid-deaths$']
WHERE Location LIKE '%states%'
ORDER BY 1,2

--Looking at the Total Cases vs. Population
--Shows what percentage of population contracted covid

SELECT Location, date, population, total_cases, (total_cases/population)*100 as CovidPercentage
FROM PortfolioProject..['covid-deaths$']
--WHERE Location LIKE '%states%'
ORDER BY 1,2

--Looking at Countries with Highest Infection Rate compared to Population

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..['covid-deaths$']
--WHERE Location LIKE '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

--Showing Countries with Highest Death Count per Population

SELECT Location, MAX(cast(total_deaths as bigint)) as TotalDeathCount
FROM PortfolioProject..['covid-deaths$']
--WHERE Location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

--Let's break things down by continent

--Showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as bigint)) as TotalDeathCount
FROM PortfolioProject..['covid-deaths$']
--WHERE Location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global numbers

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as bigint)) as total_deaths, SUM(cast(new_deaths as bigint))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..['covid-deaths$']
--Where location like '%states%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

--Looking at Total Population vs. Vaccinations
--Shows Percentage of Population that has received at least one Covid vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location
, dea.Date) as RollingPeopleVaccinated 
--, (RollingPeople Vaccinated/population)*100
FROM PortfolioProject..['covid-deaths$'] as dea
JOIN PortfolioProject..['covid-vaccinations$'] as vac
	ON dea.Location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Using CTE to perform calculation on Partition By in previous query

WITH PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location
, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..['covid-deaths$'] as dea
JOIN PortfolioProject..['covid-vaccinations$'] as vac
	ON dea.Location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER by 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac

-- Using Temp Table to perform calculation on Partition By in previous query

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location
, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..['covid-deaths$'] as dea
JOIN PortfolioProject..['covid-vaccinations$'] as vac
	ON dea.Location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER by 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated



--Creating View to store date for later visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location
, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..['covid-deaths$'] as dea
JOIN PortfolioProject..['covid-vaccinations$'] as vac
	ON dea.Location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER by 2,3

SELECT *
FROM PercentPopulationVaccinated
