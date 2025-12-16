-- 1) Запит на отримання списку всіх пацієнтів разом з їх призначеними
-- прийомами та інформацією про процедури.
SELECT
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.phone_number,
    a.appointment_id,
    a.start_time,
    pr.name AS procedure_name,
    pr.price,
    a.status
FROM Patient p
INNER JOIN Appointment a ON p.patient_id = a.patient_id
INNER JOIN Procedure pr ON a.procedure_id = pr.procedure_id
WHERE a.status = 'scheduled'
ORDER BY a.start_time
LIMIT 20;


-- 2) Запит на отримання списку працівників з інформацією 
-- про їх команду та супервайзера.
SELECT
    w.worker_id,
    w.first_name || ' ' || w.middle_name || ' ' || w.last_name AS worker_name,
    w.role,
    w.email,
    w.hire_date,
    t.name AS team_name,
    t.specialization,
    s.first_name || ' ' || s.last_name AS supervisor_name
FROM Worker w
INNER JOIN Team t ON w.team_id = t.team_id
LEFT JOIN Worker s ON w.supervisor_id = s.worker_id
ORDER BY t.name, w.last_name
LIMIT 30;


-- 3) Запит на отримання списку кімнат з інформацією про
-- обладнання та медичний заклад.
SELECT
    r.room_id,
    r.room_number,
    r.type AS room_type,
    r.status AS room_status,
    r.capacity,
    f.name AS facility_name,
    f.type AS facility_type,
    e.name AS equipment_name,
    e.serial_number,
    e.status AS equipment_status
FROM Room r
INNER JOIN Facility f ON r.facility_id = f.facility_id
INNER JOIN Equipment e ON r.room_id = e.room_id
ORDER BY f.name, r.room_number
LIMIT 30;


-- 4) Запит на отримання списку завершених прийомів з результатами,
-- інформацією про пацієнта та працівника. 
SELECT
    a.appointment_id,
    a.start_time,
    a.end_time,
    a.status,
    p.first_name || ' ' || p.last_name AS patient_name,
    w.first_name || ' ' || w.last_name AS worker_name,
    w.role,
    r.room_number,
    pr.name AS procedure_name,
    res.summary AS result_summary
FROM Appointment a
INNER JOIN Patient p ON a.patient_id = p.patient_id
INNER JOIN Worker w ON a.worker_id = w.worker_id
INNER JOIN Room r ON a.room_id = r.room_id
INNER JOIN Procedure pr ON a.procedure_id = pr.procedure_id
LEFT JOIN Result res ON a.appointment_id = res.appointment_id
WHERE a.status = 'completed'
ORDER BY a.start_time DESC
LIMIT 25;


-- 5) Запит на отримання статистики кількості прийомів та 
-- загальної вартості процедур для кожного пацієнта.
SELECT
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.email,
    COUNT(a.appointment_id) AS total_appointments,
    COUNT(CASE WHEN a.status = 'completed' THEN 1 END) AS completed_appointments,
    COUNT(CASE WHEN a.status = 'cancelled' THEN 1 END) AS cancelled_appointments,
    ROUND(SUM(pr.price)::NUMERIC, 2) AS total_spent,
    ROUND(AVG(pr.price)::NUMERIC, 2) AS avg_procedure_cost
FROM Patient p
INNER JOIN Appointment a ON p.patient_id = a.patient_id
INNER JOIN Procedure pr ON a.procedure_id = pr.procedure_id
GROUP BY p.patient_id, p.first_name, p.last_name, p.email
HAVING COUNT(a.appointment_id) >= 1
ORDER BY total_spent DESC
LIMIT 20;



-- 6) Запит на отримання статистики завантаженості працівників
-- з підрахунком кількості прийомів.
SELECT
    w.worker_id,
    w.first_name || ' ' || w.last_name AS worker_name,
    w.role,
    t.name AS team_name,
    COUNT(a.appointment_id) AS total_appointments,
    COUNT(CASE WHEN a.status = 'completed' THEN 1 END) AS completed_count,
    COUNT(CASE WHEN a.status = 'cancelled' THEN 1 END) AS cancelled_count,
    ROUND(AVG(pr.price)::NUMERIC, 2) AS avg_procedure_price
