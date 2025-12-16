-- Адміністратор:
CREATE ROLE admin_role;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_role;
GRANT USAGE ON SCHEMA public TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO admin_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO admin_role;

CREATE USER admin_user WITH PASSWORD 'AdminPass2024!';
GRANT admin_role TO admin_user;

-- Лікар:
CREATE ROLE doctor_role;

GRANT SELECT, INSERT, UPDATE ON Patient, Appointment, Result TO doctor_role;
GRANT SELECT ON Procedure, Worker, Schedule, Room, Equipment, Facility, Team TO doctor_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO doctor_role;
GRANT USAGE ON SCHEMA public TO doctor_role;

CREATE USER doctor_user WITH PASSWORD 'DoctorPass2024!';
GRANT doctor_role TO doctor_user;


-- Медичний персонал:
CREATE ROLE medical_worker_role;

GRANT SELECT ON Patient, Procedure, Worker, Schedule, Room, Equipment, Facility, Team, Appointment, Result TO medical_worker_role;
GRANT UPDATE ON Appointment TO medical_worker_role;
GRANT INSERT ON Result TO medical_worker_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO medical_worker_role;
GRANT USAGE ON SCHEMA public TO medical_worker_role;

CREATE USER medical_worker_user WITH PASSWORD 'MedWorkerPass2024!';
GRANT medical_worker_role TO medical_worker_user;

-- Тест для перевірки:
SELECT 
    u.usename AS username,
    r.rolname AS role
FROM pg_user u
JOIN pg_auth_members m ON u.usesysid = m.member
JOIN pg_roles r ON m.roleid = r.oid
WHERE u.usename IN ('admin_user', 'doctor_user', 'medical_worker_user');