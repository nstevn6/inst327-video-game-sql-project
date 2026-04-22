USE reviewed_games_backlogged;
-- View 1
DROP VIEW IF EXISTS view_game_review_summary;
CREATE VIEW view_game_review_summary AS
SELECT g.game_id, g.title, 
 	rm.num_reviews,
 	rm.plays,
 	rm.wishlist,
 	rm.rating,
   (rm.plays / NULLIF(rm.num_reviews, 0)) AS plays_per_review
FROM Games g
JOIN Review_Metrics rm ON g.game_id = rm.game_id
WHERE rm.rating >= 3
ORDER BY rating DESC;
-- Shows summary review metrics for games with a rating of at least 3.
-- Rating value is arbitrary, could be used for sampling purposes.

-- View 2
DROP VIEW IF EXISTS view_developer_game_counts;
CREATE VIEW view_developer_game_counts AS
SELECT 
	d.developer_id,
	d.developer_name, 
	(SELECT COUNT(*) 
	FROM Game_Developers gd 
	WHERE gd.developer_id = d.developer_id) AS total_games
FROM Developers d
HAVING total_games > 0
ORDER BY total_games DESC;
-- Lists developers and the total number of games they have worked on.

-- View 3
DROP VIEW IF EXISTS view_games_by_genre;
CREATE VIEW view_games_by_genre AS
SELECT 
	g.game_id, 
	g.title, 
	ge.genre_name
FROM Games g
JOIN Game_Genres AS gg ON g.game_id = gg.game_id
JOIN Genres AS ge ON gg.genre_id = ge.genre_id
WHERE ge.genre_name LIKE '%Adventure%';
-- Lists all Adventure-related games tagged games.
-- Genre of game is arbitrary, could be used for any of the genres in the db.

-- View 4:
DROP VIEW IF EXISTS view_genre_popularity_stats;
CREATE VIEW view_genre_popularity_stats AS
SELECT 
	gen.genre_name, 
	COUNT(DISTINCT g.game_id) AS total_games, 
	AVG(rm.rating) AS avg_rating, 
	SUM(rm.plays) AS total_plays
FROM Genres AS gen
JOIN Game_Genres AS gg ON gen.genre_id = gg.genre_id
JOIN Games AS g ON gg.game_id = g.game_id
JOIN Review_Metrics AS rm ON g.game_id = rm.game_id
GROUP BY gen.genre_name
HAVING AVG(rm.rating) >
    (
        SELECT AVG(rating)
    	FROM Review_Metrics
    );
-- Show average rating and total plays per chosen genre.

-- Procedure 1: 
DROP PROCEDURE IF EXISTS get_games_by_developer;
DELIMITER $$
CREATE PROCEDURE get_games_by_developer(IN dev_id INT)
BEGIN
    SELECT
    	d.developer_name,
        g.game_id,
        g.title
    FROM Games AS g
    JOIN Game_Developers AS gd ON g.game_id = gd.game_id
    JOIN Developers AS d ON gd.developer_id = d.developer_id
    WHERE gd.developer_id = dev_id;
END $$
DELIMITER ;
-- Returns all games developed by a specfied developer id.
-- Example:
-- CALL get_games_by_developer(5);

-- Procedure 2:
DROP PROCEDURE IF EXISTS get_game_review_summary;
DELIMITER $$
CREATE PROCEDURE get_game_review_summary (
    IN min_rating DECIMAL(3,1)
)
BEGIN
    SELECT
        g.game_id,
        g.title,
        rm.rating,
        rm.num_reviews,
        rm.plays,
        rm.wishlist
    FROM Games AS g
    JOIN Review_Metrics AS rm
        ON g.game_id = rm.game_id
    WHERE rm.rating >= min_rating
    ORDER BY rm.rating DESC, rm.num_reviews DESC;
END$$
DELIMITER ;
-- Lists games that meet or exceed a specified rating. Lists review metrics attached to the games.
-- Example:
-- CALL get_game_review_summary(4.0);

-- Function 1:
DROP FUNCTION IF EXISTS get_average_rating;
DELIMITER $$
CREATE FUNCTION get_average_rating()
RETURNS DECIMAL(4,2)
DETERMINISTIC
BEGIN
    DECLARE avg_rating DECIMAL(4,2);
    SELECT AVG(rating) INTO avg_rating FROM Review_Metrics;
    RETURN avg_rating;
END $$
DELIMITER ;
-- Returns the average rating of all games.
-- Example:
-- SELECT get_average_rating();

-- Function 2: Count genres for a given game
DROP FUNCTION IF EXISTS count_game_genres;
DROP FUNCTION IF EXISTS count_game_genres;
DELIMITER $$
CREATE FUNCTION count_game_genres(p_game_id INT)
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE genre_count INT;
    DECLARE game_title VARCHAR(150);
    SELECT g.title
    INTO game_title
    FROM Games AS g
    WHERE g.game_id = p_game_id;
    SELECT COUNT(*)
    INTO genre_count
    FROM Game_Genres AS gg
    WHERE gg.game_id = p_game_id;
    RETURN CONCAT(game_title, ' has ', genre_count, ' genre(s)');
END $$
DELIMITER ;

-- Purpose: Returns the number of genres assigned to a specific game.
-- Example:
-- SELECT count_game_genres(5);

