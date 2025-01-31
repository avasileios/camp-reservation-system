# Database Project: Camp Reservation System

This document outlines the steps taken to design, implement, and analyze a database system for managing camp reservations. The project is divided into three phases:

1. **Phase A**: Database Design and Normalization
2. **Phase B**: Querying and Indexing
3. **Phase C**: Data Warehouse and Reporting

---

## Phase A: Database Design and Normalization

### Step 1: Create the Database
We started by creating the `CAMPDB` database and loading the initial data from the `campData.txt` file.

```sql
CREATE DATABASE CAMPDB;
USE CAMPDB;
```

### Step 2: Create the Initial Table
We created the `campData` table to store the raw data from the `campData.txt` file.

```sql
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
```

### Step 3: Load Data from `campData.txt`
We used the `BULK INSERT` command to load data from the `campData.txt` file into the `campData` table.

```sql
SET DATEFORMAT dmy;
BULK INSERT campData
FROM 'C:\campData.txt'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');
```

### Step 4: Normalize the Database
We normalized the database into **Third Normal Form (3NF)** by creating the following tables:

1. **Campsite**:
   ```sql
   CREATE TABLE Campsite (
       campCode CHAR(3) PRIMARY KEY,
       campName VARCHAR(50) NOT NULL,
       numOfEmp INT NOT NULL
   );
   ```

2. **SpotCategory**:
   ```sql
   CREATE TABLE SpotCategory (
       catCode CHAR(1) PRIMARY KEY,
       areaM2 INT NOT NULL,
       unitCost NUMERIC(4,2) NOT NULL
   );
   ```

3. **Spot**:
   ```sql
   CREATE TABLE Spot (
       campCode CHAR(3),
       empNo INT,
       catCode CHAR(1),
       PRIMARY KEY (campCode, empNo),
       FOREIGN KEY (campCode) REFERENCES Campsite(campCode),
       FOREIGN KEY (catCode) REFERENCES SpotCategory(catCode)
   );
   ```

4. **Customer**:
   ```sql
   CREATE TABLE Customer (
       custCode INT PRIMARY KEY,
       custName VARCHAR(30) NOT NULL,
       custSurname VARCHAR(30) NOT NULL,
       custPhone VARCHAR(20) NOT NULL
   );
   ```

5. **Employee**:
   ```sql
   CREATE TABLE Employee (
       staffNo INT PRIMARY KEY,
       staffName VARCHAR(30) NOT NULL,
       staffSurname VARCHAR(30) NOT NULL
   );
   ```

6. **PaymentMethod**:
   ```sql
   CREATE TABLE PaymentMethod (
       payCode INT PRIMARY KEY,
       payMethod CHAR(2) NOT NULL
   );
   ```

7. **Reservation**:
   ```sql
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
   ```

8. **ReservationDetail**:
   ```sql
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
   ```

### Step 5: Populate the Normalized Tables
We populated the normalized tables using `INSERT INTO ... SELECT DISTINCT` statements.

```sql
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
SELECT bookCode, campCode, empNo,
       MIN(startDt) AS startDt,
       MAX(endDt) AS endDt,
       SUM(noPers) AS noPers
FROM campData
GROUP BY bookCode, campCode, empNo;
```

---

## Phase B: Querying and Indexing

### Step 1: Write SQL Queries
We wrote SQL queries to answer specific business questions. For example:

1. **Total number of reservations per payment method**:
   ```sql
   SELECT payMethod, COUNT(*) AS TotalReservations
   FROM Reservation
   JOIN PaymentMethod ON Reservation.payCode = PaymentMethod.payCode
   GROUP BY payMethod;
   ```

2. **Employee with the most reservations**:
   ```sql
   SELECT e.staffName, e.staffSurname, COUNT(r.bookCode) AS TotalReservations
   FROM Reservation r
   JOIN Employee e ON r.staffNo = e.staffNo
   GROUP BY e.staffName, e.staffSurname
   ORDER BY TotalReservations DESC;
   ```

### Step 2: Create Indexes
We created indexes to optimize query performance.

```sql
CREATE INDEX idx_reservation_bookdt ON Reservation(bookDt);
CREATE INDEX idx_customer_custcode ON Customer(custCode);
CREATE INDEX idx_reservationdetail_campcode ON ReservationDetail(campCode);
CREATE INDEX idx_spot_campcode_empno ON Spot(campCode, empNo);
CREATE INDEX idx_spotcategory_catcode ON SpotCategory(catCode);
```

---

## Phase C: Data Warehouse and Reporting

### Step 1: Create the Data Warehouse
We created a data warehouse using a **star schema**.

