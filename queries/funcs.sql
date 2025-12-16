-- 7.2.1) Дозволяє автоматично розрахувати точний вік пацієнта на поточний момент 
-- часу на основі його дати народження. 
CREATE OR REPLACE FUNCTION calculate_patient_age(p_date_of_birth DATE)
RETURNS INT
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM AGE(CURRENT_DATE, p_date_of_birth));
END;
$$;

-- 7.2.2) Дозволяє зареєструвати новий запис на прийом, автоматично встановлюючи статус
-- "scheduled". 
CREATE OR REPLACE PROCEDURE register_appointment(
    p_room_id INT,
    p_worker_id INT,
    p_patient_id INT,
    p_procedure_id INT,
    p_start_time TIMESTAMP,
    p_end_time TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    BEGIN
        INSERT INTO Appointment (room_id, worker_id, patient_id, procedure_id, start_time, end_time, status)
        VALUES (p_room_id, p_worker_id, p_patient_id, p_procedure_id, p_start_time, p_end_time, 'scheduled');

    EXCEPTION WHEN unique_violation THEN
        PERFORM setval(pg_get_serial_sequence('Appointment', 'appointment_id'), (SELECT MAX(appointment_id) FROM Appointment));

        INSERT INTO Appointment (room_id, worker_id, patient_id, procedure_id, start_time, end_time, status)
        VALUES (p_room_id, p_worker_id, p_patient_id, p_procedure_id, p_start_time, p_end_time, 'scheduled');
    END;
END;
$$;

-- 7.2.3) Повертає таблицю з розкладом конкретного працівника на вказану дату. 
CREATE OR REPLACE FUNCTION get_worker_daily_schedule(p_worker_id INT, p_date DATE)
RETURNS TABLE (
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    schedule_type TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT s.start_time, s.end_time, s.type::TEXT
    FROM Schedule s
    WHERE s.worker_id = p_worker_id
      AND s.start_time::DATE = p_date
    ORDER BY s.start_time;
END;
$$;

-- 7.2.4) Дозволяє перевірити, чи вільна конкретна кімната у заданий проміжок часу. 
-- Функція повертає TRUE, якщо кімната вільна, і FALSE, якщо у цей час там вже 
-- заплановано інший прийом або процедуру.
CREATE OR REPLACE FUNCTION check_room_availability(
    p_room_id INT, 
    p_check_start TIMESTAMP, 
    p_check_end TIMESTAMP
    )
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    is_occupied BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM Appointment a
        WHERE a.room_id = p_room_id
          AND a.status IN ('scheduled', 'in_progress')
          AND (a.start_time < p_check_end AND a.end_time > p_check_start)
    ) INTO is_occupied;

    RETURN NOT is_occupied;
END;
$$;

-- 7.2.5) Дозволяє скасувати запланований візит, змінюючи його статус на 'cancelled' 
-- та додаючи причину скасування до приміток.
CREATE OR REPLACE PROCEDURE cancel_appointment_with_reason(
    p_appointment_id INT,
    p_reason TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Appointment
    SET status = 'cancelled',
        notes = COALESCE(notes, '') || ' [Cancellation Reason: ' || p_reason || ']'
    WHERE appointment_id = p_appointment_id;
END;
$$;

-- 7.2.6) Дозволяє отримати загальну суму доходу закладу за вказаний період часу,
-- базуючись на вартості завершених процедур.
CREATE OR REPLACE FUNCTION calculate_total_revenue_by_period(p_start_date DATE, p_end_date DATE)
RETURNS DECIMAL(10, 2)
LANGUAGE plpgsql
AS $$
DECLARE
    total_revenue DECIMAL(10, 2);
BEGIN
    SELECT COALESCE(SUM(pr.price), 0)
    INTO total_revenue
    FROM Appointment a
    JOIN Procedure pr ON a.procedure_id = pr.procedure_id
    WHERE a.status = 'completed'
      AND a.start_time::DATE BETWEEN p_start_date AND p_end_date;

    RETURN total_revenue;
END;
$$;

-- 7.2.7) Повертає детальну історію візитів пацієнта, включаючи назву процедури, 
-- лікаря, дату та короткий результат.
CREATE OR REPLACE FUNCTION get_patient_history_report(p_patient_id INT)
RETURNS TABLE (
    visit_date DATE,
    procedure_name VARCHAR,
    doctor_name TEXT,
    result_summary TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.start_time::DATE,
        pr.name,
        (w.first_name || ' ' || w.last_name),
        COALESCE(res.summary, 'Результат відсутній')
    FROM Appointment a
    JOIN Procedure pr ON a.procedure_id = pr.procedure_id
    JOIN Worker w ON a.worker_id = w.worker_id
    LEFT JOIN Result res ON a.appointment_id = res.appointment_id
    WHERE a.patient_id = p_patient_id
    ORDER BY a.start_time DESC;
END;
$$;

-- 7.2.8) Дозволяє змінити статус обладнання (наприклад, перевести його в ремонт 
-- або списати) та оновити дату останнього обслуговування. 
CREATE OR REPLACE PROCEDURE update_equipment_status(
    p_equipment_id INT,
    p_new_status EQUIPMENT_STATUS
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Equipment
    SET status = p_new_status,
        last_maintenance = CASE
            WHEN p_new_status = 'maintenance' THEN CURRENT_DATE
            ELSE last_maintenance
        END
    WHERE equipment_id = p_equipment_id;
END;
$$;

-- 7.2.9) Дозволяє перевести працівника до іншої бригади (команди). 
--Процедура оновлює посилання на команду в записі працівника.
CREATE OR REPLACE PROCEDURE transfer_worker_to_team(
    p_worker_id INT,
    p_new_team_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Team WHERE team_id = p_new_team_id) THEN
        RAISE EXCEPTION 'Team with ID % does not exist', p_new_team_id;
    END IF;

    UPDATE Worker
    SET team_id = p_new_team_id
    WHERE worker_id = p_worker_id;
END;
$$;

-- 7.2.10) Дозволяє отримати статистику по закладу: загальну
-- кількість кімнат та кількість одиниць обладнання.
CREATE OR REPLACE FUNCTION get_facility_load_stats(p_facility_id INT)
RETURNS TABLE (
    facility_name VARCHAR,
    total_rooms BIGINT,
    total_equipment BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.name,
        COUNT(DISTINCT r.room_id),
        COUNT(DISTINCT e.equipment_id)
    FROM Facility f
    LEFT JOIN Room r ON f.facility_id = r.facility_id
    LEFT JOIN Equipment e ON r.room_id = e.room_id
    WHERE f.facility_id = p_facility_id
    GROUP BY f.name;
END;
$$;