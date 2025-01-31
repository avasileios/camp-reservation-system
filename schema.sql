---Phase A
---Create db
CREATE DATABASE CAMPDB;
---Use db
USE CAMPDB;
--- Create table
CREATE TABLE campData (
    bookCode INT,
    bookDt DATE,
    payCode INT,
    payMethod CHAR(2),
    custCode INT,
    custName VARCHAR(30),
    custSurname VARCHAR(30),
    custPhone VARCHAR(20),
    staffNo INT,
    staffName VARCHAR(30),
    staffSurname VARCHAR(30),
    totalCost NUMERIC(19,2),
    campCode CHAR(3),
    campName VARCHAR(50),
    numOfEmp INT,
    empNo INT,
    catCode CHAR(1),
    areaM2 INT,
    unitCost NUMERIC(4,2),
    startDt DATE,
    endDt DATE,
    noPers INT,
    costPerRental NUMERIC(19,2)
);
---Load table from txt
SET DATEFORMAT dmy;
BULK INSERT campData
FROM 'C:\campData.txt'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');

---Create  3NF tables for better handling 
-- Create Campsite Table
CREATE TABLE Campsite (
    campCode CHAR(3) PRIMARY KEY,
    campName VARCHAR(50) NOT NULL,
    numOfEmp INT NOT NULL
);
-- Create SpotCategory Table
CREATE TABLE SpotCategory (
    catCode CHAR(1) PRIMARY KEY,
    areaM2 INT NOT NULL,
    unitCost NUMERIC(4,2) NOT NULL
);
-- Create Spot Table
CREATE TABLE Spot (
    campCode CHAR(3),
    empNo INT,
    catCode CHAR(1),
    PRIMARY KEY (campCode, empNo),
    FOREIGN KEY (campCode) REFERENCES Campsite(campCode),
    FOREIGN KEY (catCode) REFERENCES SpotCategory(catCode)
);
-- Create Customer Table
CREATE TABLE Customer (
    custCode INT PRIMARY KEY,
    custName VARCHAR(30) NOT NULL,
    custSurname VARCHAR(30) NOT NULL,
    custPhone VARCHAR(20) NOT NULL
);
-- Create Employee Table
CREATE TABLE Employee (
    staffNo INT PRIMARY KEY,
    staffName VARCHAR(30) NOT NULL,
    staffSurname VARCHAR(30) NOT NULL
);
-- Create PaymentMethod Table
CREATE TABLE PaymentMethod (
    payCode INT PRIMARY KEY,
    payMethod CHAR(2) NOT NULL
);
-- Create Reservation Table
CREATE TABLE Reservation (
    bookCode INT PRIMARY KEY,
    bookDt DATE NOT NULL,
    custCode INT,
    staffNo INT,
    payCode INT,
    FOREIGN KEY (custCode) REFERENCES Customer(custCode),
    FOREIGN KEY (staffNo) REFERENCES Employee(staffNo),
    FOREIGN KEY (payCode) REFERENCES PaymentMethod(payCode)
);
-- Create ReservationDetail Table
CREATE TABLE ReservationDetail (
    bookCode INT,
    campCode CHAR(3),
    empNo INT,
    startDt DATE NOT NULL,
    endDt DATE NOT NULL,
    noPers INT NOT NULL,
    PRIMARY KEY (bookCode, campCode, empNo),
    FOREIGN KEY (bookCode) REFERENCES Reservation(bookCode),
    FOREIGN KEY (campCode, empNo) REFERENCES Spot(campCode, empNo)
);

---Populate tables
-- Insert into Campsite
INSERT INTO Campsite (campCode, campName, numOfEmp)
SELECT DISTINCT campCode, campName, numOfEmp
FROM campData;
-- Insert into SpotCategory
INSERT INTO SpotCategory (catCode, areaM2, unitCost)
SELECT DISTINCT catCode, areaM2, unitCost
FROM campData;
-- Insert into Spot
INSERT INTO Spot (campCode, empNo, catCode)
SELECT DISTINCT campCode, empNo, catCode
FROM campData;
-- Insert into Customer
INSERT INTO Customer (custCode, custName, custSurname, custPhone)
SELECT DISTINCT custCode, custName, custSurname, custPhone
FROM campData;
-- Insert into Employee
INSERT INTO Employee (staffNo, staffName, staffSurname)
SELECT DISTINCT staffNo, staffName, staffSurname
FROM campData;
-- Insert into PaymentMethod
INSERT INTO PaymentMethod (payCode, payMethod)
SELECT DISTINCT payCode, payMethod
FROM campData;
-- Insert into Reservation
INSERT INTO Reservation (bookCode, bookDt, custCode, staffNo, payCode)
SELECT DISTINCT bookCode, bookDt, custCode, staffNo, payCode
FROM campData;
-- Insert into ReservationDetail
INSERT INTO ReservationDetail (bookCode, campCode, empNo, startDt, endDt, noPers)
SELECT DISTINCT bookCode, campCode, empNo, startDt, endDt, noPers
FROM campData;
--!!!!!!!---
---Error due to duplicate records
---Solution
---Look for duplic
SELECT bookCode, campCode, empNo, COUNT(*) AS DuplicateCount
FROM campData
GROUP BY bookCode, campCode, empNo
HAVING COUNT(*) > 1;
---Agrigate--- 
SELECT bookCode, campCode, empNo,
       MIN(startDt) AS startDt,  -- Earliest start date
       MAX(endDt) AS endDt,      -- Latest end date
       SUM(noPers) AS noPers     -- Total number of persons
