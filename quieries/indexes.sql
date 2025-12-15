CREATE INDEX idx_appointment_worker_time ON Appointment(worker_id, start_time, end_time);
CREATE INDEX idx_appointment_room_time ON Appointment(room_id, start_time, end_time);
CREATE INDEX idx_appointment_patient_time ON Appointment(patient_id, start_time, end_time);
CREATE INDEX idx_schedule_worker_time ON Schedule(worker_id, start_time, end_time);
CREATE INDEX idx_worker_role ON Worker(role);
CREATE INDEX idx_room_status ON Room(status);