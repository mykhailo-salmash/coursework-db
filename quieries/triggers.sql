
-- 7.3.1) Цей тригер забезпечує логічну цілісність даних, забороняючи 
-- створення нових записів на прийом (Appointment) у минулому часі.
CREATE OR REPLACE FUNCTION check_appointment_date()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.start_time < CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'Не можна створити запис на прийом у минулому часі: %', NEW.start_time;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_past_appointments
BEFORE INSERT ON Appointment
FOR EACH ROW
EXECUTE FUNCTION check_appointment_date();



-- 7.3.2) Цей тригер автоматизує зміну статусу прийому. Коли лікар вносить 
-- результати обстеження (додає запис у таблицю Result), статус відповідного
-- прийому в таблиці Appointment автоматично змінюється на 'completed'.
CREATE OR REPLACE FUNCTION update_appointment_on_result()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Appointment
    SET status = 'completed'
    WHERE appointment_id = NEW.appointment_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_complete_appointment
AFTER INSERT ON Result
FOR EACH ROW
EXECUTE FUNCTION update_appointment_on_result();



-- 7.3.3) Забезпечує стандартизацію контактних даних пацієнтів.
-- Перед додаванням або оновленням запису пацієнта тригер автоматично 
-- переводить адресу електронної пошти в нижній регістр.
CREATE OR REPLACE FUNCTION lowercase_patient_email()
RETURNS TRIGGER AS $$
BEGIN
    NEW.email := LOWER(NEW.email);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_email_lowercase
BEFORE INSERT OR UPDATE ON Patient
FOR EACH ROW
EXECUTE FUNCTION lowercase_patient_email();



-- 7.3.4) Цей тригер підтримує посилальну цілісність та операційну безпеку. Він забороняє 
-- видалення співробітника (Worker), якщо у нього є заплановані (не завершені) прийоми. Це 
-- запобігає ситуаціям, коли пацієнти приходять на прийом до лікаря, якого вже немає в системі.
CREATE OR REPLACE FUNCTION check_worker_dependencies()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM Appointment
        WHERE worker_id = OLD.worker_id
        AND status IN ('scheduled', 'in_progress')
    ) THEN
        RAISE EXCEPTION 'Не можна видалити співробітника з активними записами на прийом.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_worker_deletion_with_appointments
BEFORE DELETE ON Worker
FOR EACH ROW
EXECUTE FUNCTION check_worker_dependencies();



-- 7.3.5) Цей тригер веде аудит скасувань. Якщо статус прийому змінюється 
-- на 'cancelled', тригер автоматично додає до поля `notes` мітку часу.
CREATE OR REPLACE FUNCTION audit_cancellation()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
        NEW.notes := COALESCE(NEW.notes, '') || ' [Cancelled at ' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM-DD HH24:MI') || ']';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_appointment_cancellation
BEFORE UPDATE ON Appointment
FOR EACH ROW
EXECUTE FUNCTION audit_cancellation();