-- Drop existing tables

DROP TABLE IF EXISTS "users" CASCADE;

DROP TABLE IF EXISTS "topics" CASCADE;

DROP TABLE IF EXISTS "posts" CASCADE;

DROP TABLE IF EXISTS "comments" CASCADE;

DROP TABLE IF EXISTS "votes" CASCADE;

-- DDL COMMANDS

-- Users Table
CREATE TABLE IF NOT EXISTS "users"  (
    "id" SERIAL PRIMARY KEY,
    "username" VARCHAR(25) NOT NULL,
    "last_login" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "unique_username" UNIQUE ("username"),
    CONSTRAINT "non_empty_username" CHECK (TRIM("username") != '')
); 




--Topics Table
CREATE TABLE IF NOT EXISTS "topics" (
    "id" SERIAL PRIMARY KEY,
    "topic" VARCHAR(30) NOT NULL,
    "description" VARCHAR(500) DEFAULT NULL,
    CONSTRAINT "unique_topic" UNIQUE ("topic"),
    CONSTRAINT "non_empty_topic" CHECK (TRIM("topic") <> '')

);

-- Posts Table
CREATE TABLE IF NOT EXISTS "posts" (
    "id" SERIAL PRIMARY KEY,
    "user_id" INTEGER REFERENCES "users" ("id") ON DELETE SET NULL,
    "topic_id" INTEGER NOT NULL REFERENCES "topics" ("id") ON DELETE CASCADE,
    "title" VARCHAR(100) NOT NULL,
    "url" VARCHAR,
    "text_content" TEXT,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "non_empty_post" CHECK (TRIM("title") <> '')
    CONSTRAINT "url_or_text_content" CHECK (
        "url" IS NOT NULL OR "text_content" IS NOT NULL)
); 


-- Comments Table
CREATE TABLE IF NOT EXISTS "comments" (
    "id" SERIAL PRIMARY KEY,
    "text_content" TEXT NOT NULL,
    "user_id" INTEGER REFERENCES "users" ("id") ON DELETE SET NULL,
    "post_id" INTEGER NOT NULL REFERENCES "posts" ("id") ON DELETE CASCADE,
    "parent_comment_id" INTEGER REFERENCES "comments" ("id") ON DELETE CASCADE,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "non_empty_comment" CHECK (TRIM("text_content") != '')
);



-- Votes Table

CREATE TABLE IF NOT EXISTS "votes" (
    "id" SERIAL PRIMARY KEY,
    "user_id" INTEGER REFERENCES "users" ("id") ON DELETE SET NULL,
    "post_id" INTEGER NOT NULL REFERENCES "posts" ("id") ON DELETE CASCADE
    "vote" INTEGER NOT NULL,
    CONSTRAINT "user_vote" CHECK ("vote" IN (1, -1)),
    CONSTRAINT "unique_user_post" UNIQUE ("user_id", "post_id")
);



-- INDEXES TO SPEED UP QUERIES

-- a.	List all users who haven’t logged in in the last year. 
CREATE INDEX "users_last_login" ON "users" ("last_login");

-- b.	List all users who haven’t created any posts. 

-- Already achieved

-- c.	Find a user by their username. 
-- We don't need to create an here index because username is already unique

-- d.	List all topics that don’t have any posts. 
-- Already achieved below

-- e.	Find a topic by its name. 
-- We don't need to create an here index because name is already unique

-- f.	List the latest 20 posts for a given topic. 

CREATE INDEX "posts_topic_created_at" 
ON "posts" ("topic_id", "created_at" DESC);

-- g.	List the latest 20 posts made by a given user.

CREATE INDEX "posts_topic_created_at_idx" 
ON "posts" ("user_id", "created_at" DESC);

-- h.	Find all posts that link to a specific URL, for moderation purposes. 

CREATE INDEX "specific_url" ON "posts" ("url" VARCHAR_PATTERN_OPS);

/* i.List all the top-level comments (those that don’t have a parent comment)
for a given post. */ 

CREATE INDEX "top_level_comments" 
ON "comments" ("parent_comment_id", "post_id");

-- j.	List all the direct children of a parent comment.  
-- Can be achived using the index created in question (i) above

-- k.	List the latest 20 comments made by a given user.
-- Create indexes for the comments 
CREATE INDEX "users_latest_comments" 
ON "comments" ("user_id", "created_at" DESC);

/*  l.	Compute the score of a post, defined as the difference between
the number of upvotes and the number of downvotes */

CREATE INDEX "post_votes" ON "votes" ("post_id");





--DML COMMANDS


-- INSERT INTO USERS TABLE
INSERT INTO "users" ("username")
SELECT DISTINCT "username"
FROM (
    -- Usernames from posts
    SELECT "username" FROM "bad_posts"
    UNION
    -- Usernames from comments
    SELECT "username" FROM "bad_comments"
    UNION
    -- Usernames from upvotes (split comma-separated list)
    SELECT regexp_split_to_table("upvotes", ',') 
    FROM "bad_posts"
    UNION 
    -- Usernames from downvotes (split comma-separated list)
    SELECT regexp_split_to_table("downvotes", ',') 
    FROM "bad_posts"
) AS combined_usernames;



-- INSERT INTO TOPICS TABLE
INSERT INTO "topics" ("topic")
SELECT DISTINCT "topic"
FROM "bad_posts";


-- INSERT INTO POSTS TABLE
INSERT INTO "posts" (
    "user_id",
    "topic_id",
    "title",
    "url",
    "text_content"
)
SELECT
    u.id,
    t.id,
    b.title,
    b.url,
    b.text_content
FROM
    "users" u
JOIN
    "bad_posts" b
    ON u.username = b.username
JOIN
    "topics" t
    ON t.topic = b.topic;


-- INSERT INTO COMMENTS TABLE

INSERT INTO "comments" ("user_id", "post_id", "text_content")
SELECT
    u.id,
    bc.post_id,
    bc.text_content
FROM
    "bad_comments" bc
JOIN
    "posts" p ON (p.id = bc.post_id)
JOIN
    "users" u ON (u.username = bc.username);




-- INSERT INTO VOTES TABLE

WITH sub1 AS (
    SELECT 
        bad_posts.id AS "post_id",
        regexp_split_to_table(bad_posts.downvotes, ',') AS downvotes
    FROM "bad_posts"
),

sub2 AS (
    SELECT 
        bad_posts.id AS post_id,
        regexp_split_to_table(bad_posts.upvotes, ',') AS upvotes
    FROM bad_posts
),

sub3 AS (
    SELECT 
        u.id AS user_id,
        sub1.post_id AS post_id,
        -1 AS vote
    FROM sub1
    JOIN users u ON u.username = sub1.downvotes
    GROUP BY 1, 2
    
    UNION
    
    SELECT 
        u.id AS user_id,
        sub2.post_id AS post_id,
        1 AS vote
    FROM sub2
    JOIN users u ON u.username = sub2.upvotes
    GROUP BY 1, 2
)

INSERT INTO "votes" ("user_id", "post_id", "vote")
SELECT "user_id", "post_id", "vote"
FROM sub3;