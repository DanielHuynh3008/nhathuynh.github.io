-- PREVIEW DATA
SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

-- SELECT INFORMATION TO BE USED IN THE PROJECT
SELECT [location], [date], population, total_cases, total_deaths
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2


-- VIEW CONTRACT PERCENTAGE IN THE USA and LIKELIHOOD OF DYING IF CONTRACTED 
SELECT [location], [date], population, total_cases, total_deaths, 
    CAST(total_cases/population*100 AS decimal(18,10)) AS ContractPercentage,
    CAST((total_deaths/total_cases)*100 as decimal(18,3)) AS DeathPercentage 
FROM PortfolioProject..CovidDeaths 
WHERE [location] LIKE '%states%'
ORDER BY 1, 2


-- VIEW CONTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION
SELECT [location], population, MAX(total_cases) AS HighestInfectionCount,
    MAX(total_cases/population*100) AS HighestInfectionRate
FROM PortfolioProject..CovidDeaths
GROUP BY [location], population
ORDER BY HighestInfectionRate DESC

-- VIEW COUNTRIES WITH HIGHEST DEATHCOUNT PER POPULATION
SELECT [location], population, MAX(total_deaths) AS HighestDeathCount,
    MAX(total_deaths/population*100) AS HighestDeathRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [location], population
ORDER BY HighestDeathRate DESC

-- VIEW DATA ON CONTINENT LEVEL
-- Continent with highest infection rate
SELECT [location], population, MAX(total_cases) AS HighestInfectionCount,
    MAX(total_cases/population*100) AS HighestInfectionRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY [location], population
ORDER BY HighestInfectionRate DESC

-- Continent with highest death rate
SELECT [location], population, MAX(total_deaths) AS HighestDeathCount,
    MAX(total_deaths/population*100) AS HighestDeathRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY [location], population
ORDER BY HighestDeathRate DESC


-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS TotalNewCases, SUM(new_deaths) AS TotalNewDeaths,
CASE
    WHEN SUM(new_cases) = 0 THEN NULL
    ELSE SUM(new_deaths)/SUM(new_cases)*100
END AS TotalDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE [location] IS NOT NULL
GROUP BY [date]
ORDER BY 1


-- PREVIEW VACCINATION DATA
SELECT *
FROM PortfolioProject..CovidVaccinations

-- JOIN DEATH DATA AND VACCINATION DATA AND VIEW TOTAL POPULATION VS. VACCINATION

--USE CTE
WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingTotalVaccinations)
AS
(
SELECT dea.continent, dea.[location], dea.[date], dea.population, vacc.new_vaccinations,
    SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.[date]) AS RollingTotalVaccinations
FROM PortfolioProject..CovidDeaths dea 
JOIN PortfolioProject..CovidVaccinations vacc 
    ON dea.[location] = vacc.[location]
    AND dea.[date] = vacc.[date]
WHERE dea.continent IS NOT NULL
)
SELECT *, (CAST(RollingTotalVaccinations as decimal)/Population)*100 AS RollingVaccinationRate
FROM PopvsVac

--USE TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingTotalVaccinations NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.[location], dea.[date], dea.population, vacc.new_vaccinations,
    SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.[date]) AS RollingTotalVaccinations
FROM PortfolioProject..CovidDeaths dea 
JOIN PortfolioProject..CovidVaccinations vacc 
    ON dea.[location] = vacc.[location]
    AND dea.[date] = vacc.[date]
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT *, RollingTotalVaccinations/Population*100 AS RollingVaccinationRate
FROM #PercentPopulationVaccinated


-- CREATE VIEWS TO STORE DATA FOR LATER VISUALIZATIONS 
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.[location], dea.[date], dea.population, vacc.new_vaccinations,
    SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.[date]) AS RollingTotalVaccinations
FROM PortfolioProject..CovidDeaths dea 
JOIN PortfolioProject..CovidVaccinations vacc 
    ON dea.[location] = vacc.[location]
    AND dea.[date] = vacc.[date]
WHERE dea.continent IS NOT NULL

