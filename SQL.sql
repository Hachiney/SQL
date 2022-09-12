-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE people.weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst LIKE '% %'
  ORDER BY namefirst, namelast
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, avg(height) AS avgheight, COUNT(*) AS count
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, avg(height) AS avgheight, COUNT(*) AS count
  FROM people
  GROUP BY birthyear
  HAVING avgheight > 70
  ORDER BY birthyear
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT namefirst, namelast, people.playerid AS playerid, yearid
  FROM people INNER JOIN halloffame 
              ON people.playerid = halloffame.playerid
  WHERE inducted = 'Y'
  ORDER BY yearid DESC, playerid 
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT namefirst, namelast, people.playerid AS playerid, schools.schoolid AS schoolid, yearid
  FROM people JOIN halloffame
    ON people.playerid = halloffame.playerid
    JOIN CollegePlaying
      ON halloffame.playerid = CollegePlaying.playerid
      JOIN schools 
        ON CollegePlaying.schoolid = schools.schoolid
  WHERE schools.schoolState = 'CA' AND halloffame.inducted = 'Y'
  ORDER BY yearid DESC, schoolid, playerid
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT people.playerid AS playerid, namefirst, namelast, CollegePlaying.schoolid AS schoolid
  FROM people JOIN halloffame ON people.playerid = halloffame.playerid
    LEFT JOIN CollegePlaying ON halloffame.playerid = CollegePlaying.playerid
  WHERE halloffame.inducted = 'Y'
  ORDER BY playerid DESC, schoolid
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid, p.namefirst, p.namelast, b.yearid, 
         MAX(CAST((b.H - b.H2B - b.H3B - b.HR) + 2 * H2B + 3 * H3B + 4 * HR AS FLOAT) / b.AB) AS slg
  FROM people as p JOIN batting AS b ON p.playerid = b.playerid
  GROUP BY p.playerid, b.yearid
  HAVING b.AB >50
  ORDER BY slg DESC, b.yearid, p.playerid
  LIMIT 10 
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT p.playerid, p.namefirst, p.namelast, 
        (CAST(sum(b.H - b.H2B - b.H3B - b.HR) + sum(2 * b.H2B) + sum(3 * b.H3B) + sum(4 * b.HR) AS FLOAT) / sum(b.AB)) AS lslg
  FROM people as p JOIN batting AS b ON p.playerid = b.playerid
  GROUP BY p.playerid
  HAVING SUM(b.AB) > 50
  ORDER BY lslg DESC, p.playerid
  LIMIT 10 
;
-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT p.namefirst, p.namelast, 
        (CAST(sum(b.H - b.H2B - b.H3B - b.HR) + sum(2 * b.H2B) + sum(3 * b.H3B) + sum(4 * b.HR) AS FLOAT) / sum(b.AB)) AS lslg
  FROM people as p JOIN batting AS b ON p.playerid = b.playerid
  GROUP BY p.playerid
  HAVING SUM(b.AB) > 50 
          AND lslg >(SELECT (CAST(sum(b.H - b.H2B - b.H3B - b.HR) + sum(2 * b.H2B) + sum(3 * b.H3B) + sum(4 * b.HR) AS FLOAT) / sum(b.AB)) AS compareSlg
                     FROM people AS p JOIN batting AS b ON p.playerid = b.playerid
                     WHERE p.playerid = 'mayswi01'
                     GROUP BY p.playerid
                     )
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary) AS min, MAX(salary) AS max, AVG(salary) AS avg
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  WITH min_max(minSal, maxSal, diff) AS (SELECT MIN(salary) AS minSal, 
                                                MAX(salary) AS maxSal, 
                                                (MAX(salary) - MIN(salary))/ 10 AS diff 
                                        FROM salaries WHERE yearid = 2016),
       --salaries2016 AS (SELECT * FROM salaries WHERE yearid =2016),
       binTbl(bin, salary, yearid) AS (SELECT (CAST(((salary - minSal) / diff) AS INT)) AS bin, salary, yearid
                               FROM salaries, min_max
                               WHERE yearid = 2016)                        
  SELECT binid, (min_max.minSal + min_max.diff * binid) AS low, (min_max.minSal + (min_max.diff * (binid + 1))) AS high, 
      CASE 
          WHEN binid = 9 THEN COUNT(binTbl.salary) + 1
          ELSE COUNT(binTbl.salary) END
  FROM binids INNER JOIN binTbl ON binids.binid = binTbl.bin, min_max
  GROUP BY binid
  ORDER BY binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  -- Get the min, max and avg salaries of each year
  WITH annualTbl AS (SELECT yearid, MIN(salary) AS minSal, MAX(salary) AS maxSal, AVG(salary) AS avgSal
                     FROM salaries
                     GROUP BY yearid),
       -- get the minDiff, maxDiff and avgDiff of each year
       annualDiff AS (SELECT yearid, minSal - (LAG(minSal, 1) OVER (ORDER BY yearid)) AS mindiff,
                             maxSal - (LAG(maxSal, 1) OVER (ORDER BY yearid)) AS maxdiff,
                             avgSal - (LAG(avgSal, 1) OVER (ORDER BY yearid)) AS avgdiff
                             FROM annualTbl)
  -- Select all but not the first year
  SELECT * FROM annualDiff WHERE yearid > (SELECT MIN(yearid) FROM annualDiff) 
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT p.playerid, p.namefirst, p.namelast, s.salary, s.yearid
  FROM people AS p JOIN salaries AS s ON p.playerid = s.playerid
  --Filter out the max salaries in those two years
  WHERE (s.salary =
      (SELECT MAX(s1.salary) FROM salaries AS s1 WHERE s1.yearid = 2000)
      AND s.yearid = 2000)
    OR (s.salary =
      (SELECT MAX(s2.salary) FROM salaries AS s2 WHERE s2.yearid = 2001)
      AND s.yearid = 2001)
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT table2016.teamid AS team, (MAX(salary) - MIN(salary)) AS diffAvg
  FROM
      (SELECT allstarfull.playerid, allstarfull.teamid, salaries.salary 
       FROM allstarfull JOIN salaries ON allstarfull.playerid = salaries.playerid AND allstarfull.yearid = 2016 AND salaries.yearid = 2016) AS table2016
  GROUP BY table2016.teamid
;

