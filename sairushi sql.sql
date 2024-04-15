create database hotel_data;
use hotel_data;

-- Creating tables
CREATE TABLE customer (
    serial_number INT,
    customer_type VARCHAR(15) NOT NULL,
    country VARCHAR(5) NOT NULL,
    adult INT,
    children INT,
    babies INT,
    meal VARCHAR(5),
    special_guest INT,
    PRIMARY KEY (serial_number) -- Assuming serial_number is the primary key
);

CREATE TABLE hotel (
    serial_number INT primary key,
    hotel_type VARCHAR(20) NOT NULL,
    country VARCHAR(30) NOT NULL,
    reserved_room varchar(1),
    assigned_room varchar(1),
    FOREIGN KEY (serial_number) REFERENCES customer(serial_number)
);

CREATE TABLE booking (
    serial_number INT,
    reservation_status VARCHAR(15) NOT NULL,
    booking_changes int,
    reserved_type VARCHAR(1) NOT NULL,
    assigned_type VARCHAR(1) NOT NULL,
    meal VARCHAR(5) NOT NULL,
    customer_type VARCHAR(15) NOT NULL
);


-- 1. Retrieve the customer_type and country from the customer table, converting the country names to uppercase.
SELECT customer_type, UPPER(country) AS country FROM customer;

-- 2. Concatenate the hotel_type and country columns from the hotel table, separating them with a hyphen.
SELECT CONCAT(hotel_type, '-', country) AS hotel_info FROM hotel;

-- 3. Calculate the total number of adults, children, and babies for each customer, and display the sum as a new column.
SELECT *, adult + children + babies AS total_people FROM customer;

-- 4. Determine the average number of booking changes made by customers.
SELECT AVG(booking_changes) AS avg_booking_changes FROM booking;


-- 5. Find the total count of customers by customer_type.
SELECT customer_type, COUNT(*) AS total_customers FROM customer GROUP BY customer_type;

-- 6. Calculate the average number of booking changes made by customers of each customer_type.
SELECT customer_type, AVG(booking_changes) AS avg_booking_changes FROM booking GROUP BY customer_type;

-- 7. Rank the customers based on the number of booking changes they made.
SELECT customer_type, RANK() OVER (ORDER BY booking_changes DESC) AS change_rank FROM booking;

	-- 8. Calculate the running total of booking changes for each customer, ordered by serial_number.
	SELECT serial_number, booking_changes, SUM(booking_changes) OVER (ORDER BY serial_number) AS running_total_changes FROM booking;

-- 9. Identify customers who have made more than 3 booking changes and label them as 'High Maintenance', otherwise label them as 'Regular'.
SELECT customer_type, CASE WHEN booking_changes > 3 THEN 'High Maintenance' ELSE 'Regular' END AS maintenance_status FROM booking;

-- 10. Classify customers based on their total count of adults: 'Single', 'Couple', 'Family'.
SELECT *, 
    CASE 
        WHEN adult = 1 THEN 'Single'
        WHEN adult = 2 THEN 'Couple'
        ELSE 'Family' 
    END AS customer_class 
FROM customer;

-- 11. Create a function to calculate the total number of people (adults, children, and babies) for each customer.
-- Example function:
DROP FUNCTION IF EXISTS calculate_total_people;
DELIMITER //
CREATE FUNCTION calculate_total_people(adults INT, children INT, babies INT) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total INT;
    SET total = adults + children + babies;
    RETURN total;
END //
DELIMITER ;
SELECT calculate_total_people(2, 1, 0) AS total_people;

-- 12. Create a function to check if a customer's reservation_status in the booking table is 'Confirmed'.
-- Example function:
DROP FUNCTION IF EXISTS is_confirmed_reservation;
DELIMITER //
CREATE FUNCTION is_confirmed_reservation(serial_number INT) RETURNS INT
READS SQL DATA
BEGIN
    DECLARE is_confirmed INT;
    SET is_confirmed = EXISTS (SELECT 1 FROM booking WHERE serial_number = serial_number AND reservation_status = 'Confirmed');
    RETURN is_confirmed;
END //
DELIMITER ;
SELECT is_confirmed_reservation(12) AS is_confirmed;

-- 13. Retrieve the customer_type, country, and hotel_type for all reservations made by customers.
SELECT b.customer_type, c.country, h.hotel_type
FROM booking b
INNER JOIN customer c ON b.serial_number = c.serial_number
INNER JOIN hotel h ON b.serial_number = h.serial_number;

