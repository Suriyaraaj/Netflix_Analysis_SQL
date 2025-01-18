CREATE DATABASE IF NOT EXISTS suriya;
USE suriya;

CREATE TABLE IF NOT EXISTS net_fe (
    show_id      VARCHAR(10),          -- IDs are short alphanumeric strings
    typea         VARCHAR(15),          -- "Movie" or "TV Show"
    title        VARCHAR(500),         -- Titles up to 500 characters
    director     VARCHAR(300),         -- Names can be long
    cast         VARCHAR(1000),        -- Some casts are lengthy lists
    country      VARCHAR(200),         -- Country names and lists
    date_added   VARCHAR(25),          -- Dates in text form
    release_year INT,                  -- Release year
    rating       VARCHAR(10),          -- Ratings like "PG-13"
    duration     VARCHAR(15),          -- Durations like "2 Seasons"
    listed_in    VARCHAR(300),         -- Categories
    descriptions  VARCHAR(300)          -- Descriptions up to 300 characters
);

LOAD DATA LOCAL INFILE 'C:/Users/SURYA/Documents/sql lab/netflix_titles_cleaned.csv'
INTO TABLE net_fe
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    show_id, 
    typea, 
    title, 
    director, 
    cast, 
    country, 
    date_added, 
    release_year, 
    rating, 
    duration, 
    listed_in, 
    descriptions
)
SET
    release_year = NULLIF(release_year, ''),
    director = NULLIF(director, ''),
    cast = NULLIF(cast, ''),
    country = NULLIF(country, ''),
    rating = NULLIF(rating, ''),
    duration = NULLIF(duration, ''),
    date_added = NULLIF(date_added, '');
    
SELECT COUNT(*) AS total_rows FROM net_fe;
select * from net_fe;


-- 1. Count the Number of Movies vs TV Shows
-- Objective: Determine the distribution of content types on Netflix.
SELECT 
    typea,
    COUNT(*)
FROM net_fe
GROUP BY 1;     

-- 2.Find the Most Common Rating for Movies and TV Shows
-- Objective: Identify the most frequently occurring rating for each type of content.
SELECT 
    typea,                        
    rating,                       
    COUNT(*) AS count             
FROM 
    net_fe              
GROUP BY 
    typea, rating               
ORDER BY 
    count DESC                    
LIMIT 3;   
        
-- 3.  List All Movies Released in a Specific Year (e.g., 2021)
-- Objective: Retrieve all movies released in a specific year.
select *
from net_fe
where typea = 'Movie' and release_year= '2021';

-- 4.  Find the Top 5 Countries with the Most Content on Netflix
-- Objective: Identify the top 5 countries with the highest number of content items.
SELECT 
    country,                   
    COUNT(*) AS content_count   
FROM 
    net_fe 
    where 
    country is not null
GROUP BY 
    country                    
ORDER BY 
    content_count DESC         
LIMIT 5;       

-- 5 Identify the Longest Movie
-- Objective: Find the movie with the longest duration.
SELECT DISTINCT typea, duration
FROM net_fe
WHERE typea = 'Movie';

SELECT 
    title,                      
    duration,                   
    CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) AS duration_minutes  
FROM net_fe
WHERE typea = 'Movie'           -- Only include movies
  AND duration != ''            -- Exclude empty duration values
  AND duration IS NOT NULL      -- Exclude NULL values
ORDER BY duration_minutes DESC  
LIMIT 3;         
  --          explanation for the query substring --             
-- In the duration column, the duration of movies is given in the format XX mins, where XX is the number of minutes (e.g., 99 mins, 104 mins, etc.).
-- The function SUBSTRING_INDEX is used to extract the part before the first space, which is the numeric value (99, 104, etc.).
-- Then, we use CAST(... AS UNSIGNED) to convert this numeric value (which is initially a string) into an integer so we can sort it properly.
-- This whole step extracts the number of minutes, converts it to a number, and allows us to order the movies by their runtime, from the longest to the shortest.
               
