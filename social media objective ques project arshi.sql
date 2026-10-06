use ig_clone;

-- 1. FOR CHECKING DUPLICATED AND NULLS

-- Check for duplicate usernames
SELECT username, COUNT(*) 
FROM users
GROUP BY username
HAVING COUNT(*) > 1;

-- Check for nulls
SELECT * 
FROM photos
WHERE image_url IS NULL OR user_id IS NULL;


-- 2.DISTRIBUTION OF USER ACTIVITY LEVEL

SELECT 
    u.id AS user_id,
    u.username,
    COUNT(DISTINCT p.id) AS total_photos,
    COUNT(DISTINCT l.photo_id) AS total_likes,
    COUNT(DISTINCT c.id) AS total_comments
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username;

-- 3. AVG NO.OG TAGS PER POST

SELECT 
    ROUND(AVG(tag_count),2) AS avg_tags_per_photo
FROM (
    SELECT p.id, COUNT(pt.tag_id) AS tag_count
    FROM photos p
    LEFT JOIN photo_tags pt ON p.id = pt.photo_id
    GROUP BY p.id
) sub;

-- 4.TOP USERS WITH HIGHEST ENGAGEMENT RATE

SELECT 
    p.user_id,
    u.username,
    (COUNT(DISTINCT l.user_id || l.photo_id) + COUNT(DISTINCT c.id)) / 
    NULLIF(COUNT(DISTINCT p.id), 0) AS engagement_rate
FROM photos p
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
JOIN users u ON p.user_id = u.id
GROUP BY p.user_id, u.username
ORDER BY engagement_rate DESC
LIMIT 10;

-- 5.total number of followers and followings


WITH followers_cte AS (
    SELECT 
        followee_id AS user_id,
        COUNT(follower_id) AS follower_count
    FROM follows
    GROUP BY followee_id
),
following_cte AS (
    SELECT 
        follower_id AS user_id,
        COUNT(followee_id) AS following_count
    FROM follows
    GROUP BY follower_id
)
SELECT 
    u.id AS user_id,
    u.username,
    COALESCE(f.follower_count, 0) AS total_followers,
    COALESCE(g.following_count, 0) AS total_following
FROM users u
LEFT JOIN followers_cte f ON u.id = f.user_id
LEFT JOIN following_cte g ON u.id = g.user_id
ORDER BY total_followers DESC;



-- 6. AVG ENGAGEMENT PER PHOTO

SELECT 
    u.username,
    ROUND((COUNT(DISTINCT l.user_id || l.photo_id) + COUNT(DISTINCT c.id)) / 
          NULLIF(COUNT(DISTINCT p.id),0), 2) AS avg_engagement
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY u.username;

-- 7. USERS WHO NEVER LIKES ANY POSTS

SELECT id AS user_id, username
FROM users
WHERE id NOT IN (SELECT DISTINCT user_id FROM likes);

-- 10 total number of likes, comments, and photo tags for each user

SELECT 
    u.id AS user_id,
    u.username,
    COUNT(DISTINCT l.user_id || l.photo_id) AS total_likes,
    COUNT(DISTINCT c.id) AS total_comments,
    COUNT(DISTINCT pt.tag_id) AS total_tags
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
LEFT JOIN photo_tags pt ON p.id = pt.photo_id
GROUP BY u.id, u.username;

-- 11.Rank users based on their total engagement (likes, comments, shares) over a month.

WITH user_likes AS (
    SELECT 
        p.user_id,
        COUNT(l.user_id) AS total_likes
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    GROUP BY p.user_id
),
user_comments AS (
    SELECT 
        p.user_id,
        COUNT(c.id) AS total_comments
    FROM photos p
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
),
engagement_cte AS (
    SELECT 
        u.id AS user_id,
        u.username,
        COALESCE(l.total_likes, 0) AS total_likes,
        COALESCE(c.total_comments, 0) AS total_comments,
        (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) AS engagement_score
    FROM users u
    LEFT JOIN user_likes l ON u.id = l.user_id
    LEFT JOIN user_comments c ON u.id = c.user_id
)
SELECT 
    user_id,
    username,
    total_likes,
    total_comments,
    engagement_score,
    RANK() OVER (ORDER BY engagement_score DESC) AS influencer_rank
FROM engagement_cte
ORDER BY influencer_rank;



-- 12.Hashtags with Highest Average Likes (CTE)

WITH HashtagLikes AS (
    SELECT 
        t.tag_name,
        AVG(like_count) AS avg_likes
    FROM (
        SELECT pt.tag_id, COUNT(l.user_id) AS like_count
        FROM photo_tags pt
        JOIN likes l ON pt.photo_id = l.photo_id
        GROUP BY pt.tag_id, pt.photo_id
    ) sub
    JOIN tags t ON sub.tag_id = t.id
    GROUP BY t.tag_name
)
SELECT * 
FROM HashtagLikes
ORDER BY avg_likes DESC
LIMIT 10;




-- 13.users who have started following someone after being followed by that person

SELECT 
    f1.follower_id AS user_a,
    f1.followee_id AS user_b
FROM follows f1
JOIN follows f2
  ON f1.follower_id = f2.followee_id
 AND f1.followee_id = f2.follower_id;







