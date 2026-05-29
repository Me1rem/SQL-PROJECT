use TDI

-- For this analysis, I have 6 primary tables
select * from [elec-fossil-nuclear-renewables]  -- This is our main table
select * from [change-energy-consumption]
select * from [electricity-generation] 
select * from [primary-energy-cons]
select * from [share-of-the-population-with-access-to-electricity] 
select * from [GDP-Per-Capita-usd] 

-- This is a supplementary table, it contains list of all countries in the world
--with their 3-digit codes and their continents
select * from [country_codes_and_continents] 


--DATA CLEANING AND PREPARATION
-- 1. Handle Missing or Inconsistent Data
-- Fill missing values with appropriate defaults or remove rows with critical missing data

-- First for our main table - elec-fossil-nuclear-renewables table
UPDATE [elec-fossil-nuclear-renewables]
SET Electricity_from_renewables_TWh_adapted_for_visualization_of_chart_elec_fossil_nuclear_renewables = 0
WHERE Electricity_from_renewables_TWh_adapted_for_visualization_of_chart_elec_fossil_nuclear_renewables IS NULL;

UPDATE [elec-fossil-nuclear-renewables]
SET Electricity_from_nuclear_TWh_adapted_for_visualization_of_chart_elec_fossil_nuclear_renewables = 0
WHERE Electricity_from_nuclear_TWh_adapted_for_visualization_of_chart_elec_fossil_nuclear_renewables IS NULL;

UPDATE [elec-fossil-nuclear-renewables]
SET Electricity_from_fossil_fuels_TWh_adapted_for_visualization_of_chart_elec_fossil_nuclear_renewables = 0
WHERE Electricity_from_fossil_fuels_TWh_adapted_for_visualization_of_chart_elec_fossil_nuclear_renewables IS NULL;

-- For our second table
UPDATE [change-energy-consumption]
SET Annual_change_in_primary_energy_consumption = 0
WHERE Annual_change_in_primary_energy_consumption IS NULL;

-- For our third table
UPDATE [electricity-generation]
SET Electricity_generation_TWh = 0
WHERE Electricity_generation_TWh IS NULL;

-- For our fourth table
UPDATE [primary-energy-cons]
SET Primary_energy_consumption_TWh = 0
WHERE Primary_energy_consumption_TWh IS NULL;

-- For our fifth table
UPDATE [share-of-the-population-with-access-to-electricity]
SET Access_to_electricity_of_population = 0
WHERE Access_to_electricity_of_population IS NULL;

-- For our Sixth table
--I have to do some transformations on the GDPpercapita table
--because the table is in wide format (the years data are in columns), 
--I need to convert it to long format (years in rows instead of columns)
-- Step 1: Declare variables for dynamic SQL
DECLARE @sql NVARCHAR(MAX);
DECLARE @columns NVARCHAR(MAX);

-- Dynamically get all year columns
SELECT @columns = STRING_AGG(QUOTENAME(name), ', ')
FROM sys.columns
WHERE object_id = OBJECT_ID('[GDP-Per-Capita-usd]') 
  AND (name LIKE '19%' OR name LIKE '20%'); 

-- Build dynamic unpivot query
SET @sql = '
    -- Create the table to store unpivoted data
    CREATE TABLE GDPData (
        Country NVARCHAR(255),
        Code NVARCHAR(255),
        Year NVARCHAR(4),
        [GDP per Capita] DECIMAL(18, 2)
    );

    -- Insert unpivoted data into the table
    INSERT INTO GDPData (Country, Code, Year, [GDP per Capita])
    SELECT 
        Country, 
        Code, 
        Year, 
        COALESCE(TRY_CONVERT(DECIMAL(18, 2), REPLACE(TRIM([GDP per Capita]), '','', ''.'')), 0) AS [GDP per Capita]
    FROM 
        [GDP-Per-Capita-usd]
    UNPIVOT (
        [GDP per Capita] FOR Year IN (' + @columns + ')
    ) AS unpvt;
';

-- Execute the dynamic SQL to create the table
EXEC sp_executesql @sql;

-- Query the new table 
SELECT * FROM GDPData;


-- For our supplementary table
DELETE FROM [country_codes_and_continents]
WHERE Continent IS NULL;