-- 14. Retrieve the reservation_status, customer_type, and meal for each booking, joined with the customer table.
SELECT b.reservation_status, c.customer_type, b.meal
FROM booking b
INNER JOIN customer c ON b.serial_number = c.serial_number;

-- 15. Find the customers who have made more booking changes than the average number of booking changes.
SELECT b.serial_number, b.booking_changes, a.avg_booking_changes
FROM booking b
INNER JOIN (SELECT AVG(booking_changes) AS avg_booking_changes FROM booking) a ON b.booking_changes > a.avg_booking_changes;

-- 16. Identify customers who have reserved a room type that is not assigned yet.
SELECT c.serial_number, b.reserved_type, b.assigned_type
FROM customer c
INNER JOIN booking b ON c.serial_number = b.serial_number
WHERE b.reserved_type != b.assigned_type;

-- 17. Calculate the average number of booking changes made by customers for each customer_type using a CTE.
WITH AvgBookingChanges AS (
    SELECT customer_type, AVG(booking_changes) AS avg_changes
    FROM booking
    GROUP BY customer_type
)
SELECT * FROM AvgBookingChanges;

-- 18. Identify customers who have made more booking changes than the average number of booking changes using a CTE.
WITH AvgBookingChanges AS (
    SELECT customer_type, AVG(booking_changes) AS avg_changes
    FROM booking
    GROUP BY customer_type
)
SELECT b.serial_number, b.booking_changes, a.avg_changes
FROM booking b
INNER JOIN AvgBookingChanges a ON b.customer_type = a.customer_type
WHERE b.booking_changes > a.avg_changes;

-- 19. Create a view that displays the customer_type, country, and total number of people for each customer.
DROP VIEW IF EXISTS CustomerDetails;
CREATE VIEW CustomerDetails AS
SELECT c.customer_type, c.country, (c.adult + c.children + c.babies) AS total_people
FROM customer c;
SELECT * FROM CustomerDetails;


-- 20. Create a view that combines data from the customer and hotel tables to show the reservation details.
DROP VIEW IF EXISTS ReservationDetails;
CREATE VIEW ReservationDetails AS
SELECT b.serial_number, b.reservation_status, b.booking_changes, b.reserved_type, 
       b.assigned_type, b.meal, b.customer_type AS booking_customer_type,
       c.customer_type, c.country, h.hotel_type
FROM booking b
INNER JOIN customer c ON b.serial_number = c.serial_number
INNER JOIN hotel h ON b.serial_number = h.serial_number;
SELECT * FROM ReservationDetails;

-- 21. Create a stored procedure to calculate the total number of adults, children, and babies for a given customer serial_number.
-- Example stored procedure:
DROP PROCEDURE IF EXISTS CalculateTotalPeople;
DELIMITER //

CREATE PROCEDURE CalculateTotalPeople (IN p_serial_number INT)
BEGIN
    SELECT adults, children, babies, (adults + children + babies) AS total_people
    FROM customer
    WHERE serial_number = p_serial_number;
END;
//
DELIMITER ;

-- 22. Create a stored procedure to update the reservation_status of a booking based on certain conditions.
-- Example stored procedure:
DROP PROCEDURE IF EXISTS UpdateReservationStatus;
DELIMITER //
CREATE PROCEDURE UpdateReservationStatus (IN booking_id INT, IN new_status VARCHAR(15))
BEGIN
    UPDATE booking
    SET reservation_status = new_status
    WHERE serial_number = booking_id;
END;
//
DELIMITER ;

-- 23. Implement a trigger to automatically update the reserved_room and assigned_room columns in the hotel table when a new reservation is made.
-- Example trigger:
DROP TRIGGER IF EXISTS UpdateRooms;
DELIMITER //

CREATE TRIGGER UpdateRooms AFTER INSERT ON booking
FOR EACH ROW
BEGIN
    UPDATE hotel
    SET reserved_room = NEW.reserved_type, assigned_room = NEW.assigned_type
    WHERE serial_number = NEW.serial_number;
END;
//

DELIMITER ;

-- 24. Create a trigger to log changes made to the reservation_status column in the booking table.
-- Example trigger:
DROP TRIGGER IF EXISTS LogReservationStatusChanges;
DELIMITER //

CREATE TRIGGER LogReservationStatusChanges AFTER UPDATE ON booking
FOR EACH ROW
BEGIN
    INSERT INTO reservation_status_log (booking_id, old_status, new_status, change_timestamp)
    VALUES (OLD.serial_number, OLD.reservation_status, NEW.reservation_status, NOW());
END;
//

DELIMITER ;