-- 6.  Find Content Added in the Last 5 Years
-- Objective: Retrieve content added to Netflix in the last 5 years.
SELECT typea, title, country, date_added as last_five_year_release
FROM net_fe
WHERE STR_TO_DATE(date_added, '%M %d, %Y') >= CURDATE() - INTERVAL 5 YEAR;

-- 7. Find all Movies/TV Shows directed by 'Rajiv Chilaka'
-- Objective: List all content directed by 'Rajiv Chilaka'.
SELECT 
    title,                         
    typea,                          
    director                      
FROM 
    net_fe                         
WHERE 
    director = 'Rajiv Chilaka'    
    AND director != '\N'            
ORDER BY 
    title;             
    
-- 8. List All TV Shows with More Than 5 Seasons
-- Objective: Identify TV shows with more than 5 seasons.    
SELECT 
    title,                                   
    CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) AS duration_season 
FROM net_fe
WHERE typea = 'TV Show'           -- Only include movies
  AND duration != ''            -- Exclude empty duration values
  AND duration IS NOT NULL      -- Exclude NULL values
ORDER BY duration_season DESC  
LIMIT 3; 

-- 9. Count the Number of Content Items in Each Genre
-- Objective: Count the number of content items in each genre.
SELECT listed_in, COUNT(*) AS genre_count
FROM net_fe
GROUP BY listed_in
ORDER BY genre_count DESC;

-- 10 Find each year and the average numbers of content release in India on netflix.
-- return top 5 year with highest avg content release!
SELECT 
    country,
    release_year,
    COUNT(show_id) AS total_release,
    ROUND(
        (COUNT(show_id) / 
        (SELECT COUNT(show_id) FROM net_fe WHERE country = 'India')) * 100, 2 -- This part calculates the percentage of releases per year relative to all releases in India.
    ) AS avg_release
FROM net_fe
WHERE country = 'India'
GROUP BY country, release_year
ORDER BY avg_release DESC
LIMIT 5;

-- 11. List All Movies that are Documentaries
-- Objective: Retrieve all movies classified as documentaries.
SELECT typea, title, director, release_year,listed_in as genre
FROM net_fe
WHERE listed_in LIKE '%Documentaries';

-- 12. Find All Content Without a Director
-- Objective: List content that does not have a director.
SELECT * 
FROM net_fe
WHERE director IS NULL;
-- counting rows how many contents are without direstors
select count(*) 
from net_fe
where director is null;

-- 13. Find How Many Movies Actor 'Shah Rukh Khan' Appeared in the Last 10 Years
SELECT * 
FROM net_fe
WHERE cast LIKE '%Shah Rukh Khan%'
  AND release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10;

-- 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India
-- Objective: Identify the top 10 actors with the most appearances in Indian-produced movies.
SELECT actor, COUNT(*) AS movie_count
FROM (
    SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(cast, ',', 1), ',', -1)) AS actor -- TRIM(SUBSTRING_INDEX(...)) will only extract and count the first actor in the casts column
    FROM net_fe                                                                   -- The last , -1 in this context isn't really removing any commas if there aren't any more commas in the string you're working with (as with just "Salman Khan").
    WHERE country = 'India' 
      AND typea = 'Movie'
) AS actor_data
GROUP BY actor
ORDER BY movie_count DESC
LIMIT 10;


-- 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords
-- Objective: Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. 
-- Count the number of items in each category.
SELECT show_id,
       title,
       descriptions,
       CASE 
           WHEN descriptions LIKE '%Kill%' AND descriptions LIKE '%Violence%' THEN 'Kill & Violence'
           WHEN descriptions LIKE '%Kill%' THEN 'Kill'
           WHEN descriptions LIKE '%Violence%' THEN 'Violence'
           ELSE 'None' 
       END AS content_category
FROM net_fe
WHERE descriptions LIKE '%Kill%' OR descriptions LIKE '%Violence%';