--2. Remove Duplicates
-- Remove duplicate rows based on primary key (Entity, Code, Year)
-- For the first table
ALTER TABLE [elec-fossil-nuclear-renewables] 
ADD id INT IDENTITY(1,1) PRIMARY KEY; -- First, I add a new id column to uniquely identify each row

DELETE FROM [elec-fossil-nuclear-renewables]
WHERE id NOT IN (
    SELECT MIN(id)
    FROM [elec-fossil-nuclear-renewables]
    GROUP BY Entity, Code, Year
);


-- For the second table
ALTER TABLE [change-energy-consumption] 
ADD id INT IDENTITY(1,1) PRIMARY KEY; -- First, I add a new id column to uniquely identify each row

DELETE FROM [change-energy-consumption]
WHERE id NOT IN (
    SELECT MIN(id)
    FROM [change-energy-consumption]
    GROUP BY Entity, Code, Year
);


-- For the third table
ALTER TABLE [electricity-generation] 
ADD id INT IDENTITY(1,1) PRIMARY KEY; -- First, I add a new id column to uniquely identify each row

DELETE FROM [electricity-generation]
WHERE id NOT IN (
    SELECT MIN(id)
    FROM [electricity-generation]
    GROUP BY Entity, Code, Year
);


-- For the fourth table
ALTER TABLE [primary-energy-cons] 
ADD id INT IDENTITY(1,1) PRIMARY KEY; -- First, I add a new id column to uniquely identify each row

DELETE FROM [primary-energy-cons]
WHERE id NOT IN (
    SELECT MIN(id)
    FROM [primary-energy-cons]
    GROUP BY Entity, Code, Year
);


-- For the fifth table
ALTER TABLE [share-of-the-population-with-access-to-electricity]
ADD id INT IDENTITY(1,1) PRIMARY KEY; -- First, I add a new id column to uniquely identify each row

DELETE FROM [share-of-the-population-with-access-to-electricity]
WHERE id NOT IN (
    SELECT MIN(id)
    FROM [share-of-the-population-with-access-to-electricity]
    GROUP BY Entity, Code, Year
);


-- For the sixth table
ALTER TABLE GDPData
ADD id INT IDENTITY(1,1) PRIMARY KEY; -- First, I add a new id column to uniquely identify each row

DELETE FROM GDPData
WHERE id NOT IN (
    SELECT MIN(id)
    FROM GDPData
    GROUP BY Country, Code, Year
);


-- For the supplementary table, I would not do this operation as all rows are unique with no duplicates


--3. Format and Structure Data
-- Ensure all columns have appropriate data types
-- For [elec-fossil-nuclear-renewables] table
ALTER TABLE [elec-fossil-nuclear-renewables]
ALTER COLUMN Electricity_from_renewables_TWh_adapted_for_visualization_of_chart_elec_fossil_nuclear_renewables DECIMAL(18, 2);

ALTER TABLE [elec-fossil-nuclear-renewables]
ALTER COLUMN Electricity_from_nuclear_TWh_adapted_for_visualization_of_chart_elec_fossil_nuclear_renewables DECIMAL(18, 2);

ALTER TABLE [elec-fossil-nuclear-renewables]
ALTER COLUMN Electricity_from_fossil_fuels_TWh_adapted_for_visualization_of_chart_elec_fossil_nuclear_renewables DECIMAL(18, 2);

-- For [change-energy-consumption] table
ALTER TABLE [change-energy-consumption]
ALTER COLUMN Annual_change_in_primary_energy_consumption DECIMAL(18, 2);

-- For [electricity-generation] table
ALTER TABLE [electricity-generation]
ALTER COLUMN Electricity_generation_TWh DECIMAL(18, 2);

-- For [primary-energy-cons] table
ALTER TABLE [primary-energy-cons]
ALTER COLUMN Primary_energy_consumption_TWh DECIMAL(18, 2);

-- For [share-of-the-population-with-access-to-electricity] table
ALTER TABLE [share-of-the-population-with-access-to-electricity]
ALTER COLUMN Access_to_electricity_of_population DECIMAL(18, 2);

-- For [GDP-Per-Capita-usd] table 
-- The [GDP Per Capita] is already in Decimal format;

