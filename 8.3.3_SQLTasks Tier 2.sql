/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
SELECT name
FROM Facilities
WHERE membercost = 0;
-- Answer: Badminton Court, Table Tennis, Snooker Table, Pool Table.

/* Q2: How many facilities do not charge a fee to members? */
SELECT COUNT(name) FROM Facilities WHERE membercost = 0;
-- Answer: 4.

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
SELECT facid, name, membercost, monthlymaintenance FROM Facilities
WHERE membercost != 0 AND membercost < 0.2*monthlymaintenance;

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */
SELECT * FROM Facilities WHERE facid IN (1, 5);

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */
SELECT name, monthlymaintenance,
	CASE WHEN monthlymaintenance > 100 THEN 'expensive'
	ELSE 'cheap' END AS cheap_or_expens
FROM Facilities

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */
SELECT firstname, surname, joindate
FROM Members WHERE joindate > '2012-09-01'
ORDER BY joindate DESC;

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT
	f.name AS facility,
	CASE WHEN (m.firstname != 'GUEST')
		THEN CONCAT (m.firstname, ' ', m.surname)
		ELSE 'GUEST' END AS person
FROM Bookings AS b
LEFT JOIN Facilities AS f
ON f.facid = b.facid
LEFT JOIN Members AS m
ON b.memid = m.memid
WHERE f.facid IN (0, 1)
ORDER BY person;
-- When name is not specified, using 'GUEST'
 
/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT
	f.name AS facility,
	CASE WHEN (m.firstname != 'GUEST')
		THEN CONCAT (m.firstname, ' ', m.surname)
		ELSE 'GUEST' END AS person,
	CASE WHEN (m.firstname != 'GUEST') THEN f.membercost * b.slots
	ELSE f.guestcost * b.slots END AS cost
FROM Bookings AS b
LEFT JOIN Members AS m
ON b.memid = m.memid
LEFT JOIN Facilities AS f
ON b.facid = f.facid
WHERE EXTRACT(YEAR FROM starttime) = 2012
	AND EXTRACT(MONTH FROM starttime) = 9
	AND EXTRACT(DAY FROM starttime) = 14
	AND (((m.firstname != 'GUEST') AND (f.membercost * b.slots > 30)) OR ((m.firstname = 'GUEST') AND (f.guestcost * b.slots > 30)))
ORDER BY cost DESC;

/* Q9: This time, produce the same result as in Q8, but using a subquery. */
SELECT
	s.facility,
	s.person,	
	s.cost
FROM
	(SELECT
		f.name AS facility,
		
		CASE WHEN (m.firstname != 'GUEST')
		THEN CONCAT (m.firstname, ' ', m.surname)
		ELSE 'GUEST' END AS person,
		
		CASE WHEN (m.firstname != 'GUEST') THEN f.membercost * b.slots
		ELSE f.guestcost * b.slots
		END AS cost
	FROM Members AS m
	RIGHT JOIN Bookings AS b
	ON m.memid = b.memid
	LEFT JOIN Facilities AS f
	ON b.facid = f.facid
	WHERE EXTRACT(YEAR FROM b.starttime) = 2012
	AND EXTRACT(MONTH FROM b.starttime) = 9
	AND EXTRACT(DAY FROM b.starttime) = 14
	) AS s
WHERE s.cost > 30
ORDER BY s.cost DESC;

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  
*/

/*QUESTIONS:

/* ATTENTION: Below, SQL queries are shown; Python code is here: XXX */

/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */
SELECT
    s.name AS facility,
    s.total_revenue
FROM -- Correlated subquery
    (SELECT
        f.name,
        SUM(
            CASE WHEN (m.firstname != 'GUEST')
                THEN f.membercost * b.slots
                ELSE f.guestcost * b.slots
            END
        ) AS total_revenue
    FROM Bookings AS b
    LEFT JOIN Facilities AS f
    ON b.facid = f.facid
    LEFT JOIN Members AS m
    ON b.memid = m.memid
    GROUP BY f.facid) AS s
WHERE s.total_revenue < 1000;

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */
-- Surnames and firstnames in separate columns
SELECT DISTINCT
	-- m.memid,
	m.surname AS member_surname,
	m.firstname AS member_firstname,
	CASE WHEN m.recommendedby = '' THEN ''
		ELSE m2.surname END
		AS rec_surname,
	CASE WHEN m.recommendedby = '' THEN ''
		ELSE m2.firstname END
		AS rec_firstname
FROM Members AS m
LEFT JOIN Members AS m2
ON m.recommendedby = m2.memid
ORDER BY member_surname, member_firstname;

-- Concatenated surname and firstname for both the member and recommender
SELECT DISTINCT
	CASE WHEN (m.surname != 'GUEST') THEN
		CONCAT (m.surname, ' ', m.firstname)
	ELSE 'GUEST'
	END AS member,
	CASE WHEN (m.recommendedby = '') THEN ''
		ELSE CONCAT (m2.surname, ' ', m2.firstname)
		END AS recommender
FROM Members AS m
LEFT JOIN Members AS m2
ON m.recommendedby = m2.memid
ORDER BY member;

/* Q12: Find the facilities with their usage by member, but not guests */

-- List of facilities used by members, no usage details
SELECT DISTINCT
	-- b.facid,
	f.name
FROM Bookings AS b
LEFT JOIN Facilities AS f
ON b.facid = f.facid
WHERE b.memid != 0; -- All guests have id=0

-- List of facilities used by members, with details on usage by member ID
SELECT
	f.name AS facility,
	b.memid,
	SUM(b.slots) AS usag
FROM Bookings AS b
LEFT JOIN Facilities AS f
ON b.facid = f.facid
WHERE b.memid != 0 -- All guests have id=0
GROUP BY f.facid, b.memid
ORDER BY f.facid, b.memid;

-- List of facilities used by members, with details on usage by member name
SELECT
	f.name AS facility,
	CASE WHEN (m.surname != 'GUEST') THEN
		CONCAT (m.surname, ' ', m.firstname)
	ELSE 'GUEST'
	END AS member,
	SUM(b.slots) AS usag
FROM Bookings AS b
LEFT JOIN Facilities AS f
ON b.facid = f.facid
LEFT JOIN Members AS m
ON m.memid = b.memid
WHERE b.memid != 0 -- All guests have id=0
GROUP BY f.facid, b.memid
ORDER BY f.facid, member;

/* Q13: Find the facilities usage by month, but not guests */
SELECT
	f.name AS facility,
	EXTRACT(MONTH FROM b.starttime) AS month,
	SUM(b.slots) AS usag
FROM Bookings AS b
LEFT JOIN Facilities AS f
ON b.facid = f.facid
WHERE b.memid != 0 -- All guests have id=0
GROUP BY f.facid, month
ORDER BY f.facid, month;
