SELECT *
FROM BellaBeat..dailyActivity_merged$

--Check for nulls

SELECT *
FROM BellaBeat..dailyActivity_merged$
WHERE COALESCE(ActivityDate,TotalSteps,TotalDistance,TrackerDistance,ModeratelyActiveDistance,
				LightActiveDistance,SedentaryActiveDistance,VeryActiveDistance,FairlyActiveMinutes,
				LightlyActiveMinutes,SedentaryMinutes,Calories) IS NULL

--Reviewing the time period per participant 
SELECT MIN(ActivityDate),MAX(ActivityDate)
FROM BellaBeat..dailyActivity_merged$

SELECT DISTINCT(Id), COUNT(Id) AS total
FROM BellaBeat..dailyActivity_merged$
GROUP BY Id
ORDER BY COUNT(Id) DESC

--Checking for number of participants who completed the time period
SELECT DISTINCT(Id), COUNT(Id) AS total
FROM BellaBeat..dailyActivity_merged$
GROUP BY Id
ORDER BY COUNT(Id) DESC

SELECT *
FROM BellaBeat..dailyActivity_merged$
WHERE Id IN (4057192912,5577150313)
ORDER BY Id, ActivityDate

--Removing time from the date column
SELECT ActivityDate
FROM BellaBeat..dailyActivity_merged$

ALTER TABLE BellaBeat..dailyActivity_merged$
ADD DateOfActivity date

UPDATE BellaBeat..dailyActivity_merged$
SET DateOfActivity = CONVERT(date, ActivityDate)

ALTER TABLE BellaBeat..dailyActivity_merged$
DROP COLUMN ActivityDate

--Check for duplicates on table 2
SELECT *
FROM BellaBeat..hourlyCalories_merged$

SELECT DISTINCT(Id), COUNT(Id) AS total
FROM BellaBeat..hourlyCalories_merged$
GROUP BY Id
ORDER BY COUNT(Id) DESC

SELECT *
FROM BellaBeat..hourlySteps_merged$

SELECT *
FROM BellaBeat..sleepDay_merged$

--Removing time from the date column
SELECT SleepDay
FROM BellaBeat..sleepDay_merged$

ALTER TABLE BellaBeat..sleepDay_merged$
ADD DayOfSleep date

UPDATE BellaBeat..sleepDay_merged$
SET DayOfSleep = CONVERT(date, SleepDay)

ALTER TABLE BellaBeat..sleepDay_merged$
DROP COLUMN SleepDay

SELECT *
FROM BellaBeat..weightLogInfo_merged$

SELECT DISTINCT(Id), COUNT(Id)
FROM BellaBeat..weightLogInfo_merged$
GROUP BY Id
ORDER BY COUNT(Id) DESC

--E.D.A
--Joining sleep and daily activities tables
SELECT a.Id,a.TotalDistance, a.TotalSteps,s.TotalSleepRecords,a.ModeratelyActiveDistance,a.LightActiveDistance,s.TotalMinutesAsleep,s.TotalTimeInBed,s.DayOfSleep
FROM BellaBeat..dailyActivity_merged$ AS a
JOIN BellaBeat..sleepDay_merged$ AS s
ON a.Id = s.Id
AND a.DateOfActivity = s.DayOfSleep
WHERE a.TotalDistance > 6.03861986084438
ORDER BY a.TotalDistance DESC

--average distances and steps covered
SELECT AVG(a.ModeratelyActiveDistance), AVG(a.TotalDistance), AVG(TotalSteps)
FROM BellaBeat..dailyActivity_merged$ AS a
JOIN BellaBeat..sleepDay_merged$ AS s
ON a.Id = s.Id
AND a.DateOfActivity = s.DayOfSleep


--Amount of time spent on the bed without sleeping
WITH sleepCount AS
(
SELECT Id, TotalMinutesAsleep, TotalTimeInBed, (TotalTimeInBed-TotalMinutesAsleep) AS TimeAwakeOnBed
FROM BellaBeat..sleepDay_merged$
GROUP BY Id, TotalMinutesAsleep, TotalTimeInBed
)
SELECT Id, SUM(TimeAwakeOnBed) OnBed, SUM(TotalTimeInBed) Asleep, SUM(TimeAwakeOnBed)/SUM(TotalTimeInBed)*100 PercentageOnBedActive
FROM sleepCount
GROUP BY Id
ORDER BY PercentageOnBedActive DESC

--Joining the three tables with hourly data
SELECT 
		c.Id, c.Calories, i.TotalIntensity, i.AverageIntensity, s.StepTotal,
		CONVERT (DATE, c.ActivityHour) AS Date, CONVERT (TIME(0), c.ActivityHour) AS Time --splitting the datetime column
FROM BellaBeat..hourlyCalories_merged$ c
JOIN BellaBeat..hourlyIntensities_merged$ i
ON c.Id = i.Id
AND c.ActivityHour = i.ActivityHour
JOIN BellaBeat..hourlySteps_merged$ s
ON i.Id = s.Id
AND i.ActivityHour = s.ActivityHour

--creating a view with a table showing the data from the 3 hourly tables and time of day
CREATE VIEW Data_Hourly AS
WITH HourlyData AS
(	SELECT 
		c.Id, c.Calories, i.TotalIntensity, i.AverageIntensity, s.StepTotal,
		CONVERT (DATE, c.ActivityHour) AS Date, CONVERT (TIME(0), c.ActivityHour) AS Time --splitting the datetime column
FROM BellaBeat..hourlyCalories_merged$ c
JOIN BellaBeat..hourlyIntensities_merged$ i
ON c.Id = i.Id
AND c.ActivityHour = i.ActivityHour
JOIN BellaBeat..hourlySteps_merged$ s
ON i.Id = s.Id
AND i.ActivityHour = s.ActivityHour
)
SELECT *, 
		CASE WHEN Time BETWEEN '07:00:00' AND '11:00:00'
			THEN 'Morning'
			WHEN Time BETWEEN '12:00:00' AND '16:00:00'
			THEN 'Afternoon'
			WHEN Time BETWEEN '17:00:00' AND '19:00:00'
			THEN 'Evening'
			ELSE 'Night'
			END AS TimeOfDay
FROM HourlyData;

SELECT *
FROM BellaBeat..weightLogInfo_merged$

SELECT *
FROM BellaBeat..dailyActivity_merged$
