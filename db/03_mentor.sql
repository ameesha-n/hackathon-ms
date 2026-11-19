-- Modification: Mentor feedback module
USE hackathon_db;

CREATE TABLE mentor (
  mentor_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL,
  expertise VARCHAR(60)
);

CREATE TABLE feedback (                -- resolves Project M:N Mentor
  feedback_id INT PRIMARY KEY AUTO_INCREMENT,
  project_id INT NOT NULL,
  mentor_id INT NOT NULL,
  rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment VARCHAR(300),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES project(project_id) ON DELETE CASCADE,
  FOREIGN KEY (mentor_id) REFERENCES mentor(mentor_id) ON DELETE CASCADE
);

INSERT INTO mentor (name, expertise) VALUES ('Sanjay Rao','Backend'), ('Neha Kapoor','Design');
INSERT INTO feedback (project_id, mentor_id, rating, comment) VALUES
 (1,1,4,'Solid data pipeline, add error handling'),
 (1,2,5,'Clean UX for farmers'),
 (2,1,5,'Great use of hashing for records'),
 (3,2,3,'Dashboard needs clearer visuals'),
 (4,1,4,'Good idea, validate crowd reports');

-- 4th application role + link from login table to mentor
INSERT INTO role (role_name) VALUES ('mentor');
ALTER TABLE app_user
  ADD COLUMN mentor_id INT NULL,
  ADD CONSTRAINT fk_user_mentor FOREIGN KEY (mentor_id) REFERENCES mentor(mentor_id);

-- View: feedback summary per project
CREATE VIEW project_feedback AS
SELECT p.project_id, p.title, t.team_name,
       COUNT(f.feedback_id) AS reviews,
       ROUND(AVG(f.rating), 2) AS avg_rating
FROM project p
JOIN team t ON t.team_id = p.team_id
LEFT JOIN feedback f ON f.project_id = p.project_id
GROUP BY p.project_id, p.title, t.team_name;

-- Trigger: log every new feedback in the audit table
CREATE TRIGGER trg_feedback_audit AFTER INSERT ON feedback FOR EACH ROW
  INSERT INTO audit_log (action, details)
  VALUES ('FEEDBACK_ADDED', CONCAT('project ', NEW.project_id, ' by mentor ', NEW.mentor_id));

-- Database-level RBAC for the new role
CREATE ROLE IF NOT EXISTS 'r_mentor';
GRANT SELECT ON hackathon_db.* TO 'r_mentor';
GRANT INSERT, UPDATE ON hackathon_db.feedback TO 'r_mentor';
GRANT SELECT ON hackathon_db.project_feedback TO 'r_participant';
CREATE USER IF NOT EXISTS 'mentor_user'@'%' IDENTIFIED BY 'Mentor@123';
GRANT 'r_mentor' TO 'mentor_user'@'%';
SET DEFAULT ROLE ALL TO 'mentor_user'@'%';
