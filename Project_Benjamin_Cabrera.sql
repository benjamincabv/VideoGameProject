-- This query displays the top 5 rows with the purpose of showing all columns and their type of information.
USE CAP2761C_Project

SELECT TOP 5 * 
FROM Video_Games_1980_2016;


-----------------------------------------------------------------------------------------------------------------------------------------------
-- This query creates a new table for key Column Genres.
USE CAP2761C_Project

CREATE TABLE VD_Genres (
    Genre_ID INT IDENTITY(1,1) PRIMARY KEY,
    Genre_Name NVARCHAR(100) UNIQUE
);


-- This query inserts the data from the Main Table into the new table VD_Genres.
USE CAP2761C_Project

INSERT INTO VD_Genres (Genre_Name)
SELECT DISTINCT Genre 
FROM Video_Games_1980_2016 
WHERE Genre IS NOT NULL;


-----------------------------------------------------------------------------------------------------------------------------------------------
-- This query creates a new table for key Column Platforms.
USE CAP2761C_Project

CREATE TABLE VD_Platforms (
    Platform_ID INT IDENTITY(1,1) PRIMARY KEY,
    Platform_Name NVARCHAR(100) UNIQUE
);


-- This query inserts the data from the Main Table into the new table VD_Platforms.
USE CAP2761C_Project

INSERT INTO VD_Platforms (Platform_Name)
SELECT DISTINCT Platform 
FROM Video_Games_1980_2016 
WHERE Platform IS NOT NULL;


-----------------------------------------------------------------------------------------------------------------------------------------------
-- This query creates a new table for key Column Publishers.
USE CAP2761C_Project

CREATE TABLE VD_Publishers (
    Publisher_ID INT IDENTITY(1,1) PRIMARY KEY,
    Publisher_Name NVARCHAR(255) UNIQUE
);


-- This query inserts the data from the Main Table into the new table VD_Publishers.
USE CAP2761C_Project

INSERT INTO VD_Publishers (Publisher_Name)
SELECT DISTINCT Publisher 
FROM Video_Games_1980_2016 
WHERE Publisher IS NOT NULL;


-----------------------------------------------------------------------------------------------------------------------------------------------
-- These queries alter the Main Table to Add Foreign Key Columns.
USE CAP2761C_Project

ALTER TABLE Video_Games_1980_2016 ADD Genre_ID INT;


USE CAP2761C_Project

ALTER TABLE Video_Games_1980_2016 ADD Platform_ID INT;


USE CAP2761C_Project

ALTER TABLE Video_Games_1980_2016 ADD Publisher_ID INT;


-----------------------------------------------------------------------------------------------------------------------------------------------
-- This query inserts the ID columns with JOINs.
USE CAP2761C_Project

UPDATE vg
SET Genre_ID = g.Genre_ID
FROM Video_Games_1980_2016 vg
JOIN VD_Genres g ON vg.Genre = g.Genre_Name;


USE CAP2761C_Project

UPDATE vg
SET Platform_ID = p.Platform_ID
FROM Video_Games_1980_2016 vg
JOIN VD_Platforms p ON vg.Platform = p.Platform_Name;


USE CAP2761C_Project

UPDATE vg
SET Publisher_ID = pub.Publisher_ID
FROM Video_Games_1980_2016 vg
JOIN VD_Publishers pub ON vg.Publisher = pub.Publisher_Name;


-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
--SECTION 1: JOINs

-- This query displays the Total Sales by Genre and Platform.

USE CAP2761C_Project

SELECT 
    g.Genre_Name,
    p.Platform_Name,
    ROUND(SUM(vg.Global_Sales), 1) AS Total_Global_Sales
FROM Video_Games_1980_2016 vg
JOIN VD_Genres g ON vg.Genre_ID = g.Genre_ID
JOIN VD_Platforms p ON vg.Platform_ID = p.Platform_ID
GROUP BY g.Genre_Name, p.Platform_Name
ORDER BY Total_Global_Sales DESC;


-- This query displays the Top 5 Gaming Platforms and their Global Sales.

USE CAP2761C_Project

SELECT TOP 5
    p.Platform_Name,
    ROUND(SUM(vg.Global_Sales), 1) AS Total_Global_Sales
FROM Video_Games_1980_2016 vg
JOIN VD_Platforms p ON vg.Platform_ID = p.Platform_ID
GROUP BY p.Platform_Name
ORDER BY Total_Global_Sales DESC;


-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
--SECTION 2: SUBQUERIES