FROM Worker w
INNER JOIN Team t ON w.team_id = t.team_id
LEFT JOIN Appointment a ON w.worker_id = a.worker_id
LEFT JOIN Procedure pr ON a.procedure_id = pr.procedure_id
GROUP BY w.worker_id, w.first_name, w.last_name, w.role, t.name
HAVING COUNT(a.appointment_id) >= 1
ORDER BY total_appointments DESC
LIMIT 20;


-- 7) Запит на отримання статистики використання кімнат 
-- з підрахунком кількості прийомів.
SELECT
    r.room_id,
    r.room_number,
    r.type,
    r.capacity,
    f.name AS facility_name,
    COUNT(a.appointment_id) AS appointments_count,
    MIN(a.start_time) AS first_appointment,
    MAX(a.end_time) AS last_appointment
FROM Room r
INNER JOIN Facility f ON r.facility_id = f.facility_id
LEFT JOIN Appointment a ON r.room_id = a.room_id
GROUP BY r.room_id, r.room_number, r.type, r.capacity, f.name
HAVING COUNT(a.appointment_id) >= 1
ORDER BY appointments_count DESC
LIMIT 20;


-- 8) Запит на отримання рейтингу найпопулярніших процедур з 
-- підрахунком кількості призначень та загального доходу.
SELECT
    pr.procedure_id,
    pr.name AS procedure_name,
    pr.required_role,
    pr.price,
    COUNT(a.appointment_id) AS times_performed,
    ROUND(SUM(pr.price)::NUMERIC, 2) AS total_revenue,
    COUNT(DISTINCT a.patient_id) AS unique_patients,
    COUNT(DISTINCT a.worker_id) AS workers_performed
FROM Procedure pr
INNER JOIN Appointment a ON pr.procedure_id = a.procedure_id
GROUP BY pr.procedure_id, pr.name, pr.required_role, pr.price
HAVING COUNT(a.appointment_id) >= 1
ORDER BY total_revenue DESC, times_performed DESC
LIMIT 20;


-- 9) Запит на отримання списку працівників, які мають більше прийомів, 
-- ніж середня кількість прийомів по всіх працівниках.
SELECT
    w.worker_id,
    w.first_name || ' ' || w.last_name AS worker_name,
    w.role,
    w.email,
    COUNT(a.appointment_id) AS appointments_count
FROM Worker w
INNER JOIN Appointment a ON w.worker_id = a.worker_id
GROUP BY w.worker_id, w.first_name, w.last_name, w.role, w.email
HAVING COUNT(a.appointment_id) > (
    SELECT AVG(app_count)
    FROM (
        SELECT COUNT(*) AS app_count
        FROM Appointment
        GROUP BY worker_id
    ) AS avg_appointments
)
ORDER BY appointments_count DESC;


-- 10) Запит на отримання інформації про пацієнтів з 
-- підрахунком їх загальних витрат.
SELECT
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.date_of_birth,
    p.phone_number,
    (
        SELECT COUNT(*)
        FROM Appointment a
        WHERE a.patient_id = p.patient_id
    ) AS total_appointments,
    (
        SELECT ROUND(SUM(pr.price)::NUMERIC, 2)
        FROM Appointment a
        INNER JOIN Procedure pr ON a.procedure_id = pr.procedure_id
        WHERE a.patient_id = p.patient_id AND a.status = 'completed'
    ) AS total_spent,
    (
        SELECT ROUND(MAX(pr.price)::NUMERIC, 2)
        FROM Appointment a
        INNER JOIN Procedure pr ON a.procedure_id = pr.procedure_id
        WHERE a.patient_id = p.patient_id
    ) AS most_expensive_procedure
FROM Patient p
WHERE EXISTS (
    SELECT 1
    FROM Appointment a
    WHERE a.patient_id = p.patient_id
)
ORDER BY total_spent DESC NULLS LAST
LIMIT 20;


-- 11) Запит на отримання списку команд, в яких працюють лікарі, що проводили
-- процедури дорожчі за 300 грошових одиниць.
SELECT DISTINCT
    t.team_id,
    t.name AS team_name,
    t.specialization,
    t.created_at,
    COUNT(DISTINCT w.worker_id) AS doctors_count
FROM Team t
INNER JOIN Worker w ON t.team_id = w.team_id
WHERE w.worker_id IN (
    SELECT DISTINCT a.worker_id
    FROM Appointment a
    INNER JOIN Procedure pr ON a.procedure_id = pr.procedure_id
    WHERE pr.price > 300
)
AND w.role = 'doctor'
GROUP BY t.team_id, t.name, t.specialization, t.created_at
ORDER BY doctors_count DESC;


