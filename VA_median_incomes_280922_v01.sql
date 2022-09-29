/* Preparation for Data on Virginia Housing, Income and Population by Locality
Data to be visualized in Tableau (https://public.tableau.com/app/profile/zeometer)
Data sourced from the Virginia Data Portal (http://data.virginia.gov) and US Census Bureau (https://www.census.gov/)
Data current as of December 2020

Skills used - views, joins, 
*/

/* PREPARING DATA ON MEDIAN INCOMES */

-- SELECT *
-- FROM VAMedianIncome;

-- creating view to edit values and generate visualization

GO
CREATE VIEW VAEditedMedianIncome
AS
    SELECT county
    , B19013_001E AS overallmedianincome
    , B19013A_001E AS whitemedianincome
    , B19013B_001E AS blackmedianincome1
    , B19013C_001E AS indigenousmedianincome
    , B19013D_001E AS asianmedianincome
    , B19013E_001E AS hawaiianpimedianincome
    , B19013F_001E AS otherracemedianincome
    , B19013G_001E AS multiracialmedianincome
    , B19013H_001E AS whitenonhispanicmedianincome
    , B19013I_001E AS hispanicmedianincome
    FROM VAMedianIncome
GO

-- adjusting value of -666666666 (designated as unavailable or statistically insigificant in data source) to 0

UPDATE VAEditedMedianIncome
SET blackmedianincome1 = REPLACE(blackmedianincome1, '-666666666', '0')
SET indigenousmedianincome = REPLACE(indigenousmedianincome, '-666666666', '0')
SET asianmedianincome = REPLACE(asianmedianincome, '-666666666', '0')
SET hawaiianpimedianincome = REPLACE(hawaiianpimedianincome, '-666666666', '0')
SET otherracemedianincome = REPLACE(otherracemedianincome, '-666666666', '0')
SET multiracialmedianincome = REPLACE(multiracialmedianincome, '-666666666', '0')
SET whitenonhispanicmedianincome = REPLACE(whitenonhispanicmedianincome, '-666666666', '0')
SET hispanicmedianincome = REPLACE(hispanicmedianincome, '-666666666', '0')

/* 1. Median Incomes for Every County in VA, Organized by Race/Ethnicity */

SELECT *
FROM VAEditedMedianIncome;

-- joining data from census bureau to get population

SELECT inc.county
    , pop.population
    , overallmedianincome
    , whitemedianincome
    , blackmedianincome1
    , indigenousmedianincome
    , asianmedianincome
    , hawaiianpimedianincome
    , otherracemedianincome
    , multiracialmedianincome
    , whitenonhispanicmedianincome
    , hispanicmedianincome
FROM VAEditedMedianIncome inc JOIN VAPopulation2020 pop 
    ON inc.county = pop.county

-- creating views for visualizations in Tableau

GO
CREATE VIEW VAPopVsDetailedIncome
AS
SELECT inc.county
    , pop.population
    , overallmedianincome
    , whitemedianincome
    , blackmedianincome1
    , indigenousmedianincome
    , asianmedianincome
    , hawaiianpimedianincome
    , otherracemedianincome
    , multiracialmedianincome
    , whitenonhispanicmedianincome
    , hispanicmedianincome
FROM VAEditedMedianIncome inc JOIN VAPopulation2020 pop 
    ON inc.county = pop.county
GO

/* 2. VA Population vs Median Incomes, by Locality and Race/Ethnicity */

SELECT *
FROM VAPopVsDetailedIncome

GO
CREATE VIEW VAPopVsMedianIncome
AS
SELECT inc.county
    , pop.population
    , overallmedianincome
FROM VAEditedMedianIncome inc JOIN VAPopulation2020 pop 
    ON inc.county = pop.county
GO

/* 3. VA Population vs Median Incomes, by Locality */

SELECT *
FROM VAPopVsMedianIncome

/* PREPARING DATA ON HOUSING COUNTS */

-- SELECT *
-- FROM VAUnaffordableHousing

-- creating view for visualizations in Tableau
-- counts represent number of units where 30% or more is spent on housing, given the following income grades:
-- 'grade E' = below $20,000,
-- 'grade D' = $20,000 to $34,999,
-- 'grade C' = $35,000 to $49,999,
-- 'grade B' = $50,000 to $74,999,
-- 'grade A' = $75,000 and above


-- creating views for visualization in Tableau

GO
CREATE VIEW VAEditedUnafforableHousing
AS
    SELECT county
    , B25106_002E AS totalowneroccupiedhousing
    , B25106_006E AS ownerincomelevel1
    , B25106_010E AS ownerincomelevel2
    , B25106_014E AS ownerincomelevel3
    , B25106_018E AS ownerincomelevel4
    , B25106_022E AS ownerincomelevel5
    , B25106_024E AS totalrenteroccupiedhousing
    , B25106_028E AS renterincomelevel1
    , B25106_032E AS renterincomelevel2
    , B25106_036E AS renterincomelevel3
    , B25106_040E AS renterincomelevel4
    , B25106_044E AS renterincomelevel5
    FROM VAUnaffordableHousing
GO

/* 4. VA Counts of Households Spending 30% mr More on Housing, by Locality and Income Level */

SELECT *
FROM VAEditedUnafforableHousing

GO
CREATE VIEW VAOwnerOccupiedHousing
AS
    SELECT county
    , B25106_002E AS totalowneroccupiedhousing
    , B25106_006E AS ownerincomelevel1
    , B25106_010E AS ownerincomelevel2
    , B25106_014E AS ownerincomelevel3
    , B25106_018E AS ownerincomelevel4
    , B25106_022E AS ownerincomelevel5
FROM VAUnaffordableHousing
GO

GO
CREATE VIEW VARenterOccupiedHousing
AS
    SELECT  county
    , B25106_024E AS totalrenteroccupiedhousing
    , B25106_028E AS renterincomelevel1
    , B25106_032E AS renterincomelevel2
    , B25106_036E AS renterincomelevel3
    , B25106_040E AS renterincomelevel4
    , B25106_044E AS renterincomelevel5
    FROM VAUnaffordableHousing
GO

/* 5. VA Counts of House Owners Spending 30% or More of Income in Housing */

SELECT *
FROM VAOwnerOccupiedHousing

/* 6. VA Counts of Renters Spending 30% or More of Income in Housing */

SELECT *
FROM VARenterOccupiedHousing

-- creating reference table for income levels

CREATE TABLE VAIncomeLevels (
    incomelevel varchar(255),
    incomerange varchar(255)
)

INSERT INTO VAIncomeLevels
VALUES ('level1', 'below $20,000')
, ('level2', '$20,000 - $34,999')
, ('level3', '$35,000 - $49,999')
, ('level4', '$50,000 - $74,999')
, ('level5', 'above $75,000')