-- This query displays how many games have been released by the Top 5 Gaming Platforms during 1980-2016.

USE CAP2761C_Project

SELECT 
    p.Platform_Name,
    COUNT(*) AS Total_Games
FROM Video_Games_1980_2016 vg
JOIN VD_Platforms p ON vg.Platform_ID = p.Platform_ID
WHERE p.Platform_Name IN (
    SELECT TOP 5 p2.Platform_Name
    FROM Video_Games_1980_2016 vg2
    JOIN VD_Platforms p2 ON vg2.Platform_ID = p2.Platform_ID
    GROUP BY p2.Platform_Name
    ORDER BY SUM(vg2.Global_Sales) DESC
)
GROUP BY p.Platform_Name
ORDER BY Total_Games DESC;


-- This query displays the Top 3 Games of each Platform during 1980-2016.

USE CAP2761C_Project

;WITH Ranked_Games_By_Platform AS (
    SELECT 
        vg.Name,
        p.Platform_Name,
        pub.Publisher_Name,
        vg.Year_of_Release,
        vg.Global_Sales,
        RANK() OVER (PARTITION BY p.Platform_Name ORDER BY vg.Global_Sales DESC) AS Game_Rank
    FROM Video_Games_1980_2016 vg
    JOIN VD_Platforms p ON vg.Platform_ID = p.Platform_ID
    JOIN VD_Publishers pub ON vg.Publisher_ID = pub.Publisher_ID
)
SELECT Name, Platform_Name, Publisher_Name, Year_of_Release, Global_Sales
FROM Ranked_Games_By_Platform
WHERE Game_Rank <= 3
ORDER BY Platform_Name, Game_Rank;


-- This query displays the Top 3 Games of each Genre during 1980-2016.

USE CAP2761C_Project

;WITH Ranked_Games_By_Genre AS (
    SELECT 
        vg.Name,
        g.Genre_Name,
        p.Platform_Name,
        pub.Publisher_Name,
        vg.Year_of_Release,
        vg.Global_Sales,
        RANK() OVER (PARTITION BY g.Genre_Name ORDER BY vg.Global_Sales DESC) AS Game_Rank
    FROM Video_Games_1980_2016 vg
    JOIN VD_Genres g ON vg.Genre_ID = g.Genre_ID
    JOIN VD_Platforms p ON vg.Platform_ID = p.Platform_ID
    JOIN VD_Publishers pub ON vg.Publisher_ID = pub.Publisher_ID
)
SELECT Name, Genre_Name, Platform_Name, Publisher_Name, Year_of_Release, Global_Sales
FROM Ranked_Games_By_Genre
WHERE Game_Rank <= 3
ORDER BY Genre_Name, Game_Rank;


-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
--SECTION 3: TABLE EXPRESSIONS

-- This query displays the most popular Genre per Platform during 1980-2016.

USE CAP2761C_Project

;WITH Genre_Sales AS (
    SELECT 
        p.Platform_Name,
        g.Genre_Name,
        ROUND(SUM(vg.Global_Sales), 1) AS Total_Global_Sales,
        RANK() OVER (PARTITION BY p.Platform_Name ORDER BY SUM(vg.Global_Sales) DESC) AS Genre_Rank
    FROM Video_Games_1980_2016 vg
    JOIN VD_Platforms p ON vg.Platform_ID = p.Platform_ID
    JOIN VD_Genres g ON vg.Genre_ID = g.Genre_ID
    GROUP BY p.Platform_Name, g.Genre_Name
)
SELECT Platform_Name, Genre_Name, Total_Global_Sales
FROM Genre_Sales
WHERE Genre_Rank = 1
ORDER BY Platform_Name;


-- This query displays the Top 3 Genres per Region during 2006-2016

USE CAP2761C_Project

