-- Viewing data in Dataset 1

SELECT 
       * 
FROM
       CensusProject..Dataset1;


-- Viewing data in Dataset 2

SELECT
       * 
FROM 
     CensusProject..Dataset2;

-- Number of rows in our dataset

SELECT 
      COUNT(*) 
FROM 
     CensusProject..Dataset1;

-------

SELECT 
       COUNT(*)
FROM 
       CensusProject..Dataset2;

-- Dataset for Bihar and Jharkhand

SELECT 
       *  
FROM 
     CensusProject..Dataset1 
WHERE 
     State='Jharkhand' OR State='Bihar';

-- Population of India

SELECT 
      SUM(population) AS Population 
FROM
      CensusProject..Dataset2;

--Average growth of India

SELECT 
      AVG(growth)*100 AS avg_growth 
FROM 
      CensusProject..Dataset1;

-------

SELECT 
       State, ROUND(AVG(growth)*100,5) AS avg_growth 
FROM 
       CensusProject..Dataset1 
GROUP BY 
         State 
ORDER BY 
         avg_growth DESC;

-- Average sex ratio of each state

SELECT 
        State, ROUND(AVG(Sex_Ratio),0) AS avg_sex_ratio 
FROM 
        CensusProject..Dataset1 
GROUP BY 
        State
ORDER BY 
         avg_sex_ratio DESC;

-- Average literacy rate

SELECT 
       State, ROUND(AVG(Literacy),5) AS avg_literacy_rate 
FROM 
        CensusProject..Dataset1 
GROUP BY 
         State
ORDER BY 
          avg_literacy_rate DESC;

------------

SELECT 
       State, ROUND(AVG(Literacy),5) AS avg_literacy_rate 
FROM 
       CensusProject..Dataset1
GROUP BY 
       State 
HAVING
       ROUND(AVG(Literacy),5)>90 
ORDER BY
        avg_literacy_rate DESC ;

--Top 5 State having highest growth rate

SELECT 
        TOP 5 State, ROUND(AVG(growth)*100,5) AS avg_growth 
FROM 
        CensusProject..Dataset1 
GROUP BY 
        State 
ORDER BY 
        avg_growth DESC;

-- Bottom 5 State with lowest sex ratio

SELECT 
        TOP 5 State, ROUND(AVG(Sex_Ratio),0) AS avg_sex_ratio 
FROM 
        CensusProject..Dataset1 
GROUP BY 
        State 
ORDER BY 
        avg_sex_ratio ASC;

-- Temporary Tables

--Top state table

DROP TABLE IF EXISTS #topstates;
CREATE TABLE #topstates
       ( State NVARCHAR(255),
         literacy FLOAT
	    );

INSERT INTO #topstates
            SELECT 
			      State, ROUND(AVG(Literacy),5) AS avg_literacy_rate 
			FROM 
			      CensusProject..Dataset1 
			GROUP BY 
			      State;

SELECT 
        * 
FROM 
        #topstates 
ORDER BY 
        literacy DESC;

--bottom state table

DROP TABLE IF EXISTS #bottomstates;
CREATE TABLE #bottomstates
       ( State NVARCHAR(255),
         literacy FLOAT
		);

INSERT INTO #bottomstates
            SELECT 
			         State, ROUND(AVG(Literacy),5) AS avg_literacy_rate 
			FROM 
			         CensusProject..Dataset1 
			GROUP BY 
			         State;

SELECT 
          * 
FROM 
          #bottomstates
ORDER BY
          literacy ASC;

-- UNION operator

SELECT 
       * 
FROM (
       SELECT 
              TOP 5 *
       FROM 
              #TOPstates 
       ORDER BY 
               literacy DESC
       ) a
UNION
SELECT 
         * 
FROM (
         SELECT 
                TOP 5 *
         FROM 
                #bottomstates 
         ORDER BY
                literacy ASC
      ) b 
ORDER BY 
         literacy DESC;


-- States starting with letter 'a' and 'b'

SELECT DISTINCT 
		State 
FROM 
		CensusProject..Dataset1 
WHERE 
		LOWER(State) LIKE 'a%' OR LOWER(State) LIKE 'b%';

-- States starting with letter 'a' and ending with 's'

SELECT DISTINCT 
		State 
FROM 
		CensusProject..Dataset1 
WHERE 
		LOWER(State) LIKE 'a%' and LOWER(State) LIKE '%s';

--Joining both tables

SELECT 
		a.District, a.State, a.Sex_Ratio, b.Population 
FROM
		CensusProject..Dataset1 a 
INNER JOIN
		CensusProject..Dataset2 b 
ON
		a.district=b.district;

-- Getting number of males and females in a district

SELECT
		c.District, c.State, 
		ROUND(c.Population/(c.Sex_Ratio+1),0) AS males,
		ROUND(c.Population*c.Sex_Ratio/(c.Sex_Ratio+1),0) AS females 
FROM (
		SELECT 
				a.District, a.State, a.Sex_Ratio/1000 as sex_ratio, b.Population 
		FROM 
				CensusProject..Dataset1 a 
		INNER JOIN
				CensusProject..Dataset2 b 
		ON
				a.district=b.district
	  ) c ;

-- Getting number of males and females in state

SELECT 
		d.State, SUM(d.males) AS total_males, SUM(d.females) AS total_females 
