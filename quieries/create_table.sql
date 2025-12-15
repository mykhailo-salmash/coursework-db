CREATE TYPE WORKER_ROLE AS ENUM ('doctor', 'nurse', 'technician', 'administrator', 'specialist');
CREATE TYPE SCHEDULE_TYPE AS ENUM ('work_shift', 'break', 'vacation', 'sick_leave');
CREATE TYPE APPOINTMENT_STATUS AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled');
CREATE TYPE ROOM_STATUS AS ENUM ('available', 'occupied', 'maintenance');
CREATE TYPE ROOM_TYPE AS ENUM ('examination', 'procedure', 'surgery', 'consultation');
CREATE TYPE EQUIPMENT_STATUS AS ENUM ('operational', 'maintenance', 'broken', 'decommissioned');
CREATE TYPE FACILITY_TYPE AS ENUM ('hospital', 'clinic', 'laboratory', 'diagnostic_center');

CREATE TABLE Patient (
  patient_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  date_of_birth DATE NOT NULL,
  phone_number VARCHAR(20),
  email VARCHAR(255),
  CONSTRAINT chk_patient_age CHECK (date_of_birth < CURRENT_DATE)
);

CREATE TABLE Facility (
  facility_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type FACILITY_TYPE NOT NULL,
  location POINT NOT NULL
);

CREATE TABLE Team (
  team_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  specialization VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Worker (
  worker_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  team_id INT NOT NULL,
  role WORKER_ROLE NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  middle_name VARCHAR(100),
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  hire_date DATE NOT NULL DEFAULT CURRENT_DATE,
  supervisor_id INT,
  CONSTRAINT FK_Worker_team_id
    FOREIGN KEY (team_id)
      REFERENCES Team(team_id),
  CONSTRAINT FK_Worker_supervisor_id
    FOREIGN KEY (supervisor_id)
      REFERENCES Worker(worker_id),
  CONSTRAINT chk_supervisor_not_self CHECK (supervisor_id IS NULL OR supervisor_id != worker_id)
);

CREATE TABLE Schedule (
  schedule_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  worker_id INT NOT NULL,
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP NOT NULL,
  type SCHEDULE_TYPE NOT NULL,
  CONSTRAINT FK_Schedule_worker_id
    FOREIGN KEY (worker_id)
      REFERENCES Worker(worker_id),
  CONSTRAINT chk_schedule_time CHECK (end_time > start_time)
);

CREATE TABLE Procedure (
  procedure_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  duration INTERVAL NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  required_role WORKER_ROLE NOT NULL,
  CONSTRAINT chk_procedure_price CHECK (price >= 0),
  CONSTRAINT chk_procedure_duration CHECK (duration > INTERVAL '0 minutes')
);

CREATE TABLE Room (
  room_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  facility_id INT NOT NULL,
  team_id INT,
  room_number VARCHAR(20) NOT NULL,
  type ROOM_TYPE NOT NULL,
  capacity INT NOT NULL,
  status ROOM_STATUS NOT NULL DEFAULT 'available',
  CONSTRAINT FK_Room_facility_id
    FOREIGN KEY (facility_id)
      REFERENCES Facility(facility_id),
  CONSTRAINT FK_Room_team_id
    FOREIGN KEY (team_id)
      REFERENCES Team(team_id),
  CONSTRAINT chk_room_capacity CHECK (capacity > 0),
  CONSTRAINT unq_room_number_facility UNIQUE (facility_id, room_number)
);

CREATE TABLE Appointment (
  appointment_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  room_id INT NOT NULL,
  worker_id INT NOT NULL,
  patient_id INT NOT NULL,
  procedure_id INT NOT NULL,
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP NOT NULL,
  status APPOINTMENT_STATUS NOT NULL DEFAULT 'scheduled',
  notes TEXT,
  CONSTRAINT FK_Appointment_patient_id
    FOREIGN KEY (patient_id)
      REFERENCES Patient(patient_id),
  CONSTRAINT FK_Appointment_procedure_id
    FOREIGN KEY (procedure_id)
      REFERENCES Procedure(procedure_id),
  CONSTRAINT FK_Appointment_worker_id
    FOREIGN KEY (worker_id)
      REFERENCES Worker(worker_id),
  CONSTRAINT FK_Appointment_room_id
    FOREIGN KEY (room_id)
      REFERENCES Room(room_id),
  CONSTRAINT chk_appointment_time CHECK (end_time > start_time)
);

CREATE TABLE Result (
  result_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  appointment_id INT NOT NULL UNIQUE,
  summary TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT FK_Result_appointment_id
    FOREIGN KEY (appointment_id)
      REFERENCES Appointment(appointment_id)
);

CREATE TABLE Equipment (
  equipment_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  room_id INT NOT NULL,
  name VARCHAR(255) NOT NULL,
  serial_number VARCHAR(100) UNIQUE,
  status EQUIPMENT_STATUS NOT NULL DEFAULT 'operational',
  last_maintenance DATE,
  CONSTRAINT FK_Equipment_room_id
    FOREIGN KEY (room_id)
      REFERENCES Room(room_id)
);