;WITH Genre_Regional_Sales AS (
    SELECT 
        g.Genre_Name,
        ROUND(SUM(vg.NA_Sales), 1) AS NA_Sales,
        ROUND(SUM(vg.EU_Sales), 1) AS EU_Sales,
        ROUND(SUM(vg.JP_Sales), 1) AS JP_Sales
    FROM Video_Games_1980_2016 vg
    JOIN VD_Genres g ON vg.Genre_ID = g.Genre_ID
    WHERE vg.Year_of_Release BETWEEN 2006 AND 2016
    GROUP BY g.Genre_Name
),
Ranked AS (
    SELECT Genre_Name, 'NA' AS Region, NA_Sales AS Regional_Sales,
           RANK() OVER (PARTITION BY 'NA' ORDER BY NA_Sales DESC) AS Genre_Rank
    FROM Genre_Regional_Sales
    UNION ALL
    SELECT Genre_Name, 'EU', EU_Sales,
           RANK() OVER (PARTITION BY 'EU' ORDER BY EU_Sales DESC)
    FROM Genre_Regional_Sales
    UNION ALL
    SELECT Genre_Name, 'JP', JP_Sales,
           RANK() OVER (PARTITION BY 'JP' ORDER BY JP_Sales DESC)
    FROM Genre_Regional_Sales
)
SELECT *
FROM Ranked
WHERE Genre_Rank <= 3
ORDER BY Region, Genre_Rank;


-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
--SECTION 4: SET OPERATORS

-- This query displays the Top 3 Platforms per Region during 2006-2016.

USE CAP2761C_Project

;WITH Platform_Regional_Sales AS (
    SELECT 
        p.Platform_Name,
        ROUND(SUM(vg.NA_Sales), 1) AS NA_Sales,
        ROUND(SUM(vg.EU_Sales), 1) AS EU_Sales,
        ROUND(SUM(vg.JP_Sales), 1) AS JP_Sales
    FROM Video_Games_1980_2016 vg
    JOIN VD_Platforms p ON vg.Platform_ID = p.Platform_ID
    WHERE vg.Year_of_Release BETWEEN 2006 AND 2016
    GROUP BY p.Platform_Name
),
Ranked AS (
    SELECT Platform_Name, 'NA' AS Region, NA_Sales AS Regional_Sales,
           RANK() OVER (PARTITION BY 'NA' ORDER BY NA_Sales DESC) AS Platform_Rank
    FROM Platform_Regional_Sales
    UNION ALL
    SELECT Platform_Name, 'EU', EU_Sales,
           RANK() OVER (PARTITION BY 'EU' ORDER BY EU_Sales DESC)
    FROM Platform_Regional_Sales
    UNION ALL
    SELECT Platform_Name, 'JP', JP_Sales,
           RANK() OVER (PARTITION BY 'JP' ORDER BY JP_Sales DESC)
    FROM Platform_Regional_Sales
)
SELECT *
FROM Ranked
WHERE Platform_Rank <= 3
ORDER BY Region, Platform_Rank;


-- This query displays the Top 3 Publishers per Region and how many games they released during 1980-2016.

USE CAP2761C_Project

;WITH Publisher_Regional AS (
    SELECT 
        pub.Publisher_Name,
        COUNT(*) AS Total_Games,
        ROUND(SUM(vg.NA_Sales), 1) AS NA_Sales,
        ROUND(SUM(vg.EU_Sales), 1) AS EU_Sales,
        ROUND(SUM(vg.JP_Sales), 1) AS JP_Sales
    FROM Video_Games_1980_2016 vg
    JOIN VD_Publishers pub ON vg.Publisher_ID = pub.Publisher_ID
    WHERE vg.Year_of_Release BETWEEN 2006 AND 2016
    GROUP BY pub.Publisher_Name
),
Ranked AS (
    SELECT Publisher_Name, Total_Games, 'NA' AS Region, NA_Sales AS Regional_Sales,
           RANK() OVER (PARTITION BY 'NA' ORDER BY NA_Sales DESC) AS Publisher_Rank
    FROM Publisher_Regional
    UNION ALL
    SELECT Publisher_Name, Total_Games, 'EU', EU_Sales,
           RANK() OVER (PARTITION BY 'EU' ORDER BY EU_Sales DESC)
    FROM Publisher_Regional
    UNION ALL
    SELECT Publisher_Name, Total_Games, 'JP', JP_Sales,
           RANK() OVER (PARTITION BY 'JP' ORDER BY JP_Sales DESC)
    FROM Publisher_Regional
)
SELECT *
FROM Ranked
WHERE Publisher_Rank <= 3
ORDER BY Region, Publisher_Rank;


-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
--SECTION 5: DATA MODIFICATIONS

-- This query renames one of the Genres.

USE CAP2761C_Project

UPDATE VD_Genres
SET Genre_Name = 'Miscellaneous'
WHERE Genre_Name = 'Misc';


-- This query drops the three created columns Genre_ID, Publisher_ID, and Platform_ID from the Main Table.

USE CAP2761C_Project

ALTER TABLE Video_Games_1980_2016
DROP COLUMN Genre_ID, Publisher_ID, Platform_ID;