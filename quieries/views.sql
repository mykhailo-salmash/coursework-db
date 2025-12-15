-- 7.4.1) Дозволяє отримати зведену інформацію про завантаженість лікарів: 
-- кількість запланованих, завершених та скасованих прийомів. 
CREATE OR REPLACE VIEW view_doctor_workload AS
SELECT
    w.worker_id,
    w.first_name || ' ' || w.last_name AS doctor_name,
    t.name AS team_name,
    COUNT(CASE WHEN a.status = 'scheduled' THEN 1 END) AS scheduled,
    COUNT(CASE WHEN a.status = 'completed' THEN 1 END) AS completed,
    COUNT(CASE WHEN a.status = 'cancelled' THEN 1 END) AS cancelled
FROM Worker w
JOIN Team t ON w.team_id = t.team_id
LEFT JOIN Appointment a ON w.worker_id = a.worker_id
WHERE w.role = 'doctor'
GROUP BY w.worker_id, w.first_name, w.last_name, t.name;


-- 7.4.2) Надає адміністраторам зручний "Dashboard" на поточний день. 
-- Показує час, пацієнта, лікаря та статус.
CREATE OR REPLACE VIEW view_daily_schedule_dashboard AS
SELECT
    a.start_time,
    a.end_time,
    r.room_number,
    p.first_name || ' ' || p.last_name AS patient,
    w.last_name AS doctor,
    pr.name AS procedure,
    a.status
FROM Appointment a
JOIN Room r ON a.room_id = r.room_id
JOIN Patient p ON a.patient_id = p.patient_id
JOIN Worker w ON a.worker_id = w.worker_id
JOIN Procedure pr ON a.procedure_id = pr.procedure_id
WHERE a.start_time::DATE = '2024-11-01' -- У реальній системі тут буде CURRENT_DATE
ORDER BY a.start_time;

-- 7.4.3) Дозволяє фінансовому відділу аналізувати прибутковість різних медичних
-- напрямків. Підсумовує дохід від завершених процедур за спеціалізаціями.
CREATE OR REPLACE VIEW view_financial_performance_by_specialization AS
SELECT
    t.specialization,
    COUNT(a.appointment_id) AS total_procedures,
    SUM(pr.price) AS total_revenue,
    ROUND(AVG(pr.price), 2) AS average_check
FROM Team t
JOIN Worker w ON t.team_id = w.team_id
JOIN Appointment a ON w.worker_id = a.worker_id
JOIN Procedure pr ON a.procedure_id = pr.procedure_id
WHERE a.status = 'completed'
GROUP BY t.specialization
ORDER BY total_revenue DESC;