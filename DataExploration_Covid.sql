--Query the entire table
SELECT *
FROM PortfolioProject..CovidDeaths

--Select data to use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;

--Total cases vs. total deaths in Canada (death percentage)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location='Canada'
ORDER BY 2;

--Total cases vs. population in USA (case percentage)
SELECT location, date, total_cases, population, (total_cases/population)*100 AS CasePercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 2;

--Countries with highest infections vs. population
SELECT location, MAX(total_cases) AS TotalCasesCount, population, MAX((total_cases/population))*100 AS InfectionPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY InfectionPercentage DESC;

--EDA that shows when continent=NULL, location lists continents
SELECT continent, location
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL;

--EDA that shows when continent!=NULL, location lists countries
SELECT continent, location
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;

--Countries with highest death count
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathsCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC;

--Continents with highest death count
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathsCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC;

--Probably, doesnt't reflect the correct figures, e.g. total death count for N.America should combine both USA and Canada
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathsCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC;

--Global new cases and new deaths by date
SELECT date, SUM(new_cases) AS GlobalNewCases, SUM(CAST(new_deaths AS INT)) AS GLobalNewDeaths
FROM PortfolioProject..CovidDeaths
GROUP BY date
ORDER BY date;

--Total global death percentage
SELECT SUM(new_cases) AS TotalGlobalCases, SUM(CAST(new_deaths AS INT)) AS TotalGlobalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS GlobalDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;

--Query the entire table
SELECT *
FROM PortfolioProject..CovidVaccinations;

--Inner join on both tables by location and date
SELECT *
FROM PortfolioProject..CovidDeaths cd
INNER JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location=cv.location
	AND cd.date=cv.date
WHERE cd.continent IS NOT NULL;

--New each day vaccinations
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
FROM PortfolioProject..CovidDeaths cd
INNER JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location=cv.location
	AND cd.date=cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2,3;

--Rolling total vaccinations by location and date
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CONVERT(INT,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS RollingTotalVaccinations
	--, (RollingTotalVaccinations/population)*100 AS PercentagePopulationVaccinated (*refer to CTE below)
FROM PortfolioProject..CovidDeaths cd
INNER JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location=cv.location
	AND cd.date=cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2,3;

--CTE for calculating PercentagePopulationVaccinated using RollingTotalVaccinations (cannot use generated aggregated column directly in the query above)
WITH PopVsVac (Continent, Location, Date, Population, NewVaccinations, RollingTotalVaccinations)
AS (
	SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CONVERT(INT,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS RollingTotalVaccinations
	FROM PortfolioProject..CovidDeaths cd
		INNER JOIN PortfolioProject..CovidVaccinations cv
		ON cd.location=cv.location
		AND cd.date=cv.date
	WHERE cd.continent IS NOT NULL
	--cannot use ORDER BY in common table expressions
)
SELECT *, (RollingTotalVaccinations/Population)*100 AS PercentagePopulationVaccinated
FROM PopVsVac;

--Temporary Table for executing the same query as above
DROP TABLE IF EXISTS #PopVsVacTable;
CREATE TABLE #PopVsVacTable (
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime, 
	Population numeric, 
	NewVaccinations numeric, 
	RollingTotalVaccinations numeric
);
INSERT INTO #PopVsVacTable
	SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
		SUM(CONVERT(INT,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS RollingTotalVaccinations
		FROM PortfolioProject..CovidDeaths cd
			INNER JOIN PortfolioProject..CovidVaccinations cv
			ON cd.location=cv.location
			AND cd.date=cv.date
		WHERE cd.continent IS NOT NULL
		ORDER BY 2,3;
SELECT *, (RollingTotalVaccinations/Population)*100 AS PercentagePopulationVaccinated
FROM #PopVsVacTable;

--Creating view to be accessed later for visualizations
CREATE VIEW RollingTotalVaccinations AS
	SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
		SUM(CONVERT(INT,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.date) AS RollingTotalVaccinations
		FROM PortfolioProject..CovidDeaths cd
			INNER JOIN PortfolioProject..CovidVaccinations cv
			ON cd.location=cv.location
			AND cd.date=cv.date
		WHERE cd.continent IS NOT NULL;
		--cannot use ORDER BY in views
SELECT *
FROM RollingTotalVaccinations;


	





