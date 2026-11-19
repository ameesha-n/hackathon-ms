USE hackathon_db;
-- ===== AUTH + RBAC TABLES =====
CREATE TABLE role (role_id INT PRIMARY KEY AUTO_INCREMENT, role_name VARCHAR(20) NOT NULL UNIQUE);
CREATE TABLE app_user (
  user_id INT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(100) NOT NULL,
  role_id INT NOT NULL,
  participant_id INT NULL, judge_id INT NULL,
  FOREIGN KEY (role_id) REFERENCES role(role_id),
  FOREIGN KEY (participant_id) REFERENCES participant(participant_id),
  FOREIGN KEY (judge_id) REFERENCES judge(judge_id),
  CHECK (participant_id IS NULL OR judge_id IS NULL)
);
CREATE TABLE audit_log (log_id INT PRIMARY KEY AUTO_INCREMENT, action VARCHAR(40), details VARCHAR(200), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO role (role_name) VALUES ('admin'),('judge'),('participant');

-- ===== DATABASE-LEVEL RBAC (MySQL 8 roles) =====
CREATE ROLE IF NOT EXISTS 'r_admin','r_judge','r_participant';
GRANT ALL ON hackathon_db.* TO 'r_admin';
GRANT SELECT ON hackathon_db.* TO 'r_judge';
GRANT INSERT, UPDATE ON hackathon_db.score TO 'r_judge';
GRANT SELECT ON hackathon_db.leaderboard TO 'r_participant';
GRANT SELECT ON hackathon_db.team TO 'r_participant';
GRANT SELECT ON hackathon_db.project TO 'r_participant';
GRANT INSERT ON hackathon_db.team_member TO 'r_participant';

-- ===== FUNCTION, PROCEDURE, TRIGGER =====
DELIMITER //
CREATE FUNCTION fn_project_avg(p_id INT) RETURNS DECIMAL(5,2) READS SQL DATA
BEGIN
  RETURN (SELECT ROUND(AVG(innovation + technical + impact), 2) FROM score WHERE project_id = p_id);
END//
CREATE PROCEDURE sp_register_team(IN p_name VARCHAR(60), IN p_hack INT, IN p_lead INT)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  INSERT INTO team (team_name, hackathon_id) VALUES (p_name, p_hack);
  INSERT INTO team_member VALUES (LAST_INSERT_ID(), p_lead, TRUE);
  COMMIT;
END//
CREATE TRIGGER trg_score_audit AFTER INSERT ON score FOR EACH ROW
  INSERT INTO audit_log (action, details)
  VALUES ('SCORE_ADDED', CONCAT('project ', NEW.project_id, ' by judge ', NEW.judge_id))//
DELIMITER ;
-- (trg_team_size from 01_schema.sql is the second trigger)

-- ===== DML =====
INSERT INTO participant (name, email, college) VALUES ('Tanya Bose','tanya@mail.com','PES');
UPDATE participant SET college = 'RVCE' WHERE email = 'tanya@mail.com';
DELETE FROM participant WHERE email = 'tanya@mail.com';
CALL sp_register_team('DataDragons', 1, 9);
SELECT title, fn_project_avg(project_id) AS avg_score FROM project;

-- ===== NESTED / CORRELATED / RECURSIVE / CTE / JOIN =====
-- Nested: participants whose team submitted a project
SELECT name FROM participant WHERE participant_id IN
  (SELECT participant_id FROM team_member WHERE team_id IN (SELECT team_id FROM project));
-- Correlated: scores above that project's own average
SELECT j.name AS judge, p.title, s.innovation + s.technical + s.impact AS total
FROM score s JOIN judge j ON j.judge_id = s.judge_id JOIN project p ON p.project_id = s.project_id
WHERE s.innovation + s.technical + s.impact >
  (SELECT AVG(s2.innovation + s2.technical + s2.impact) FROM score s2 WHERE s2.project_id = s.project_id);
-- Recursive CTE: day-by-day schedule of a hackathon
WITH RECURSIVE days AS (
  SELECT hackathon_id, start_date AS d, end_date AS e FROM hackathon WHERE hackathon_id = 1
  UNION ALL SELECT hackathon_id, d + INTERVAL 1 DAY, e FROM days WHERE d < e)
SELECT hackathon_id, d AS event_day FROM days;
-- CTE + window function: ranking
WITH totals AS (SELECT project_id, AVG(innovation + technical + impact) AS a FROM score GROUP BY project_id)
SELECT p.title, ROUND(t.a, 2) AS avg_total, RANK() OVER (ORDER BY t.a DESC) AS rnk
FROM totals t JOIN project p ON p.project_id = t.project_id;
-- Multi-table JOIN: participant to hackathon with project
SELECT pa.name, t.team_name, p.title, h.name AS hackathon
FROM participant pa JOIN team_member tm ON tm.participant_id = pa.participant_id
JOIN team t ON t.team_id = tm.team_id JOIN hackathon h ON h.hackathon_id = t.hackathon_id
LEFT JOIN project p ON p.team_id = t.team_id;


-- ===== DB USERS FOR RBAC =====
CREATE USER IF NOT EXISTS 'admin_user'@'%' IDENTIFIED BY 'Admin@123';
CREATE USER IF NOT EXISTS 'judge_user'@'%' IDENTIFIED BY 'Judge@123';
CREATE USER IF NOT EXISTS 'part_user'@'%' IDENTIFIED BY 'Part@123';
GRANT 'r_admin' TO 'admin_user'@'%';
GRANT 'r_judge' TO 'judge_user'@'%';
GRANT 'r_participant' TO 'part_user'@'%';
SET DEFAULT ROLE ALL TO 'admin_user'@'%','judge_user'@'%','part_user'@'%';