```sql
CREATE DATABASE CAMPDW;
USE CAMPDW;

-- Create Dimension Tables
CREATE TABLE DimTime (
    timeID INT PRIMARY KEY,
    fullDate DATE NOT NULL,
    year INT NOT NULL,
    month INT NOT NULL,
    day INT NOT NULL,
    quarter INT NOT NULL
);

CREATE TABLE DimCustomer (
    custCode INT PRIMARY KEY,
    custName VARCHAR(30) NOT NULL,
    custSurname VARCHAR(30) NOT NULL,
    custPhone VARCHAR(20) NOT NULL
);

CREATE TABLE DimCampsite (
    campCode CHAR(3) PRIMARY KEY,
    campName VARCHAR(50) NOT NULL,
    numOfEmp INT NOT NULL
);

CREATE TABLE DimSpotCategory (
    catCode CHAR(1) PRIMARY KEY,
    areaM2 INT NOT NULL,
    unitCost NUMERIC(4,2) NOT NULL
);

-- Create Fact Table
CREATE TABLE FactReservation (
    timeID INT,
    custCode INT,
    campCode CHAR(3),
    catCode CHAR(1),
    totalReservations INT,
    totalRevenue NUMERIC(19,2),
    totalPersons INT,
    PRIMARY KEY (timeID, custCode, campCode, catCode),
    FOREIGN KEY (timeID) REFERENCES DimTime(timeID),
    FOREIGN KEY (custCode) REFERENCES DimCustomer(custCode),
    FOREIGN KEY (campCode) REFERENCES DimCampsite(campCode),
    FOREIGN KEY (catCode) REFERENCES DimSpotCategory(catCode)
);
```

### Step 2: Populate the Data Warehouse
We populated the data warehouse by extracting data from the normalized tables.

```sql
-- Insert into DimTime
INSERT INTO DimTime (timeID, fullDate, year, month, day, quarter)
SELECT DISTINCT YEAR(bookDt) * 10000 + MONTH(bookDt) * 100 + DAY(bookDt) AS timeID,
                bookDt AS fullDate,
                YEAR(bookDt) AS year,
                MONTH(bookDt) AS month,
                DAY(bookDt) AS day,
                DATEPART(QUARTER, bookDt) AS quarter
FROM CAMPDB.dbo.Reservation;

-- Insert into DimCustomer
INSERT INTO DimCustomer (custCode, custName, custSurname, custPhone)
SELECT custCode, custName, custSurname, custPhone
FROM CAMPDB.dbo.Customer;

-- Insert into DimCampsite
INSERT INTO DimCampsite (campCode, campName, numOfEmp)
SELECT campCode, campName, numOfEmp
FROM CAMPDB.dbo.Campsite;

-- Insert into DimSpotCategory
INSERT INTO DimSpotCategory (catCode, areaM2, unitCost)
SELECT catCode, areaM2, unitCost
FROM CAMPDB.dbo.SpotCategory;

-- Insert into FactReservation
INSERT INTO FactReservation (timeID, custCode, campCode, catCode, totalReservations, totalRevenue, totalPersons)
SELECT YEAR(r.bookDt) * 10000 + MONTH(r.bookDt) * 100 + DAY(r.bookDt) AS timeID,
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
GROUP BY YEAR(r.bookDt), MONTH(r.bookDt), DAY(r.bookDt),
         r.custCode, s.campCode, s.catCode;
```

### Step 3: Generate Reports
We wrote SQL queries to generate reports for the business. For example:

1. **Top 100 Customers by Reservation Value**:
   ```sql
   SELECT c.custName, c.custSurname, SUM(f.totalRevenue) AS TotalReservationValue
   FROM FactReservation f
   JOIN DimCustomer c ON f.custCode = c.custCode
   GROUP BY c.custName, c.custSurname
   ORDER BY TotalReservationValue DESC
   OFFSET 0 ROWS
   FETCH NEXT 100 ROWS ONLY;
   ```

2. **Total Reservation Value per Campsite and Category for 2000**:
   ```sql
   SELECT cs.campName, sc.catCode, SUM(f.totalRevenue) AS TotalReservationValue
   FROM FactReservation f
   JOIN DimCampsite cs ON f.campCode = cs.campCode
   JOIN DimSpotCategory sc ON f.catCode = sc.catCode
   JOIN DimTime t ON f.timeID = t.timeID
   WHERE t.year = 2000
   GROUP BY cs.campName, sc.catCode
   ORDER BY cs.campName, sc.catCode;
   ```

---

## Conclusion
This project involved designing a normalized database, querying the data, and creating a data warehouse for reporting. The steps outlined above provide a comprehensive guide to completing the task.