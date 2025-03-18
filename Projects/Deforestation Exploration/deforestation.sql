-- Create a View called “forestation” by joining all three tables - forest_area, land_area, and regions

CREATE VIEW forestation AS
SELECT
    f.country_code,
    f.country_name,
    f.year,
    f.forest_area_sqkm,
    l.total_area_sq_mi,
    r.region,
    r.income_group,
    l.total_area_sq_mi * 2.59 AS total_area_sqkm,
    f.forest_area_sqkm / (l.total_area_sq_mi * 2.59) * 100 AS percent_of_land_area_that_is_forest
FROM
    forest_area f
JOIN
    land_area l ON f.country_code = l.country_code AND f.year = l.year
JOIN
    regions r ON f.country_code = r.country_code;

    -- a. What was the total forest area (in sq km) of the world in 1990? Please keep in mind that you can use the country record denoted as “World" in the region table.
    --
    -- b. What was the total forest area (in sq km) of the world in 2016? Please keep in mind that you can use the country record in the table is denoted as “World.”
    --
    -- c. What was the change (in sq km) in the forest area of the world from 1990 to 2016?
    --
    -- d. What was the percent change in forest area of the world between 1990 and 2016?
    --

    WITH sub AS (
        SELECT year, country_name, region, forest_area_sqkm
        FROM forestation
        WHERE country_name = 'World' AND (year = 2016 OR year = 1990)
    )
    SELECT
        s1.region,
        s1.forest_area_sqkm AS forest_area_sqkm_2016,
        s2.forest_area_sqkm AS forest_area_sqkm_1990,
        s2.forest_area_sqkm - s1.forest_area_sqkm AS drop_in_forest_area,
        (s2.forest_area_sqkm - s1.forest_area_sqkm) * 100 / s2.forest_area_sqkm AS percentage_drop_in_forest_area
    FROM
        sub s1
    JOIN
        sub s2
    ON
        s1.region = s2.region AND s1.year > s2.year;

    --
    -- e. If you compare the amount of forest area lost between 1990 and 2016, to which country's total area in 2016 is it closest to?
    --
    WITH sub AS (
        SELECT year, country_name, region, forest_area_sqkm
        FROM forestation
        WHERE country_name = 'World' AND (year = 2016 OR year = 1990)
    ),
    sub2 AS (
        SELECT
            s1.region,
            s1.forest_area_sqkm AS forest_area_sqkm_2016,
            s2.forest_area_sqkm AS forest_area_sqkm_1990,
            s2.forest_area_sqkm - s1.forest_area_sqkm AS drop_in_forest_area,
            (s2.forest_area_sqkm - s1.forest_area_sqkm) * 100 / s2.forest_area_sqkm AS percentage_drop_in_forest_area
        FROM
            sub s1
        JOIN
            sub s2
        ON
            s1.region = s2.region AND s1.year > s2.year
    )

    SELECT
        year,
        country_name,
        total_area_sqkm,
        ABS(total_area_sqkm - (SELECT drop_in_forest_area FROM sub2)) AS absolute_diff
    FROM
        forestation
    WHERE
        year = 2016
    ORDER BY
        absolute_diff
    LIMIT 1;



    Part 2 - Regional Outlook

    -- Create a table that shows the Regions and their percent forest area (sum of forest area divided by the sum of land area) in 1990 and 2016. (Note that 1 sq mi = 2.59 sq km).
    -- Based on the table you created:

    SELECT
        region,
        SUM(forest_area_sqkm) AS forest_area_sqkm,
        SUM(total_area_sqkm) AS total_area_sqkm,
        ROUND(
            CAST((SUM(forest_area_sqkm) / SUM(total_area_sqkm)) * 100 AS NUMERIC),
            2
        ) AS percent_forest_area
    FROM
        forestation
    WHERE
        year = 2016
    GROUP BY
        region
    ORDER BY
        percent_forest_area DESC;

    -- a. What was the percent forest of the entire world in 2016? Which region had the HIGHEST percent forest in 2016, and which had the LOWEST, to 2 decimal places?
    --
    SELECT
        region,
        SUM(forest_area_sqkm) AS forest_area_sqkm,
        SUM(total_area_sqkm) AS total_area_sqkm,
        ROUND(
            CAST((SUM(forest_area_sqkm) / SUM(total_area_sqkm)) * 100 AS NUMERIC),
            2
        ) AS percent_forest_area
    FROM
        forestation
    WHERE
        year = 2016 AND region = 'World'
    GROUP BY
        region

    -- b. What was the percent forest of the entire world in 1990? Which region had the HIGHEST percent forest in 1990, and which had the LOWEST, to 2 decimal places?
    --
    SELECT
        region,
        SUM(forest_area_sqkm) AS forest_area_sqkm,
        SUM(total_area_sqkm) AS total_area_sqkm,
        ROUND(
            CAST((SUM(forest_area_sqkm) / SUM(total_area_sqkm)) * 100 AS NUMERIC),
            2
        ) AS percent_forest_area
    FROM
        forestation
    WHERE
        year = 1990 AND region = 'World'
    GROUP BY
        region

    -- c. Based on the table you created, which regions of the world DECREASED in forest area from 1990 to 2016?
    --

    WITH sub AS (
        SELECT
            year,
            region,
            forest_area_sqkm,
            total_area_sqkm
        FROM
            forestation
        WHERE
            year = 2016 OR year = 1990
    ),
    sub2 AS (
        SELECT
            s1.region,
            s1.forest_area_sqkm AS forest_area_sqkm_2016,
            s1.total_area_sqkm AS total_area_sqkm_2016,
            s2.forest_area_sqkm AS forest_area_sqkm_1990,
            s2.total_area_sqkm AS total_area_sqkm_1990
        FROM
            sub s1
        JOIN
            sub s2 ON s1.region = s2.region AND s1.year > s2.year
    )

    SELECT
        region,
        ROUND(
            CAST(SUM(forest_area_sqkm_1990) * 100 / SUM(total_area_sqkm_1990) AS NUMERIC),
            2
        ) AS perc_forest_area_1990,
        ROUND(
            CAST(SUM(forest_area_sqkm_2016) * 100 / SUM(total_area_sqkm_2016) AS NUMERIC),
            2
        ) AS perc_forest_area_2016
    FROM
        sub2
    GROUP BY
        region
    ORDER BY
        perc_forest_area_1990 DESC;



    -- Part 3 - Country-Level Detail
    --
    -- Success Stories

    WITH sub AS (
        SELECT
            year,
            country_name,
            region,
            forest_area_sqkm
        FROM
            forestation
        WHERE
            (year = 2016 OR year = 1990) AND
            region != 'World' AND
            forest_area_sqkm IS NOT NULL
    )

    SELECT
        s1.country_name,
        s1.forest_area_sqkm AS forest_area_sqkm_2016,
        s2.forest_area_sqkm AS forest_area_sqkm_1990,
        ROUND(CAST((s1.forest_area_sqkm - s2.forest_area_sqkm) AS NUMERIC), 2) AS increase_in_forest_area,
        ROUND(CAST(100 * ((s1.forest_area_sqkm - s2.forest_area_sqkm) / s2.forest_area_sqkm) AS NUMERIC), 2) AS perc_change_in_forest_area
    FROM
        sub s1
    JOIN
        sub s2 ON s1.country_name = s2.country_name AND s1.year > s2.year
    ORDER BY
        increase_in_forest_area DESC;


    WITH sub AS (
        SELECT
            year,
            country_name,
            region,
            forest_area_sqkm
        FROM
            forestation
        WHERE
            (year = 2016 OR year = 1990) AND
            region != 'World' AND
            forest_area_sqkm IS NOT NULL
    )

    SELECT
        s1.country_name,
        s1.forest_area_sqkm AS forest_area_sqkm_2016,
        s2.forest_area_sqkm AS forest_area_sqkm_1990,
        ROUND(CAST((s1.forest_area_sqkm - s2.forest_area_sqkm) AS NUMERIC), 2) AS increase_in_forest_area,
        ROUND(CAST(100 * ((s1.forest_area_sqkm - s2.forest_area_sqkm) / s2.forest_area_sqkm) AS NUMERIC), 2) AS perc_change_in_forest_area
    FROM
        sub s1
    JOIN
        sub s2 ON s1.country_name = s2.country_name AND s1.year > s2.year
    ORDER BY
        perc_change_in_forest_area DESC;


    a. Which 5 countries saw the largest amount decrease in forest area from 1990 to 2016? What was the difference in forest area for each?
    WITH sub AS (
        SELECT
            year,
            country_name,
            region,
            forest_area_sqkm
        FROM
            forestation
        WHERE
            (year = 2016 OR year = 1990) AND
            region != 'World' AND
            forest_area_sqkm IS NOT NULL
    )

    SELECT
        s1.country_name,
        s1.region,
        ROUND(CAST((s2.forest_area_sqkm - s1.forest_area_sqkm) AS NUMERIC), 2) AS change_in_forest_area
    FROM
        sub s1
    JOIN
        sub s2 ON s1.country_name = s2.country_name AND s1.year > s2.year
    ORDER BY
        change_in_forest_area DESC
    LIMIT 5;


    -- b. Which 5 countries saw the largest percent decrease in forest area from 1990 to 2016? What was the percent change to 2 decimal places for each?
    --
    WITH sub AS (
        SELECT
            year,
            country_name,
            region,
            forest_area_sqkm
        FROM
            forestation
        WHERE
            (year = 2016 OR year = 1990) AND
            region != 'World' AND
            forest_area_sqkm IS NOT NULL
    )

    SELECT
        s1.country_name,
        s1.region,
        ROUND(CAST((s2.forest_area_sqkm - s1.forest_area_sqkm) AS NUMERIC), 2) AS change_in_forest_area,
        ROUND(CAST(100 * ((s2.forest_area_sqkm - s1.forest_area_sqkm) / s2.forest_area_sqkm) AS NUMERIC), 2) AS per_change_in_forest_area
    FROM
        sub s1
    JOIN
        sub s2 ON s1.country_name = s2.country_name AND s1.year > s2.year
    ORDER BY
        per_change_in_forest_area DESC
    LIMIT 5;

    -- c. If countries were grouped by percent forestation in quartiles, which group had the most countries in it in 2016?
    --
    WITH sub AS (
        SELECT
            year,
            country_name,
            region,
            forest_area_sqkm * 100 / total_area_sqkm AS percent_forestation
        FROM
            forestation
        WHERE
            year = 2016
    ),
    sub2 AS (
        SELECT
            country_name,
            CASE
                WHEN percent_forestation > 75 THEN 'Fourth'
                WHEN percent_forestation > 50 THEN 'Third'
                WHEN percent_forestation > 25 THEN 'Second'
                ELSE 'First'
            END AS quartile_category
        FROM
            sub
        WHERE
            percent_forestation IS NOT NULL
    )

    SELECT
        DISTINCT quartile_category,
        COUNT(country_name) OVER(PARTITION BY quartile_category) AS number_of_countries
    FROM
        sub2
    ORDER BY
        number_of_countries DESC;

    -- d. List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016.
    --
    WITH sub AS (
        SELECT
            year,
            country_name,
            region,
            ROUND(CAST(forest_area_sqkm * 100 / total_area_sqkm AS NUMERIC), 2) AS percent_forestation
        FROM
            forestation
        WHERE
            year = 2016
    ),
    sub2 AS (
        SELECT
            country_name,
            region,
            percent_forestation,
            CASE
                WHEN percent_forestation > 75 THEN 'Fourth'
                WHEN percent_forestation > 50 THEN 'Third'
                WHEN percent_forestation > 25 THEN 'Second'
                ELSE 'First'
            END AS quartile_category
        FROM
            sub
        WHERE
            percent_forestation IS NOT NULL
    )

    SELECT
        country_name,
        region,
        percent_forestation
    FROM
        sub2
    WHERE
        quartile_category = 'Fourth'
    ORDER BY
        percent_forestation DESC;

    -- e. How many countries had a percent forestation higher than the United States in 2016?
    --
    WITH sub AS (
        SELECT
            year,
            country_name,
            region,
            ROUND(CAST(forest_area_sqkm * 100 / total_area_sqkm AS NUMERIC), 2) AS percent_forestation
        FROM
            forestation
        WHERE
            year = 2016
    ),
    sub2 AS (
        SELECT
            country_name,
            percent_forestation,
            CASE
                WHEN percent_forestation > 75 THEN 'Fourth'
                WHEN percent_forestation > 50 THEN 'Third'
                WHEN percent_forestation > 25 THEN 'Second'
                ELSE 'First'
            END AS quartile_category
        FROM
            sub
        WHERE
            percent_forestation IS NOT NULL
    )

    SELECT
        COUNT(*)
    FROM
        sub2
    WHERE
        percent_forestation > (
            SELECT
                percent_forestation
            FROM
                sub2
            WHERE
                country_name = 'United States'
        );
