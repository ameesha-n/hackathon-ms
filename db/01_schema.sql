-- Hackathon Management System (MySQL 8)
DROP DATABASE IF EXISTS hackathon_db;
CREATE DATABASE hackathon_db;
USE hackathon_db;

-- ========== DDL ==========
CREATE TABLE hackathon (
  hackathon_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  city VARCHAR(60),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  CHECK (end_date >= start_date)
);
CREATE TABLE participant (
  participant_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  college VARCHAR(80)
);
CREATE TABLE team (
  team_id INT PRIMARY KEY AUTO_INCREMENT,
  team_name VARCHAR(60) NOT NULL,
  hackathon_id INT NOT NULL,
  UNIQUE (team_name, hackathon_id),
  FOREIGN KEY (hackathon_id) REFERENCES hackathon(hackathon_id) ON DELETE CASCADE
);
CREATE TABLE team_member (            -- resolves Team M:N Participant
  team_id INT,
  participant_id INT,
  is_lead BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (team_id, participant_id),
  FOREIGN KEY (team_id) REFERENCES team(team_id) ON DELETE CASCADE,
  FOREIGN KEY (participant_id) REFERENCES participant(participant_id) ON DELETE CASCADE
);
CREATE TABLE project (
  project_id INT PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(100) NOT NULL,
  track VARCHAR(40),
  repo_url VARCHAR(200),
  team_id INT NOT NULL UNIQUE,        -- 1 team : 1 project
  FOREIGN KEY (team_id) REFERENCES team(team_id) ON DELETE CASCADE
);
CREATE TABLE judge (
  judge_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL,
  expertise VARCHAR(60)
);
CREATE TABLE score (                  -- resolves Project M:N Judge
  project_id INT,
  judge_id INT,
  innovation TINYINT CHECK (innovation BETWEEN 0 AND 10),
  technical  TINYINT CHECK (technical  BETWEEN 0 AND 10),
  impact     TINYINT CHECK (impact     BETWEEN 0 AND 10),
  PRIMARY KEY (project_id, judge_id),
  FOREIGN KEY (project_id) REFERENCES project(project_id) ON DELETE CASCADE,
  FOREIGN KEY (judge_id) REFERENCES judge(judge_id) ON DELETE CASCADE
);
CREATE TABLE sponsor (
  sponsor_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL
);
CREATE TABLE sponsorship (            -- resolves Hackathon M:N Sponsor
  hackathon_id INT,
  sponsor_id INT,
  amount DECIMAL(10,2) NOT NULL,
  tier ENUM('Gold','Silver','Bronze'),
  PRIMARY KEY (hackathon_id, sponsor_id),
  FOREIGN KEY (hackathon_id) REFERENCES hackathon(hackathon_id),
  FOREIGN KEY (sponsor_id) REFERENCES sponsor(sponsor_id)
);

-- ========== SEED DATA ==========
INSERT INTO hackathon (name, city, start_date, end_date) VALUES
 ('HackBLR 2026','Bengaluru','2026-12-05','2026-12-07'),
 ('CodeSprint 2025','Mysuru','2025-03-14','2025-03-16');
INSERT INTO participant (name, email, college) VALUES
 ('Aarav Rao','aarav@mail.com','RVCE'),('Diya Nair','diya@mail.com','PES'),
 ('Karan Mehta','karan@mail.com','BMS'),('Sneha Iyer','sneha@mail.com','RVCE'),
 ('Rohan Das','rohan@mail.com','PES'),('Ishita Jain','ishita@mail.com','IISc'),
 ('Vikram Shetty','vikram@mail.com','BMS'),('Meera Pillai','meera@mail.com','IISc'),
 ('Nikhil Hegde','nikhil@mail.com','RVCE');          -- not in any team
INSERT INTO team (team_name, hackathon_id) VALUES
 ('ByteBandits',1),('NeuralNinjas',1),('CloudCrafters',1),('PixelPirates',1);