-- For [country_codes_and_continents] table
-- No numeric columns to alter, as it contains only text (Country, Country_Code, Continent)



-- Define Relationships
--Primary Key: Our primary keys are Entity, Code, Year in the [elec-fossil-nuclear-renewables] table
--Foreign Keys: Entity and Year are the foreign keys in the other tables,
--except the [country_codes_and_continents] table where the primary keys are Country and Country_Code.


-- Some Exploratory Data Analysis
WITH CleanedData AS (		-- creating a CTE for single use
    SELECT 
        e.Entity,
        e.Code,
		cc.Continent,
        e.Year,
        e.Electricity_from_renewables_TWh_adapted_for_visualization_of_chart_elec_fossil_nuclear_renewables AS Electricity_from_Renewables,
        e.Electricity_from_nuclear_TWh_adapted_for_visualization_of_chart_elec_fossil_nuclear_renewables AS Electricity_from_Nuclear,
        e.Electricity_from_fossil_fuels_TWh_adapted_for_visualization_of_chart_elec_fossil_nuclear_renewables AS Electricity_from_Fossil_Fuels,
        c.Annual_change_in_primary_energy_consumption,
        g.Electricity_generation_TWh,
        p.[GDP Per Capita] AS GDP_Per_Capita_USD,
        t.Primary_energy_consumption_TWh,
        s.Access_to_electricity_of_population
    FROM 
        [elec-fossil-nuclear-renewables] e
    LEFT JOIN 
        [change-energy-consumption] c ON e.Code = c.Code AND e.Year = c.Year
    LEFT JOIN 
        [electricity-generation]  g ON e.Code = g.Code AND e.Year = g.Year
    LEFT JOIN 
        GDPData p ON e.Code = p.Code AND e.Year = p.Year
    LEFT JOIN 
        [primary-energy-cons] t ON e.Code = t.Code AND e.Year = t.Year
    LEFT JOIN 
        [country_codes_and_continents] cc ON e.Code = cc.Country_Code
    LEFT JOIN 
        [share-of-the-population-with-access-to-electricity] s ON e.Code = s.Code AND e.Year = s.Year
    WHERE 
        e.code IS NOT NULL AND
		e.Year BETWEEN 2000 AND 2022 --I want to analyze data from 2000 to 2022

)

SELECT 
    Year,
    AVG(Electricity_from_Renewables) AS Avg_Electricity_from_Renewables,
    AVG(Electricity_from_Nuclear) AS Avg_Electricity_from_Nuclear,
    AVG(Electricity_from_Fossil_Fuels) AS Avg_Electricity_from_Fossil_Fuels,
    AVG(Annual_change_in_primary_energy_consumption) AS Avg_Annual_Change,
    AVG(Electricity_generation_TWh) AS Avg_Electricity_Generation,
    AVG([GDP_Per_Capita_USD]) AS Avg_GDP_per_capita_USD,
    AVG(Access_to_electricity_of_population) AS Avg_Access_to_Electricity
FROM 
    CleanedData
GROUP BY 
    Year
ORDER BY 
    Year;



-- KEY QUESTIONS FOR MAIN ANALYSIS

--(1) What is the trend of electricity generation per continent for the period considered?
--(2) How does the percentage of people with access to electricity correlate 
--with electricity generation from renewables, nuclear, and fossil fuels?
--(3) What is the trend in electricity generation from renewables, 
--nuclear, and fossil fuels over the years for each entity?
--(4) What are the top 10 countries with the highest electricity generation in 2022
--(5) What is the relationship between GDP Per Capita (USD) and Electricity Generation (TWh)/Population Access for 2022
--(6) How has the annual change in primary energy consumption impacted electricity generation 
--from renewables, nuclear, and fossil fuels?

