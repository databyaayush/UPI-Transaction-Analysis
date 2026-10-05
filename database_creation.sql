 -- CREATE DATABASE  --
 CREATE DATABASE upi;
 
 -- USE DATABASE --
 USE upi;
 
 -- CREATING TRANSACTIONS TABLE --
 CREATE TABLE transactions(
	transaction_id VARCHAR(100) PRIMARY KEY,
    timestamp DATE,
    sender_name VARCHAR(100),
    sender_upi_id VARCHAR(100),
    reciver_name VARCHAR(100),
	reciver_upi_id VARCHAR(100),
    amount INT,
    status VARCHAR(100)
 );