-- 12) Запит на отримання списку медичних закладів з
-- статистикою по кімнатах та обладнанню.
SELECT
    f.facility_id,
    f.name AS facility_name,
    f.type,
    room_stats.rooms_count,
    room_stats.total_equipment,
    ROUND(room_stats.avg_equipment_per_room::NUMERIC, 2) AS avg_equipment_per_room
FROM Facility f
INNER JOIN (
    SELECT
        r.facility_id,
        COUNT(DISTINCT r.room_id) AS rooms_count,
        COUNT(e.equipment_id) AS total_equipment,
        AVG(eq_count.equipment_count) AS avg_equipment_per_room
    FROM Room r
    LEFT JOIN Equipment e ON r.room_id = e.room_id
    LEFT JOIN (
        SELECT room_id, COUNT(*) AS equipment_count
        FROM Equipment
        GROUP BY room_id
    ) AS eq_count ON r.room_id = eq_count.room_id
    GROUP BY r.facility_id
) AS room_stats ON f.facility_id = room_stats.facility_id
ORDER BY room_stats.total_equipment DESC;


-- 13) Запит на отримання статистики прийомів по статусах з 
-- розподілом за типами процедур.
SELECT
    a.status,
    COUNT(*) AS total_appointments,
    COUNT(DISTINCT a.patient_id) AS unique_patients,
    COUNT(DISTINCT a.worker_id) AS unique_workers,
    ROUND(AVG(pr.price)::NUMERIC, 2) AS avg_price,
    ROUND(SUM(CASE WHEN a.status = 'completed' THEN pr.price ELSE 0 END)::NUMERIC, 2) AS revenue
FROM Appointment a
INNER JOIN Procedure pr ON a.procedure_id = pr.procedure_id
GROUP BY a.status
ORDER BY total_appointments DESC;


-- 14) Запит на отримання списку працівників з категоризацією 
-- за рівнем досвіду та завантаженості.
SELECT
    w.worker_id,
    w.first_name || ' ' || w.last_name AS worker_name,
    w.role,
    w.hire_date,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, w.hire_date)) AS years_experience,
    CASE
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, w.hire_date)) < 1 THEN 'Junior'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, w.hire_date)) BETWEEN 1 AND 5 THEN 'Middle'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, w.hire_date)) > 5 THEN 'Senior'
    END AS experience_level,
    COUNT(a.appointment_id) AS total_appointments,
    CASE
        WHEN COUNT(a.appointment_id) = 0 THEN 'No workload'
        WHEN COUNT(a.appointment_id) < 5 THEN 'Low workload'
        WHEN COUNT(a.appointment_id) BETWEEN 5 AND 15 THEN 'Medium workload'
        WHEN COUNT(a.appointment_id) > 15 THEN 'High workload'
    END AS workload_category
FROM Worker w
LEFT JOIN Appointment a ON w.worker_id = a.worker_id
GROUP BY w.worker_id, w.first_name, w.last_name, w.role, w.hire_date
ORDER BY years_experience DESC, total_appointments DESC
LIMIT 30;


-- 15) Запит на отримання звіту про статус обладнання з 
-- категоризацією за необхідністю обслуговування.
SELECT
    e.equipment_id,
    e.name AS equipment_name,
    e.serial_number,
    e.status,
    r.room_number,
    f.name AS facility_name,
    CASE
        WHEN e.status = 'operational' THEN 'Працює нормально'
        WHEN e.status = 'maintenance' THEN 'На обслуговуванні'
        WHEN e.status = 'broken' THEN 'Зламане'
        WHEN e.status = 'decommissioned' THEN 'Списано'
    END AS status_description
FROM Equipment e
INNER JOIN Room r ON e.room_id = r.room_id
INNER JOIN Facility f ON r.facility_id = f.facility_id
ORDER BY e.status, f.name
LIMIT 30;


-- 16) Запит на отримання рейтингу працівників за кількістю 
-- виконаних прийомів в кожній команді з ранжуванням.
SELECT
    w.worker_id,
    w.first_name || ' ' || w.last_name AS worker_name,
    w.role,
    t.name AS team_name,
    COUNT(a.appointment_id) AS appointments_completed,
    RANK() OVER (PARTITION BY t.team_id ORDER BY COUNT(a.appointment_id) DESC) AS rank_in_team,
    ROUND(
        COUNT(a.appointment_id)::NUMERIC /
        NULLIF(SUM(COUNT(a.appointment_id)) OVER (PARTITION BY t.team_id), 0) * 100,
        2
    ) AS percentage_in_team