-- First, I create a view for reuse in answering the questions
CREATE VIEW CleanedTable AS 
    SELECT 
        e.Entity AS Country,
        e.Code,
		cc.Continent,
        e.Year,
        e.Electricity_from_renewables_TWh_adapted_for_visualization_of_chart_elec_fossil_nuclear_renewables AS Electricity_from_Renewables_TWh,
        e.Electricity_from_nuclear_TWh_adapted_for_visualization_of_chart_elec_fossil_nuclear_renewables AS Electricity_from_Nuclear_TWh,
        e.Electricity_from_fossil_fuels_TWh_adapted_for_visualization_of_chart_elec_fossil_nuclear_renewables AS Electricity_from_Fossil_Fuels_TWh,
        COALESCE(c.Annual_change_in_primary_energy_consumption,0) AS Annual_change_in_primary_energy_consumption,
        g.Electricity_generation_TWh,
        COALESCE(p.[GDP Per Capita],0) AS GDP_Per_Capita_USD,
        t.Primary_energy_consumption_TWh,
        COALESCE(s.Access_to_electricity_of_population, 0) AS "Access_to_electricity_%_of_population"
    FROM 
        [elec-fossil-nuclear-renewables] e
	INNER JOIN 
        [country_codes_and_continents] cc ON e.Code = cc.Country_Code
    LEFT JOIN 
        [change-energy-consumption] c ON e.Code = c.Code AND e.Year = c.Year
    LEFT JOIN 
        [electricity-generation]  g ON e.Code = g.Code AND e.Year = g.Year
    LEFT JOIN 
        GDPData p ON e.Code = p.Code AND e.Year = p.Year
    LEFT JOIN 
        [primary-energy-cons] t ON e.Code = t.Code AND e.Year = t.Year
    LEFT JOIN 
        [share-of-the-population-with-access-to-electricity] s ON e.Code = s.Code AND e.Year = s.Year
    WHERE 
        e.Code IS NOT NULL AND 
		e.Year BETWEEN 2000 AND 2022; --I want to analyze data from 2000 to 2022




--(1) What is the trend of electricity generation per continent for the period considered?
SELECT 
    Year,
	Continent,
	sum(Electricity_generation_TWh) as Electricity_generation_TWh
FROM 
    CleanedTable
Group by Year, Continent
Order by Year;


--(2) How does the percentage of people with access to electricity correlate 
--with electricity generation from renewables, nuclear, and fossil fuels?
SELECT 
    Country,
	Continent,
    Year,
    Electricity_from_renewables_TWh,
    Electricity_from_nuclear_TWh,
    Electricity_from_fossil_fuels_TWh,
    "Access_to_electricity_%_of_population",
	CASE 
        WHEN "Access_to_electricity_%_of_population" > 90 THEN 'High Access'
        WHEN "Access_to_electricity_%_of_population" BETWEEN 50 AND 90 THEN 'Medium Access'
        ELSE 'Low Access'
    END AS Access_Level
FROM 
	CleanedTable;

--(3) What is the trend in electricity generation from renewables, 
--nuclear, and fossil fuels over the years for each entity?
SELECT 
    Year,
    sum(Electricity_from_renewables_TWh) as Electricity_from_renewables_TWh,
    sum(Electricity_from_nuclear_TWh) as Electricity_from_nuclear_TWh,
    sum(Electricity_from_fossil_fuels_TWh) as Electricity_from_fossil_fuels_TWh
FROM 
	CleanedTable
Group by Year
Order by Year;


--(4) What are the top 10 countries with the highest electricity generation in 2022

SELECT TOP 10 
	Country,
	Electricity_generation_TWh,
	"Access_to_electricity_%_of_population"
FROM
	CleanedTable
WHERE
	Year = '2022'
ORDER BY Electricity_generation_TWh DESC;

--(5) What is the relationship between GDP Per Capita (USD) and Electricity 
--Generation (TWh)/Population Access for 2022
SELECT 
    Country,
	Continent,
    Year,
    Electricity_generation_TWh,
	"Access_to_electricity_%_of_population",
    GDP_Per_Capita_USD
FROM 
	CleanedTable
WHERE
	Year = '2022'
ORDER BY GDP_Per_Capita_USD DESC;

--(6) How has the annual change in primary energy consumption impacted electricity generation 
--from renewables, nuclear, and fossil fuels?

SELECT 
    Country,
	Continent,
    Year,
    Electricity_from_renewables_TWh,
    Electricity_from_nuclear_TWh,
    Electricity_from_fossil_fuels_TWh,
    Annual_change_in_primary_energy_consumption
FROM 
	CleanedTable;
