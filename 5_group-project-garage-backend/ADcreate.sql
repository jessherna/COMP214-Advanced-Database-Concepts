-- Drop existing tables to avoid conflicts
DROP TABLE ad_payments CASCADE CONSTRAINTS;
DROP TABLE ad_workorders CASCADE CONSTRAINTS;
DROP TABLE ad_services CASCADE CONSTRAINTS;
DROP TABLE ad_customers CASCADE CONSTRAINTS;
DROP TABLE ad_vehicles CASCADE CONSTRAINTS;
DROP TABLE service_schedule CASCADE CONSTRAINTS;
DROP TABLE ad_garage_config CASCADE CONSTRAINTS;

-- Create ad_customers table
CREATE TABLE ad_customers (
    customer_id NUMBER(10) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100) NOT NULL,
    address VARCHAR(200)
);

-- Create ad_vehicles table
CREATE TABLE ad_vehicles (
    vin NUMBER(10) PRIMARY KEY,
    year NUMBER(10),
    --last_service_date DATE
    mileage NUMBER(10) NOT NULL,
    customer_id NUMBER(10),
    model_name VARCHAR(100),
    maker VARCHAR(50),
    engine_type VARCHAR(50) CHECK (UPPER(engine_type) IN ('HYBRID', 'GAS', 'DIESEL', 'ELECTRIC')),
    plate_number VARCHAR(50) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES ad_customers(customer_id)
);

-- Create ad_services table
CREATE TABLE ad_services (
    service_id NUMBER(10) PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    service_description VARCHAR(200),
    service_price NUMBER(10) NOT NULL
);

-- Create maintenance_schedule table
CREATE TABLE service_schedule (
    schedule_id NUMBER(10) PRIMARY KEY,
    vehicle_id NUMBER(10),
    service_id NUMBER(10),
    FOREIGN KEY (vehicle_id) REFERENCES ad_vehicles(vin),
    FOREIGN KEY (service_id) REFERENCES ad_services(service_id)
);

-- Create ad_workorders table
CREATE TABLE ad_workorders (
    workorder_id NUMBER(10) PRIMARY KEY,
    vin NUMBER(10),
    start_date DATE,
    end_date DATE,
    schedule_id NUMBER(10),
    workorder_status VARCHAR(200) CHECK(UPPER(workorder_status) IN ('PENDING', 'IN PROGRESS', 'COMPLETED')),
    FOREIGN KEY (vin) REFERENCES ad_vehicles(vin),
    FOREIGN KEY (schedule_id) REFERENCES service_schedule(schedule_id)
);

-- Create ad_payments table
CREATE TABLE ad_payments (
    payment_id NUMBER(10) PRIMARY KEY,
    workorder_id NUMBER(10) UNIQUE NOT NULL,
    payment_date DATE,
    payment_status VARCHAR(50)CHECK(UPPER(payment_status) IN ('PAID', 'PENDING')),
    FOREIGN KEY (workorder_id) REFERENCES ad_workorders(workorder_id)
);

CREATE TABLE ad_garage_config (
    max_capacity NUMBER(10) DEFAULT 10
);