FROM Worker w
INNER JOIN Team t ON w.team_id = t.team_id
LEFT JOIN Appointment a ON w.worker_id = a.worker_id
GROUP BY w.worker_id, w.first_name, w.last_name, w.role, t.team_id, t.name
ORDER BY t.name, rank_in_team
LIMIT 30;


-- 17) Запит на отримання історії прийомів пацієнта з нумерацією візитів.
SELECT
    a.appointment_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    a.start_time,
    pr.name AS procedure_name,
    a.status,
    ROW_NUMBER() OVER (PARTITION BY p.patient_id ORDER BY a.start_time) AS visit_number
FROM Appointment a
INNER JOIN Patient p ON a.patient_id = p.patient_id
INNER JOIN Procedure pr ON a.procedure_id = pr.procedure_id
ORDER BY p.patient_id, a.start_time
LIMIT 40;


-- 18) Запит на отримання списку медичних закладів з інформацією про команди, кімнати та обладнання.
SELECT
    f.facility_id,
    f.name AS facility_name,
    f.type,
    COUNT(DISTINCT r.room_id) AS total_rooms,
    COUNT(DISTINCT t.team_id) AS total_teams,
    COUNT(DISTINCT e.equipment_id) AS total_equipment,
    COUNT(DISTINCT CASE WHEN r.status = 'available' THEN r.room_id END) AS available_rooms,
    COUNT(DISTINCT CASE WHEN e.status = 'operational' THEN e.equipment_id END) AS operational_equipment
FROM Facility f
LEFT JOIN Room r ON f.facility_id = r.facility_id
LEFT JOIN Team t ON r.team_id = t.team_id
LEFT JOIN Equipment e ON r.room_id = e.room_id
GROUP BY f.facility_id, f.name, f.type
ORDER BY total_rooms DESC;


-- 19) Запит на отримання аналізу вікової структури пацієнтів з розподілом за віковими групами.
SELECT
    CASE
        WHEN EXTRACT(YEAR FROM AGE(CAST(p.date_of_birth AS DATE))) < 18 THEN '0-17 (Дитячий)'
        WHEN EXTRACT(YEAR FROM AGE(CAST(p.date_of_birth AS DATE))) BETWEEN 18 AND 35 THEN '18-35 (Молодий)'
        WHEN EXTRACT(YEAR FROM AGE(CAST(p.date_of_birth AS DATE))) BETWEEN 36 AND 55 THEN '36-55 (Середній)'
        WHEN EXTRACT(YEAR FROM AGE(CAST(p.date_of_birth AS DATE))) > 55 THEN '55+ (Літній)'
    END AS age_group,
    COUNT(DISTINCT p.patient_id) AS patients_count,
    COUNT(a.appointment_id) AS total_appointments,
    ROUND(AVG(EXTRACT(YEAR FROM AGE(CAST(p.date_of_birth AS DATE))))::NUMERIC, 1) AS avg_age,
    ROUND(SUM(pr.price)::NUMERIC, 2) AS total_revenue
FROM Patient p
LEFT JOIN Appointment a ON p.patient_id = a.patient_id
LEFT JOIN Procedure pr ON a.procedure_id = pr.procedure_id
GROUP BY age_group
ORDER BY avg_age;


-- 20) Запит на отримання графіка роботи працівників з перевіркою робочого навантаження.
SELECT
    w.worker_id,
    w.first_name || ' ' || w.last_name AS worker_name,
    w.role,
    s.schedule_id,
    s.start_time,
    s.end_time,
    s.type AS schedule_type,
    COUNT(a.appointment_id) AS appointments_during_shift
FROM Worker w
INNER JOIN Schedule s ON w.worker_id = s.worker_id
LEFT JOIN Appointment a ON w.worker_id = a.worker_id
    AND a.start_time >= s.start_time
    AND a.end_time <= s.end_time
WHERE s.type = 'work_shift'
GROUP BY w.worker_id, w.first_name, w.last_name, w.role, s.schedule_id, s.start_time, s.end_time, s.type
ORDER BY w.worker_id, s.start_time
LIMIT 30;