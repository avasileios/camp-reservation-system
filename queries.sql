---Phase B
---1. SQL Queries
/*
a. Display the total number of reservations per payment method.
*/
SELECT 
    pm.payMethod AS PaymentMethod, 
    COUNT(r.bookCode) AS TotalReservations
FROM 
    Reservation r
JOIN 
    PaymentMethod pm ON r.payCode = pm.payCode
GROUP BY 
    pm.payMethod;

/*
b. Display the full name of the employee who processed the most reservations. 
Include the number of reservations they processed. 
If multiple employees have the same number of reservations, display all of them.
*/
SELECT 
    e.staffName, 
    e.staffSurname, 
    COUNT(r.bookCode) AS TotalReservations
FROM 
    Reservation r
JOIN 
    Employee e ON r.staffNo = e.staffNo
GROUP BY 
    e.staffName, e.staffSurname
HAVING 
    COUNT(r.bookCode) = (
        SELECT MAX(ReservationCount)
        FROM (
            SELECT COUNT(bookCode) AS ReservationCount
            FROM Reservation
            GROUP BY staffNo
        ) AS MaxReservations
    );

/*
c. Display the total number of reservations that only include spots of category "A" in one or more campsites.
*/
SELECT 
    COUNT(DISTINCT rd.bookCode) AS TotalReservations
FROM 
    ReservationDetail rd
JOIN 
    Spot s ON rd.campCode = s.campCode AND rd.empNo = s.empNo
WHERE 
    s.catCode = 'A'
AND NOT EXISTS (
    SELECT 1
    FROM ReservationDetail rd2
    JOIN Spot s2 ON rd2.campCode = s2.campCode AND rd2.empNo = s2.empNo
    WHERE rd2.bookCode = rd.bookCode AND s2.catCode <> 'A'
);

/*
d. Display a list of each customer's full name and the total number of reservations they made in the year 2000. Sort the list by the customer's surname.
*/
SELECT 
    c.custName, 
    c.custSurname, 
    COUNT(r.bookCode) AS TotalReservations
FROM 
    Reservation r
JOIN 
    Customer c ON r.custCode = c.custCode
WHERE 
    YEAR(r.bookDt) = 2000
GROUP BY 
    c.custName, c.custSurname
ORDER BY 
    c.custSurname;

/*
e. Display the total value of reservations (total revenue) per campsite.
*/
SELECT 
    c.campName, 
    SUM(sc.unitCost * DATEDIFF(day, rd.startDt, rd.endDt) * rd.noPers) AS TotalRevenue
FROM 
    ReservationDetail rd
JOIN 
    Spot s ON rd.campCode = s.campCode AND rd.empNo = s.empNo
JOIN 
    SpotCategory sc ON s.catCode = sc.catCode
JOIN 
    Campsite c ON s.campCode = c.campCode
GROUP BY 
    c.campName;

---Phase C
---1. SQL Queries
/*
a. Display a list of the top 100 customers by total reservation value. 
Include the customer's full name and total reservation value.
*/
SELECT 
    c.custName, 
    c.custSurname, 
    SUM(f.totalRevenue) AS TotalReservationValue
FROM 
    FactReservation f
JOIN 
    DimCustomer c ON f.custCode = c.custCode
GROUP BY 
    c.custName, c.custSurname
ORDER BY 
    TotalReservationValue DESC
OFFSET 0 ROWS
FETCH NEXT 100 ROWS ONLY;

/*
b. Display the total value of reservations per campsite and spot category for the year 2000.
*/
SELECT 
    cs.campName, 
    sc.catCode, 
    SUM(f.totalRevenue) AS TotalReservationValue
FROM 
    FactReservation f
JOIN 
    DimCampsite cs ON f.campCode = cs.campCode
JOIN 
    DimSpotCategory sc ON f.catCode = sc.catCode
JOIN 
    DimTime t ON f.timeID = t.timeID
WHERE 
    t.year = 2000
GROUP BY 
    cs.campName, sc.catCode
ORDER BY 
    cs.campName, sc.catCode;

/*
c. Display the total value of reservations per campsite on a monthly basis for the year 2018.
*/
SELECT 
    cs.campName, 
    t.month, 
    SUM(f.totalRevenue) AS TotalReservationValue
FROM 
    FactReservation f
JOIN 
    DimCampsite cs ON f.campCode = cs.campCode
JOIN 
    DimTime t ON f.timeID = t.timeID
WHERE 
    t.year = 2018
GROUP BY 
    cs.campName, t.month
ORDER BY 
    cs.campName, t.month;

/*
d. Generate a report with the following information:
    Total number of persons.
    Number of persons per year.
    Number of persons per year and campsite.
    Number of persons per year, campsite, and spot category.
*/
SELECT 
    COALESCE(CAST(t.year AS VARCHAR(10)), 'Grand Total') AS Year,
    COALESCE(cs.campName, 'All Campsites') AS CampName,
    COALESCE(sc.catCode, 'All Categories') AS Category,
    SUM(f.totalPersons) AS TotalPersons
FROM 
    FactReservation f
JOIN 
    DimTime t ON f.timeID = t.timeID
JOIN 
    DimCampsite cs ON f.campCode = cs.campCode
JOIN 
    DimSpotCategory sc ON f.catCode = sc.catCode
GROUP BY 
    ROLLUP(t.year, cs.campName, sc.catCode)
ORDER BY 
    t.year, cs.campName, sc.catCode;

/*
e. Create a cube to analyze reservation value by year, campsite, and spot category.
*/
SELECT 
    COALESCE(CAST(t.year AS VARCHAR(10)), 'Grand Total') AS Year,
    COALESCE(cs.campName, 'All Campsites') AS CampName,
    COALESCE(sc.catCode, 'All Categories') AS Category,
    SUM(f.totalRevenue) AS TotalRevenue
FROM 
    FactReservation f
JOIN 
    DimTime t ON f.timeID = t.timeID
JOIN 
    DimCampsite cs ON f.campCode = cs.campCode
JOIN 
    DimSpotCategory sc ON f.catCode = sc.catCode
GROUP BY 
    CUBE(t.year, cs.campName, sc.catCode)
ORDER BY 
    t.year, 
    CASE 
        WHEN cs.campName IS NULL THEN 1 
        ELSE 0 
    END, 
    cs.campName, 
    CASE 
        WHEN sc.catCode IS NULL THEN 1 
        ELSE 0 
    END, 
    sc.catCode;