FROM campData
GROUP BY bookCode, campCode, empNo;
--- Populate Table
INSERT INTO ReservationDetail (bookCode, campCode, empNo, startDt, endDt, noPers)
SELECT bookCode, campCode, empNo,
       MIN(startDt) AS startDt,
       MAX(endDt) AS endDt,
       SUM(noPers) AS noPers
FROM campData
GROUP BY bookCode, campCode, empNo;

---Verify 3NF tables 
SELECT * FROM Campsite;
SELECT * FROM SpotCategory;
SELECT * FROM Spot;
SELECT * FROM Customer;
SELECT * FROM Employee;
SELECT * FROM PaymentMethod;
SELECT * FROM Reservation;
SELECT * FROM ReservationDetail;

---Phase B
---2. Index Creation

---Index for Query d (Customer Reservations in 2000)
CREATE INDEX idx_reservation_bookdt ON Reservation(bookDt);
CREATE INDEX idx_customer_custcode ON Customer(custCode);
---Index for Query e (Total Revenue per Campsite):
CREATE INDEX idx_reservationdetail_campcode ON ReservationDetail(campCode);
CREATE INDEX idx_spot_campcode_empno ON Spot(campCode, empNo);
CREATE INDEX idx_spotcategory_catcode ON SpotCategory(catCode);

---Phase C
---1. Create the Data Warehouse
CREATE DATABASE CAMPDW;
USE CAMPDW;
---Create Dimension Tables
---Time Dimnension
CREATE TABLE DimTime (
    timeID INT PRIMARY KEY,  -- Unique ID for each date
    fullDate DATE NOT NULL,  -- Date in YYYY-MM-DD format
    year INT NOT NULL,       -- Year (e.g., 2000, 2018)
    month INT NOT NULL,      -- Month (1-12)
    day INT NOT NULL,        -- Day of the month (1-31)
    quarter INT NOT NULL     -- Quarter (1-4)
);
---Customer Dimension
CREATE TABLE DimCustomer (
    custCode INT PRIMARY KEY,  -- Unique customer code
    custName VARCHAR(30) NOT NULL,
    custSurname VARCHAR(30) NOT NULL,
    custPhone VARCHAR(20) NOT NULL
);
---Campsite Dimension
CREATE TABLE DimCampsite (
    campCode CHAR(3) PRIMARY KEY,  -- Unique campsite code
    campName VARCHAR(50) NOT NULL,
    numOfEmp INT NOT NULL
);
---Spot Category Dimension:
CREATE TABLE DimSpotCategory (
    catCode CHAR(1) PRIMARY KEY,  -- Unique category code
    areaM2 INT NOT NULL,
    unitCost NUMERIC(4,2) NOT NULL
);
---Create Fact Table
CREATE TABLE FactReservation (
    timeID INT,                -- Foreign key to DimTime
    custCode INT,              -- Foreign key to DimCustomer
    campCode CHAR(3),          -- Foreign key to DimCampsite
    catCode CHAR(1),           -- Foreign key to DimSpotCategory
    totalReservations INT,     -- Total number of reservations
    totalRevenue NUMERIC(19,2), -- Total revenue from reservations
    totalPersons INT,          -- Total number of persons
    PRIMARY KEY (timeID, custCode, campCode, catCode),
    FOREIGN KEY (timeID) REFERENCES DimTime(timeID),
    FOREIGN KEY (custCode) REFERENCES DimCustomer(custCode),
    FOREIGN KEY (campCode) REFERENCES DimCampsite(campCode),
    FOREIGN KEY (catCode) REFERENCES DimSpotCategory(catCode)
);

---Populate the Data Warehouse
INSERT INTO DimTime (timeID, fullDate, year, month, day, quarter)
SELECT 
    DISTINCT YEAR(bookDt) * 10000 + MONTH(bookDt) * 100 + DAY(bookDt) AS timeID,
    bookDt AS fullDate,
    YEAR(bookDt) AS year,
    MONTH(bookDt) AS month,
    DAY(bookDt) AS day,
    DATEPART(QUARTER, bookDt) AS quarter
FROM CAMPDB.dbo.Reservation;

INSERT INTO DimCustomer (custCode, custName, custSurname, custPhone)
SELECT custCode, custName, custSurname, custPhone
FROM CAMPDB.dbo.Customer;

INSERT INTO DimCampsite (campCode, campName, numOfEmp)
SELECT campCode, campName, numOfEmp
FROM CAMPDB.dbo.Campsite;

INSERT INTO DimSpotCategory (catCode, areaM2, unitCost)
SELECT catCode, areaM2, unitCost
FROM CAMPDB.dbo.SpotCategory;

INSERT INTO FactReservation (timeID, custCode, campCode, catCode, totalReservations, totalRevenue, totalPersons)
SELECT 
    YEAR(r.bookDt) * 10000 + MONTH(r.bookDt) * 100 + DAY(r.bookDt) AS timeID,
    r.custCode,
    s.campCode,
    s.catCode,
    COUNT(r.bookCode) AS totalReservations,
    SUM(sc.unitCost * DATEDIFF(day, rd.startDt, rd.endDt) * rd.noPers) AS totalRevenue,
    SUM(rd.noPers) AS totalPersons
FROM CAMPDB.dbo.Reservation r
JOIN CAMPDB.dbo.ReservationDetail rd ON r.bookCode = rd.bookCode
JOIN CAMPDB.dbo.Spot s ON rd.campCode = s.campCode AND rd.empNo = s.empNo
JOIN CAMPDB.dbo.SpotCategory sc ON s.catCode = sc.catCode
GROUP BY 
    YEAR(r.bookDt), MONTH(r.bookDt), DAY(r.bookDt),
    r.custCode, s.campCode, s.catCode;