-- 25. Analyze the performance impact of creating an index on the customer_type column in the customer table.
-- Example SQL for creating index:

DROP INDEX idx_customer_type ON customer;
CREATE INDEX idx_customer_type ON customer(customer_type);

-- 26. Evaluate the benefits of indexing the reservation_status column in the booking table.
-- Example SQL for creating index:
DROP INDEX idx_reservation_status ON customer;
CREATE INDEX idx_reservation_status ON booking(reservation_status);






-- SELECT statement with WHERE, GROUP BY, HAVING, and ORDER BY clauses
SELECT
    customer_type,
    country,
    AVG(adult) AS avg_adults,
    COUNT(*) AS num_bookings
FROM
    customer
WHERE
    country = 'PRT'
GROUP BY
    customer_type,
    country
HAVING
    AVG(adult) > 1
ORDER BY
    num_bookings DESC;

-- String Functions: Concatenation
SELECT
    CONCAT(customer_type, ' - ', country) AS customer_location
FROM
    customer;

-- Numeric Functions: Mathematical Calculations
SELECT
    adult,
    children,
    adult + children AS total_guests
FROM
    customer;

-- Date and Time Functions: Extracting Parts of a Date
SELECT
    reservation_status,
    DATE_FORMAT(NOW(), '%Y-%m-%d') AS `current_date`
FROM
    booking;

-- Aggregate Functions: COUNT, SUM
SELECT
    reservation_status,
    COUNT(*) AS num_bookings,
    SUM(booking_changes) AS total_changes
FROM
    booking
GROUP BY
    reservation_status;

-- Window Functions: ROW_NUMBER
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY reservation_status ORDER BY booking_changes DESC) AS row_num
FROM
    booking;

-- Control Flow Functions: CASE statement
SELECT
    reservation_status,
    CASE
        WHEN reservation_status = 'Check-Out' THEN 'Completed'
        ELSE 'Cancelled'
    END AS booking_status
FROM
    booking;

-- Subqueries: Example of a correlated subquery
SELECT
    customer_type,
    country,
    (SELECT AVG(adult) FROM customer WHERE country = c.country) AS avg_adults_country
FROM
    customer c;

-- Common Table Expressions (CTEs)
WITH TotalGuests AS (
    SELECT
        customer_type,
        SUM(adult + children) AS total_guests
    FROM
        customer
    GROUP BY
        customer_type
)
SELECT
    customer_type,
    total_guests
FROM
    TotalGuests;

-- Views
DROP VIEW IF EXISTS CustomerInfo;

CREATE VIEW CustomerInfo AS
SELECT
    serial_number,
    customer_type,
    country
FROM
    customer;

-- Stored Procedures
DROP PROCEDURE IF EXISTS GetBookingsByCountry;

DELIMITER //

CREATE PROCEDURE GetBookingsByCountry(IN country_name VARCHAR(30))
BEGIN
    SELECT * FROM booking WHERE country = country_name;
END //

DELIMITER ;
-- Trigger: Example of a trigger to log changes
DELIMITER //

CREATE TRIGGER LogBookingChanges
AFTER INSERT ON booking
FOR EACH ROW
BEGIN
    INSERT INTO booking_log (booking_id, action, timestamp)
    VALUES (NEW.serial_number, 'Inserted', NOW());
END //

DELIMITER ;

-- Indexing: Example of creating an index
CREATE INDEX idx_country ON customer (country);

-- Inner join

SELECT
    b.reservation_status,
    c.customer_type,
    c.country,
    h.hotel_type,
    h.country AS hotel_country,
    b.booking_changes,
    b.reserved_type,
    b.assigned_type,
    b.meal
FROM
    booking b
JOIN
    customer c ON b.customer_type = c.customer_type
JOIN
    hotel h ON h.serial_number = b.serial_number;
    
-- Left join 

SELECT * 
FROM booking
LEFT JOIN customer ON booking.customer_type = customer.customer_type
LEFT JOIN hotel ON booking.reserved_type = hotel.reserved_room;  

-- Right join

SELECT * 
FROM booking
RIGHT JOIN customer ON booking.customer_type = customer.customer_type
RIGHT JOIN hotel ON booking.reserved_type = hotel.reserved_room;

-- Full join

SELECT * 
FROM booking
LEFT JOIN customer ON booking.customer_type = customer.customer_type
LEFT JOIN hotel ON booking.reserved_type = hotel.reserved_room
UNION
SELECT * 
FROM booking
RIGHT JOIN customer ON booking.customer_type = customer.customer_type
RIGHT JOIN hotel ON booking.reserved_type = hotel.reserved_room;




