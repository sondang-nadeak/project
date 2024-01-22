-- PLEASE READ THIS GUIDENCE FIRST
-- I have two tables that i am gonna use, both CovidDeaths table and CovidVaccionations table
-- 1st step, data cleaning
-- 2nd step, exploratory data analyst
-- The results you can find in the last section
-- Ok, here we go!

-- DATA CLEANING
-- Let's choose columns that we need from CovidDeaths table
WITH SelectedTable AS(
	SELECT continent, date, location, total_cases, new_cases, total_deaths, new_deaths, population
	FROM CovidDeaths
),

-- Changing type data of date column to date
-- Changing the negative numeric values to postive in the new_cases column
-- Replacing the null values to 0 in the total_deaths and new_deaths columns
-- Elliminating the white space and null values of continent and new_cases columns
TableCleaning1 AS(
	SELECT continent, STR_TO_DATE(`date`,'%m/%d/%Y') date, location, COALESCE(ABS(new_cases),0) new_cases, COALESCE(ABS(new_deaths),0) new_deaths, population
	FROM SelectedTable
	WHERE continent !='' AND new_cases IS NOT NULL 
	ORDER BY 5
),

-- Adding a new column filled with the total number of new_cases column
-- A new total_cases column added because of the old one contains negative values
TableCleaning2 AS(
	SELECT  continent, date, location, SUM(new_cases) OVER(PARTITION BY location ORDER BY date) total_cases, new_cases, SUM(new_deaths) OVER(PARTITION BY location ORDER BY date) total_deaths, new_deaths, population
	FROM TableCleaning1 
	ORDER BY location, date
),

-- EXPLORATORY DATA 
-- Here is the cleaned table i am gonna use to do EDA
CovidDeathTable AS(
	Select continent, date, location AS country, total_cases, new_cases, total_deaths, new_deaths, population
	FROM TableCleaning2
),

-- Adding some new columns to make it easier to understand
-- There are a lot of insights in this table, let's explore it in the next sections
CountryGroupTable AS(
	SELECT continent, country, MAX(total_cases) total_case, population, MAX(total_cases/population)*100 case_percentage, MAX(total_deaths) total_death, MAX(total_deaths)/MAX(total_cases)*100 death_ratio
	FROM CovidDeathTable
	GROUP BY 1,2,4
	ORDER BY 3 DESC
),

-- Showing countries with the highest case
-- United States has the highest case and has the highest death as well
-- Most countries are from Europe
HighestCase AS (
	SELECT continent, country, total_case FROM CountryGroupTable
	LIMIT 10
),

-- Showing total_cases compares to population
-- Andorra has the highest percentage case compares to population, more than 17% its population got infection
CasePercentage AS (
	SELECT continent, country, total_case, population, case_percentage
	FROM CountryGroupTable
	ORDER BY 5 DESC
	LIMIT 10
),

-- Mexico is the thirth country with the highest total death, even hough it is not included in the top 10 countries with the highest case, it seems they are bad at dealing/ handling the covid
HighestDeath AS (
	SELECT country, total_death
	FROM CountryGroupTable 
	ORDER BY 2 DESC
),

-- Vanuatu is the country with the higest death ratio at 25%
DeathRatio AS(
	SELECT country, total_case, total_death, death_ratio
	FROM CountryGroupTable
	ORDER BY 4 DESC
),

-- Let's break down thing by continent
-- Europe has the highest total death
HighestDeathContinent AS(
SELECT continent, SUM(total_death) total_death
FROM CountryGroupTable
GROUP BY 1
ORDER BY 2 DESC
),

-- Showing total_case, etc globally
-- More than 3 milliion or 0.041% of world's pupulation died during in this periode 
TotalGlobally AS(
	SELECT SUM(total_case) global_total_case, SUM(total_death) total_death, SUM(population), (SUM(total_death)/SUM(population))*100 death_percentage 
	FROM(
		SELECT continent, country, MAX(total_cases) total_case, MAX(total_deaths) total_death, population
		FROM CovidDeathTable
		GROUP BY 1,2,5
	) a
),

-- Showing monthly new_total_case,  new_total_death for each country
-- if the result is ordered by death_ratio, there will be show that Suriname, Vanuatu adn Fiji are the countries have the highest monthly death ratio
MonthlyTotal AS(
	SELECT continent, DATE_FORMAT(`date`,'%Y/%m/01') date, country, SUM(new_cases) new_total_case, SUM(new_deaths) new_total_death, COALESCE(SUM(new_deaths)/SUM(new_cases)*100,0) death_ratio
	FROM CovidDeathTable
	GROUP BY 3,2,1
	ORDER BY 6 DESC, 5 DESC
	LIMIT 10
),

-- Showing 10 countries with the highest daily case and daily death ratio
-- Iran has the highest daily death ratio at 100% followed by Guyana
DailyDeathRatio AS(
	SELECT date, continent, country, total_cases, total_deaths, total_deaths/total_cases*100 death_ratio
	FROM CovidDeathTable
	ORDER BY 6 DESC
	LIMIT 10
),

-- Showing the highest case in a day for each country
-- India has reached a record high of nearly half a million case in a day followed by USA and France
CaseRecord AS(
	SELECT date, country, new_cases new_case_a_day, population
	FROM CovidDeathTable
	WHERE (country, population, new_cases) IN (SELECT country, population, MAX(new_cases) FROM CovidDeathTable GROUP BY 1,2)
	ORDER BY new_cases DESC
	LIMIT 10
),

-- Showing the highest death in a day for each country
-- Even though India has the highest case in a day, but United States even got the highest death wit a total number 4,474 deaths on 2021-01-12
DeathRecord AS(
	SELECT date, country, new_deaths new_death_a_day, population
	FROM CovidDeathTable
	WHERE (country, population, new_deaths) IN (SELECT country, population, MAX(new_deaths) FROM CovidDeathTable GROUP BY 1,2)
	ORDER BY new_deaths DESC
	LIMIT 10
),

-- DATA CLEANING
-- Let's choose columns that we need from CovidVaccinations table
-- Changing data type of date column to date
CovidVaccinationTable AS (
	SELECT continent, location, STR_TO_DATE(date,'%m/%d/%Y') date, new_vaccinations  
	FROM CovidVaccinations 
	WHERE continent !='' 
),
 
-- Let's join CovidDeathTable with CovidVaccinationTable
JoinTable AS(
	SELECT cd.continent, cd.country, cd.date, cd.total_cases, cd.total_deaths, cd.population, cv.new_vaccinations, SUM(cv.new_vaccinations)OVER(PARTITION BY cv.location) total_vaccinations
	  FROM
	    CovidDeathTable cd
	    INNER JOIN CovidVaccinationTable cv
	    ON cd.country=cv.location
	    AND cd.date=cv.date
),

-- Showing total vaccination compares to population for each country 
-- Israel is the highest percentage vaccination at more than 100%, perhaps this country has given its citizens 2nd vaccination
VaccinationPercentage AS (
	SELECT continent, country, MAX(total_cases) total_case, MAX(total_deaths) total_death, total_vaccinations, population, total_vaccinations/population*100 vaccination_percentage
	FROM JoinTable
	GROUP BY 1,2,5,6
	ORDER bY 7 DESC
)



-- DONE..!! now just replace the name of the table below to see the informations/insights u want, thank you..

SELECT * FROM HighestDeathContinent
