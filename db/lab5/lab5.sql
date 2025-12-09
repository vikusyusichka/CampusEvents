DROP TABLE IF EXISTS "CommentMention" CASCADE;
DROP TABLE IF EXISTS "EventMention" CASCADE;
DROP TABLE IF EXISTS "Comment" CASCADE;
DROP TABLE IF EXISTS "EventParticipant" CASCADE;
DROP TABLE IF EXISTS "Follow" CASCADE;
DROP TABLE IF EXISTS "EventCategory" CASCADE;
DROP TABLE IF EXISTS "Event" CASCADE;
DROP TABLE IF EXISTS "Category" CASCADE;
DROP TABLE IF EXISTS "User" CASCADE;

DROP TYPE IF EXISTS participant_status CASCADE;
DROP TYPE IF EXISTS event_status CASCADE;
DROP TYPE IF EXISTS event_visibility CASCADE;
DROP TYPE IF EXISTS follow_status CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;

CREATE TYPE user_role AS ENUM ('student', 'organizer', 'admin');
CREATE TYPE follow_status AS ENUM ('active', 'blocked');
CREATE TYPE event_visibility AS ENUM ('public', 'private');
CREATE TYPE event_status AS ENUM ('draft', 'published', 'cancelled');
CREATE TYPE participant_status AS ENUM ('going', 'interested', 'declined');

CREATE TABLE "User" (
    id SERIAL PRIMARY KEY,
    email VARCHAR(128) NOT NULL UNIQUE,
    password_hash VARCHAR(128) NOT NULL,
    name VARCHAR(64) NOT NULL,
    avatar_url VARCHAR(256),
    bio VARCHAR(256),
    role user_role NOT NULL DEFAULT 'student',
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE "Category" (
    id SERIAL PRIMARY KEY,
    name VARCHAR(64) NOT NULL UNIQUE,
    description VARCHAR(256)
);

CREATE TABLE "Event" (
    id SERIAL PRIMARY KEY,
    creator_id INT NOT NULL,
    title VARCHAR(128) NOT NULL,
    description TEXT,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    location VARCHAR(128) NOT NULL,
    visibility event_visibility NOT NULL DEFAULT 'public',
    status event_status NOT NULL DEFAULT 'draft',
    capacity INT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_event_creator
        FOREIGN KEY (creator_id) REFERENCES "User"(id) ON DELETE CASCADE
);

CREATE TABLE "EventCategory" (
    event_id INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (event_id, category_id),
    CONSTRAINT fk_eventcategory_event
        FOREIGN KEY (event_id) REFERENCES "Event"(id) ON DELETE CASCADE,
    CONSTRAINT fk_eventcategory_category
        FOREIGN KEY (category_id) REFERENCES "Category"(id) ON DELETE CASCADE
);

CREATE TABLE "Follow" (
    follower_id INT NOT NULL,
    followee_id INT NOT NULL,
    status follow_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_id, followee_id),
    CONSTRAINT fk_follow_follower
        FOREIGN KEY (follower_id) REFERENCES "User"(id) ON DELETE CASCADE,
    CONSTRAINT fk_follow_followee
        FOREIGN KEY (followee_id) REFERENCES "User"(id) ON DELETE CASCADE,
    CONSTRAINT chk_follow_not_self
        CHECK (follower_id <> followee_id)
);

CREATE TABLE "EventParticipant" (
    id SERIAL PRIMARY KEY,
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    status participant_status NOT NULL DEFAULT 'going',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_eventparticipant_event
        FOREIGN KEY (event_id) REFERENCES "Event"(id) ON DELETE CASCADE,
    CONSTRAINT fk_eventparticipant_user
        FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE,
    CONSTRAINT uq_eventparticipant_event_user
        UNIQUE (event_id, user_id)
);

CREATE TABLE "Comment" (
    id SERIAL PRIMARY KEY,
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    text VARCHAR(512) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_comment_event
        FOREIGN KEY (event_id) REFERENCES "Event"(id) ON DELETE CASCADE,
    CONSTRAINT fk_comment_user
        FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE
);

CREATE TABLE "EventMention" (
    id SERIAL PRIMARY KEY,
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_eventmention_event
        FOREIGN KEY (event_id) REFERENCES "Event"(id) ON DELETE CASCADE,
    CONSTRAINT fk_eventmention_user
        FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE
);

CREATE TABLE "CommentMention" (
    id SERIAL PRIMARY KEY,
    comment_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_commentmention_comment
        FOREIGN KEY (comment_id) REFERENCES "Comment"(id) ON DELETE CASCADE,
    CONSTRAINT fk_commentmention_user
        FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE
);