FROM (
		SELECT 
				c.District, c.State, 
				ROUND(c.Population/(c.Sex_Ratio+1),0) AS males, 
				ROUND(c.Population*c.Sex_Ratio/(c.Sex_Ratio+1),0) AS females 
		FROM (
				SELECT 
						a.District, a.State, a.Sex_Ratio/1000 AS sex_ratio, b.Population 
				FROM 
						CensusProject..Dataset1 a 
				INNER JOIN 
						CensusProject..Dataset2 b 
				ON
						a.district=b.district
		     ) c
	  ) d
GROUP BY 
		d.State;

--Total literate and illiterate people in district

SELECT 
		c.district, c.state, 
		CEILING(c.literacy_ratio*c.population) AS literate_people,
		CEILING((1-c.literacy_ratio)*c.population) AS illiterate_people 
FROM (
		SELECT 
				a.District, a.State, a.Literacy/100 AS literacy_ratio, b.Population 
		FROM 
				CensusProject..Dataset1 a 
		INNER JOIN
				CensusProject..Dataset2 b 
		ON 
				a.district=b.district
	 ) c;


-- Total literate and illiterate people in state

SELECT 
		d.State, 
		SUM(d.literate_people) AS total_literate_people, 
		SUM(d.illiterate_people) AS total_illiterate_people 
FROM (
		SELECT 
				c.district, c.state, 
				CEILING(c.literacy_ratio*c.population) AS literate_people, 
				CEILING((1-c.literacy_ratio)*c.population) AS illiterate_people 
		FROM (
				SELECT
						a.District, a.State, a.Literacy/100 AS literacy_ratio, b.Population 
				FROM 
						CensusProject..Dataset1 a 
				INNER JOIN 
						CensusProject..Dataset2 b 
				ON
						a.district=b.district
			 ) c
	   ) d
GROUP BY
		d.State;

-- District wise population in previous census

SELECT 
		district,state, 
		CEILING(population/(1+growth)) AS previous_census_population, 
		population AS current_census_population 
FROM (
		SELECT 
				a.District, a.State, a.Growth, b.Population 
		FROM 
				CensusProject..Dataset1 a 
		INNER JOIN 
				CensusProject..Dataset2 b 
		ON
				a.district=b.district
	  ) c;

-- State wise population in previous census

SELECT
		d.State, 
		SUM(d.previous_census_population) AS previous_census_population , 
		SUM(d.current_census_population) AS current_census_population 
FROM (
		SELECT 
				c.District,c.State, 
				CEILING(c.Population/(1+c.Growth)) AS previous_census_population, 
				c.Population AS current_census_population 
		FROM (
				SELECT
						a.District, a.State, a.Growth, b.Population
				FROM 
						CensusProject..Dataset1 a 
				INNER JOIN 
						CensusProject..Dataset2 b 
				ON 
						a.district=b.district
			 ) c
	  ) d
GROUP BY 
		d.State;

-- Previous census population of india 

SELECT
       SUM(e.previous_census_population) AS previous_census_population,
	   SUM(e.current_census_population) AS current_census_population 
FROM (
       SELECT
	          d.State, 
			  SUM(d.previous_census_population) AS previous_census_population , 
			  SUM(d.current_census_population) AS current_census_population 
	   FROM (
	          SELECT 
			         c.District,
					 c.State, 
					 CEILING(c.Population/(1+c.Growth)) AS previous_census_population,
					 c.Population as current_census_population
			  FROM (
			         SELECT 
					         a.District, a.State, a.Growth, b.Population 
					 FROM 
					         CensusProject..Dataset1 a 
					 INNER JOIN 
					         CensusProject..Dataset2 b
					 ON a.district=b.district
					) c
			) d
       GROUP BY d.State
	 ) e;


-- Population VS Area

SELECT 
      (j.total_area/j.previous_census_population) AS previous_census_population_vs_area, 
      (j.total_area/j.current_census_population) AS current_census_population_vs_area 
FROM (
      SELECT
            g.*,i.total_area
      FROM (
            SELECT 
                  '1' AS sl_no, f.* 
            FROM (
                   SELECT
                          SUM(e.previous_census_population) AS previous_census_population, 
						  SUM(e.current_census_population) AS current_census_population
                   FROM ( 
                          SELECT 
                                 d.State, 
								 SUM(d.previous_census_population) AS previous_census_population ,
								 SUM(d.current_census_population) AS current_census_population 
                          FROM (
                                 SELECT 
                                        c.District,
										c.State, 
										CEILING(c.Population/(1+c.Growth)) AS previous_census_population, 
										c.Population AS current_census_population 
                                 FROM ( 
                                        SELECT 
                                               a.District, a.State, a.Growth, b.Population 
                                        FROM 
                                               CensusProject..Dataset1 a 
                                        INNER JOIN 
                                                CensusProject..Dataset2 b
                                        ON a.district=b.district
									   ) c
								) d
                           GROUP BY d.State
						 ) e
					) f
			) g 
         INNER JOIN (
                      SELECT 
                             '1' AS sl_no, h.* 
                      FROM (
                             SELECT
                                    SUM(area_km2) AS total_area 
                             FROM 
                                   CensusProject..Dataset2
						    ) h
					) i
         ON g.sl_no = i.sl_no
	   ) j;

-- Window
-- Top 3 districts from each state with highest literacy rate

SELECT 
a.* 
FROM (
       SELECT 
              district, state,literacy, RANK() 
       OVER(PARTITION BY state ORDER BY literacy DESC) AS ranking 
       FROM 
              CensusProject..Dataset1
      ) a
WHERE 
      a.ranking in (1,2,3) ORDER BY State;

