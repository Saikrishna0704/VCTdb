-- viweing pacific
select * from pacific

-- viweing emea
select * from emea

-- viweing maps
select * from maps

-- viweing Agents
select * from "Agents"

-- adding region column
ALTER TABLE pacific
ADD COLUMN region VARCHAR(255) DEFAULT 'pacific';

UPDATE emea
SET region = 'emea';

-- merging pacific and emea to kickoff
CREATE TABLE kickoff AS
SELECT * FROM emea
UNION
SELECT * FROM pacific

-- viewing kickoff
select * from kickoff

-- creating teams table
CREATE TABLE teams (
    team_id SERIAL PRIMARY KEY,
    team_name VARCHAR(255) NOT NULL,
    players TEXT,
	region TEXT
);

-- Rectified issue
UPDATE kickoff
SET "teamName" = 'T1'
WHERE "teamName" LIKE 'T1%';

-- inserting data into teams table
INSERT INTO teams (team_name, players, region)
SELECT "teamName", STRING_AGG( DISTINCT "gameName", ', ') AS player_names, region
FROM kickoff
GROUP BY "teamName", "region";

-- Viewing teams table
select * from teams

-- creating tournament table
CREATE TABLE tournament (
    tournament_id SERIAL PRIMARY KEY,
    tournament_name VARCHAR(255) NOT NULL,
    eventDate DATE NOT NULL,
    country VARCHAR(255),
	teams VARCHAR(255),
	region VARCHAR(255)
);

-- inserting data into tournament table
INSERT INTO tournament (tournament_name, eventDate, country, teams, region)
VALUES 
    ('VCT_emea_kickoff', '2024-01-15', 'Germany', (select STRING_AGG(DISTINCT "team_name", ', ') from teams where region='emea' group by region), 'emea')
, 
    ('VCT_pacific_kickoff', '2024-02-17', 'South Korea',  (select STRING_AGG(DISTINCT "team_name", ', ') from teams where region='pacific' group by region), 'pacific');

-- viewing tournament table
select * from tournament

-- creating matches table
CREATE TABLE matches (
    match_id TEXT PRIMARY KEY,
    teams TEXT NOT NULL,
    tournament_name VARCHAR(255) NOT NULL,
    winning_team_name VARCHAR(255),
    losing_team_name VARCHAR(255),
    map_played TEXT
);

-- inserting into matches table
INSERT INTO matches (match_id, teams, tournament_name, winning_team_name, losing_team_name, map_played)
SELECT 
    "matchId",
    STRING_AGG(DISTINCT "teamName", ', ') AS teams,
    "tournamentName",
    (SELECT "teamName" FROM kickoff WHERE "won"=true AND "matchId" = k."matchId" AND "tournamentName" = k."tournamentName" LIMIT 1) AS winning_team,
    (SELECT "teamName" FROM kickoff WHERE "won"=false AND "matchId" = k."matchId" AND "tournamentName" = k."tournamentName" LIMIT 1) AS losing_team,
    STRING_AGG(DISTINCT "map", ', ') AS maps_played
FROM kickoff k
GROUP BY "matchId", "tournamentName";

-- viewing matches table
select * from matches

-- creating players table
CREATE TABLE players (
    player_name VARCHAR(255) PRIMARY KEY,
    team_name VARCHAR(255),
	region VARCHAR(255)
);


select * from teams

-- Normalization
CREATE TABLE players (
    player_name VARCHAR(255) PRIMARY KEY,
    team_name VARCHAR(255)
);

-- inserting into players table
INSERT INTO players ( player_name, team_name)
SELECT trim(unnest(string_to_array(players, ','))) AS player_name, team_name FROM teams;

-- viewing players table
select * from players

-- deleting the non atomic column (players)
ALTER TABLE teams
DROP COLUMN players;

-- deleting the region column
ALTER TABLE teams
DROP COLUMN region;

-- viewing teams table
select * from teams

-- 
select * from tournament

-- Normalizing matches table
ALTER TABLE matches
DROP COLUMN teams;

-- Normalizing tournament table
CREATE TABLE tournamentteams (
    team_id SERIAL PRIMARY KEY,
    tourn_id INT,
    team_name VARCHAR(100),
    FOREIGN KEY (tourn_id) REFERENCES tournament(tournament_id)
);

INSERT INTO tournamentteams(tourn_id, team_name)
SELECT tournament_id, unnest(string_to_array(teams, ', ')) AS team_name
FROM tournament;

ALTER TABLE tournament DROP COLUMN teams;


----1. Query to find the matches won by each team in descending order.
SELECT winning_team_name AS TeamName, COUNT(*) as matches_won FROM matches 
GROUP BY winning_team_name ORDER BY matches_won DESC

----2. Query to find the most played maps
SELECT map_played ,COUNT(*) as maps_frequency FROM matches 
GROUP BY map_played ORDER BY maps_frequency DESC

----3. Query to find the strong maps of each team
SELECT winning_team_name AS TeamName, map_played, COUNT(*) as win_frequency FROM matches
GROUP BY map_played, winning_team_name ORDER BY win_frequency DESC

----4. Query to find strong map of each player
SELECT players.player_name, map_played, COUNT(*) as win_frequency FROM matches
INNER JOIN players ON players.team_name = matches.winning_team_name
GROUP BY map_played, players.player_name ORDER BY win_frequency DESC

----5. Query to find the teams from a specific region 
SELECT team_name, region from tournamentteams
INNER JOIN tournament ON
tournamentteams.tourn_id = tournament.tournament_id AND region = 'emea'

----6. Query to find the count of teams from each region
SELECT count(*) AS teams_count, region FROM (SELECT team_name, region from tournamentteams
INNER JOIN tournament ON
tournamentteams.tourn_id = tournament.tournament_id) AS temp
GROUP BY region ORDER BY teams_count

----7. Query to find the players played in a specific tournament
SELECT player_name, tournament_name FROM players 
INNER JOIN matches ON players.team_name = matches.winning_team_name
WHERE tournament_name = 'VCT_pacific_kickoff'


----8. Query to find the worst performing map for a specific player.
SELECT player_name, COUNT(map_played) AS loss_frequency, map_played FROM players
INNER JOIN matches ON
players.team_name = matches.losing_team_name
WHERE player_name = 'GE Lightningfa'
GROUP BY player_name, map_played

