SELECT * FROM CensusProject..Dataset1

SELECT * FROM CensusProject..Dataset2

--Number of rows in our dataset

Select COUNT(*) FROM CensusProject..Dataset1

Select COUNT(*) FROM CensusProject..Dataset2

-- dataset for Bihar and Jharkhand

SELECT * FROM CensusProject..Dataset1 WHERE State='Jharkhand' or State='Bihar'

--Population of India

Select SUM(population) as Population From CensusProject..Dataset2

--Average growth of India

select AVG(growth)*100 as avg_growth from CensusProject..Dataset1

select State, ROUND(AVG(growth)*100,5) as avg_growth from CensusProject..Dataset1 Group By State Order by avg_growth DESC

--Average sex ratio of each state

select State, ROUND(AVG(Sex_Ratio),0) as avg_sex_ratio from CensusProject..Dataset1 Group By State Order By avg_sex_ratio DESC

-- average literacy rate

select State, ROUND(AVG(Literacy),5) as avg_literacy_rate from CensusProject..Dataset1 Group By State Order By avg_literacy_rate DESC;

select State, ROUND(AVG(Literacy),5) as avg_literacy_rate from CensusProject..Dataset1
Group By State having ROUND(AVG(Literacy),5)>90 Order By avg_literacy_rate DESC ;

--Top 5 State having highest growth rate

select TOP 5 State, ROUND(AVG(growth)*100,5) as avg_growth from CensusProject..Dataset1 Group By State Order by avg_growth DESC

-- Bottom 5 State with lowest sex ratio

select top 5 State, ROUND(AVG(Sex_Ratio),0) as avg_sex_ratio from CensusProject..Dataset1 Group By State Order By avg_sex_ratio ASC

-- temporary tables

--top state table

drop table if exists #topstates;
create table #topstates
( State nvarchar(255),
  literacy float);

insert into #topstates
select State, ROUND(AVG(Literacy),5) as avg_literacy_rate from CensusProject..Dataset1 Group By State;

select * from #topstates order by literacy desc;

--bottom state table

drop table if exists #bottomstates;
create table #bottomstates
( State nvarchar(255),
  literacy float);

insert into #bottomstates
select State, ROUND(AVG(Literacy),5) as avg_literacy_rate from CensusProject..Dataset1 Group By State;

select * from #bottomstates Order By literacy ASC;

-- union operator

select * from(select top 5 * from #topstates order by literacy desc) a
union
select * from (select top 5 * from #bottomstates order by literacy asc) b order by literacy desc;


--states starting with letter 'a'

select distinct State from CensusProject..Dataset1 where LOWER(State) like 'a%' or LOWER(State) like 'b%'

select distinct State from CensusProject..Dataset1 where LOWER(State) like 'a%' and LOWER(State) like '%s'

--Joining both tables

select a.District, a.State, a.Sex_Ratio, b.Population from CensusProject..Dataset1 a inner join CensusProject..Dataset2 b on a.district=b.district

-- getting number of males and females in a district

select c.District, c.State, ROUND(c.Population/(c.Sex_Ratio+1),0) as males, ROUND(c.Population*c.Sex_Ratio/(c.Sex_Ratio+1),0) as females from
(select a.District, a.State, a.Sex_Ratio/1000 as sex_ratio, b.Population from CensusProject..Dataset1 a inner join CensusProject..Dataset2 b on a.district=b.district
) c

-- getting number of males and females in state

select d.State, SUM(d.males) as total_males, SUM(d.females) as total_females from
(select c.District, c.State, ROUND(c.Population/(c.Sex_Ratio+1),0) as males, ROUND(c.Population*c.Sex_Ratio/(c.Sex_Ratio+1),0) as females from
(select a.District, a.State, a.Sex_Ratio/1000 as sex_ratio, b.Population from CensusProject..Dataset1 a inner join CensusProject..Dataset2 b on a.district=b.district
) c) d group by d.State;

--total literate and illiterate people in district

select c.district, c.state, ceiling(c.literacy_ratio*c.population) as literate_people, ceiling((1-c.literacy_ratio)*c.population) as illiterate_people from
(select a.District, a.State, a.Literacy/100 as literacy_ratio, b.Population from CensusProject..Dataset1 a inner join CensusProject..Dataset2 b on a.district=b.district) c


-- total literate and illiterate people in state

select d.State, SUM(d.literate_people) as total_literate_people, SUM(d.illiterate_people) as total_illiterate_people from
(select c.district, c.state, ceiling(c.literacy_ratio*c.population) as literate_people, ceiling((1-c.literacy_ratio)*c.population) as illiterate_people from
(select a.District, a.State, a.Literacy/100 as literacy_ratio, b.Population from CensusProject..Dataset1 a inner join CensusProject..Dataset2 b on a.district=b.district) c) d
group by d.State;

--district wise population in previous census

select district,state, ceiling(population/(1+growth)) as previous_census_population, population as current_census_population from
(select a.District, a.State, a.Growth, b.Population from CensusProject..Dataset1 a inner join CensusProject..Dataset2 b on a.district=b.district) c

--state wise population in previous census

select d.State, SUM(d.previous_census_population) as previous_census_population , sum(d.current_census_population) as current_census_population from
(select c.District,c.State, ceiling(c.Population/(1+c.Growth)) as previous_census_population, c.Population as current_census_population from
(select a.District, a.State, a.Growth, b.Population from CensusProject..Dataset1 a inner join CensusProject..Dataset2 b on a.district=b.district) c) d
group by d.State

-- previous census population of india 

select sum(e.previous_census_population) as previous_census_population, sum(e.current_census_population) as current_census_population from
(select d.State, SUM(d.previous_census_population) as previous_census_population , sum(d.current_census_population) as current_census_population from
(select c.District,c.State, ceiling(c.Population/(1+c.Growth)) as previous_census_population, c.Population as current_census_population from
(select a.District, a.State, a.Growth, b.Population from CensusProject..Dataset1 a inner join CensusProject..Dataset2 b on a.district=b.district) c) d
group by d.State) e;


--population vs area

select (j.total_area/j.previous_census_population) as previous_census_population_vs_area, (j.total_area/j.current_census_population) as
current_census_population_vs_area from (select g.*,i.total_area from (
select '1' as sl_no, f.* from 
(select sum(e.previous_census_population) as previous_census_population, sum(e.current_census_population) as current_census_population from
(select d.State, SUM(d.previous_census_population) as previous_census_population , sum(d.current_census_population) as current_census_population from
(select c.District,c.State, ceiling(c.Population/(1+c.Growth)) as previous_census_population, c.Population as current_census_population from
(select a.District, a.State, a.Growth, b.Population from CensusProject..Dataset1 a inner join CensusProject..Dataset2 b on a.district=b.district) c) d
group by d.State) e) f) g inner join (

select '1' as sl_no, h.* from(
select SUM(area_km2) as total_area from CensusProject..Dataset2) h) i on g.sl_no = i.sl_no) j;

--window
--top 3 districts from each state with highest literacy rate

select a.* from (
select district, state,literacy, RANK() over(partition by state order by literacy desc) as ranking from CensusProject..Dataset1) a
where a.ranking in (1,2,3) order by State

