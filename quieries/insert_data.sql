COPY Facility(facility_id, name, type, location)
    FROM '/import/Facility.csv' DELIMITER ',' CSV HEADER;

COPY Team(team_id, name, specialization, created_at)
    FROM '/import/Team.csv' DELIMITER ',' CSV HEADER;

COPY Patient(patient_id, first_name, last_name, date_of_birth, phone_number, email)
    FROM '/import/Patient.csv' DELIMITER ',' CSV HEADER;

COPY Worker(worker_id, team_id, role, first_name, middle_name, last_name, email, hire_date, supervisor_id)
    FROM '/import/Worker.csv' DELIMITER ',' CSV HEADER;

COPY Schedule(schedule_id, worker_id, start_time, end_time, type)
    FROM '/import/Schedule.csv' DELIMITER ',' CSV HEADER;

COPY Procedure(procedure_id, name, duration, price, required_role)
    FROM '/import/Procedure.csv' DELIMITER ',' CSV HEADER;

COPY Room(room_id, facility_id, team_id, room_number, type, capacity, status)
    FROM '/import/Room.csv' DELIMITER ',' CSV HEADER;

COPY Appointment(appointment_id, room_id, worker_id, patient_id, procedure_id, start_time, end_time, status, notes)
    FROM '/import/Appointment.csv' DELIMITER ',' CSV HEADER;

COPY Result(result_id, appointment_id, summary, created_at)
    FROM '/import/Result.csv' DELIMITER ',' CSV HEADER;

COPY Equipment(equipment_id, room_id, name, serial_number, status, last_maintenance)
    FROM '/import/Equipment.csv' DELIMITER ',' CSV HEADER;