INSERT INTO team_member VALUES
 (1,1,TRUE),(1,2,FALSE),(2,3,TRUE),(2,4,FALSE),(2,5,FALSE),
 (3,6,TRUE),(3,7,FALSE),(4,8,TRUE);
INSERT INTO project (title, track, repo_url, team_id) VALUES
 ('AgriSense','AI/ML','github.com/bb/agrisense',1),
 ('MediChain','HealthTech','github.com/nn/medichain',2),
 ('GreenGrid','Sustainability','github.com/cc/greengrid',3),
 ('SafeRoute','Social Good','github.com/pp/saferoute',4);
INSERT INTO judge (name, expertise) VALUES
 ('Dr. Anita Kulkarni','AI'),('Rahul Verma','Cloud'),('Priya Menon','Product');
INSERT INTO score VALUES
 (1,1,8,9,8),(1,2,7,8,9),(1,3,9,8,8),
 (2,1,9,9,9),(2,2,8,9,9),(2,3,9,10,8),
 (3,1,7,7,8),(3,2,8,7,7),(3,3,7,8,8),
 (4,1,6,7,9),(4,2,7,6,8),(4,3,6,7,8);
INSERT INTO sponsor (name) VALUES ('TechNova'),('CloudBase'),('DevForge');
INSERT INTO sponsorship VALUES
 (1,1,200000,'Gold'),(1,2,150000,'Silver'),(1,3,100000,'Bronze'),(2,1,80000,'Gold');

-- ========== VIEW ==========
CREATE VIEW leaderboard AS
SELECT p.project_id, p.title, t.team_name,
       ROUND(AVG(s.innovation + s.technical + s.impact), 2) AS avg_total,
       RANK() OVER (ORDER BY AVG(s.innovation + s.technical + s.impact) DESC) AS rnk
FROM project p
JOIN team t  ON t.team_id = p.team_id
JOIN score s ON s.project_id = p.project_id
GROUP BY p.project_id, p.title, t.team_name;

-- ========== TRIGGER: max 4 members per team ==========
DELIMITER //
CREATE TRIGGER trg_team_size BEFORE INSERT ON team_member
FOR EACH ROW
BEGIN
  IF (SELECT COUNT(*) FROM team_member WHERE team_id = NEW.team_id) >= 4 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Team cannot exceed 4 members';
  END IF;
END//
DELIMITER ;

-- ========== QUERIES ==========
-- Q1 Leaderboard (view)
SELECT * FROM leaderboard ORDER BY rnk;

-- Q2 Team sizes (JOIN + GROUP BY + HAVING)
SELECT t.team_name, COUNT(*) AS members
FROM team t JOIN team_member tm ON tm.team_id = t.team_id
GROUP BY t.team_id, t.team_name HAVING COUNT(*) >= 2;

-- Q3 Participants without a team (LEFT JOIN + IS NULL)
SELECT p.name FROM participant p
LEFT JOIN team_member tm ON tm.participant_id = p.participant_id
WHERE tm.team_id IS NULL;

-- Q4 Sponsorship total per hackathon
SELECT h.name, SUM(sp.amount) AS total_funding
FROM hackathon h JOIN sponsorship sp ON sp.hackathon_id = h.hackathon_id
GROUP BY h.hackathon_id, h.name;

-- Q5 College-wise participation
SELECT college, COUNT(*) AS participants FROM participant
GROUP BY college ORDER BY participants DESC;

-- Q6 Projects scoring above the overall average (subquery)
SELECT title, avg_total FROM leaderboard
WHERE avg_total > (SELECT AVG(avg_total) FROM leaderboard);

-- Q7 Judge strictness: average score given by each judge
SELECT j.name, ROUND(AVG(s.innovation + s.technical + s.impact), 2) AS avg_given
FROM judge j JOIN score s ON s.judge_id = j.judge_id
GROUP BY j.judge_id, j.name;
