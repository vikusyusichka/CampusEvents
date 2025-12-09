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
    password_hash VARCHAR(255) NOT NULL,
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
    description VARCHAR(1024),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    location VARCHAR(256) NOT NULL,
    capacity INT,
    visibility event_visibility NOT NULL DEFAULT 'public',
    status event_status NOT NULL DEFAULT 'draft',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_event_creator
        FOREIGN KEY (creator_id)
        REFERENCES "User"(id)
        ON DELETE CASCADE,
    CONSTRAINT chk_event_time
        CHECK (end_time > start_time),
    CONSTRAINT chk_event_capacity
        CHECK (capacity IS NULL OR capacity > 0)
);

CREATE TABLE "Follow" (
    id SERIAL PRIMARY KEY,
    follower_id INT NOT NULL,
    followed_id INT NOT NULL,
    status follow_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_follow_follower
        FOREIGN KEY (follower_id)
        REFERENCES "User"(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_follow_followed
        FOREIGN KEY (followed_id)
        REFERENCES "User"(id)
        ON DELETE CASCADE,
    CONSTRAINT uq_follow_pair
        UNIQUE (follower_id, followed_id),
    CONSTRAINT chk_follow_not_self
        CHECK (follower_id <> followed_id)
);

CREATE TABLE "EventCategory" (
    id SERIAL PRIMARY KEY,
    event_id INT NOT NULL,
    category_id INT NOT NULL,
    CONSTRAINT fk_eventcategory_event
        FOREIGN KEY (event_id)
        REFERENCES "Event"(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_eventcategory_category
        FOREIGN KEY (category_id)
        REFERENCES "Category"(id)
        ON DELETE CASCADE,
    CONSTRAINT uq_eventcategory_pair
        UNIQUE (event_id, category_id)
);

CREATE TABLE "EventParticipant" (
    id SERIAL PRIMARY KEY,
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    status participant_status NOT NULL DEFAULT 'interested',
    joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_participant_event
        FOREIGN KEY (event_id)
        REFERENCES "Event"(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_participant_user
        FOREIGN KEY (user_id)
        REFERENCES "User"(id)
        ON DELETE CASCADE,
    CONSTRAINT uq_participant_pair
        UNIQUE (event_id, user_id)
);

CREATE TABLE "Comment" (
    id SERIAL PRIMARY KEY,
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    text VARCHAR(512) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_comment_event
        FOREIGN KEY (event_id)
        REFERENCES "Event"(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_comment_user
        FOREIGN KEY (user_id)
        REFERENCES "User"(id)
        ON DELETE CASCADE
);

CREATE TABLE "EventMention" (
    id SERIAL PRIMARY KEY,
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    CONSTRAINT fk_eventmention_event
        FOREIGN KEY (event_id)
        REFERENCES "Event"(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_eventmention_user
        FOREIGN KEY (user_id)
        REFERENCES "User"(id)
        ON DELETE CASCADE,
    CONSTRAINT uq_eventmention_pair
        UNIQUE (event_id, user_id)
);

CREATE TABLE "CommentMention" (
    id SERIAL PRIMARY KEY,
    comment_id INT NOT NULL,
    user_id INT NOT NULL,
    CONSTRAINT fk_commentmention_comment
        FOREIGN KEY (comment_id)
        REFERENCES "Comment"(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_commentmention_user
        FOREIGN KEY (user_id)
        REFERENCES "User"(id)
        ON DELETE CASCADE,
    CONSTRAINT uq_commentmention_pair
        UNIQUE (comment_id, user_id)
);

INSERT INTO "User" (email, password_hash, name, avatar_url, bio, role)
VALUES
    ('alice@example.com', 'hash_alice123', 'Alice Smith', 'https://example.com/alice.jpg', 'Студентка, люблю тех-конференції', 'student'),
    ('bob@example.com', 'hash_bob456', 'Bob Johnson', 'https://example.com/bob.jpg', 'Організатор подій в кампусі', 'organizer'),
    ('carol@example.com', 'hash_carol789', 'Carol Davis', NULL, 'Музичний ентузіаст', 'student'),
    ('dave@example.com', 'hash_dave101', 'Dave Wilson', NULL, 'Спортивний фанат', 'student'),
    ('admin@example.com', 'hash_admin112', 'Admin User', NULL, 'Адміністратор системи', 'admin');

INSERT INTO "Category" (name, description)
VALUES
    ('IT & Programming', 'Технічні зустрічі, кодінг, хакатони'),
    ('Music & Arts', 'Концерти, джем-сесії, мистецтво'),
    ('Sports & Fitness', 'Спортивні події, турніри'),
    ('Social & Networking', 'Неформальні зустрічі, нетворкінг'),
    ('Workshops & Learning', 'Майстер-класи, навчання');

INSERT INTO "Event" (creator_id, title, description, start_time, end_time, location, capacity, visibility, status)
VALUES
    (2, 'Tech Conference 2025', 'Щорічна конференція з ІТ', NOW() + INTERVAL '3 days', NOW() + INTERVAL '3 days 8 hours', 'Київ, МВЦ', 200, 'public', 'published'),
    (2, 'Coding Workshop', 'Практикум з Python', NOW() + INTERVAL '5 days', NOW() + INTERVAL '5 days 3 hours', 'Online (Zoom)', 50, 'private', 'published'),
    (3, 'Music Festival', 'Жива музика в парку', NOW() + INTERVAL '10 days', NOW() + INTERVAL '10 days 5 hours', 'Парк Шевченка', NULL, 'public', 'draft'),
    (4, 'Sports Tournament', 'Студентський турнір з футболу', NOW() + INTERVAL '15 days', NOW() + INTERVAL '15 days 4 hours', 'Стадіон КПІ', 100, 'public', 'published'),
    (1, 'Networking Mixer', 'Неформальна зустріч', NOW() + INTERVAL '20 days', NOW() + INTERVAL '20 days 2 hours', 'Клуб Downtown', 80, 'private', 'cancelled');

INSERT INTO "EventCategory" (event_id, category_id)
VALUES
    (1, 1),
    (2, 5),
    (3, 2),
    (4, 3),
    (5, 4);

INSERT INTO "Follow" (follower_id, followed_id, status, created_at)
VALUES
    (1, 2, 'active', NOW() - INTERVAL '10 days'),
    (1, 3, 'active', NOW() - INTERVAL '8 days'),
    (2, 1, 'active', NOW() - INTERVAL '7 days'),
    (3, 4, 'blocked', NOW() - INTERVAL '5 days'),
    (4, 5, 'active', NOW() - INTERVAL '3 days');

INSERT INTO "EventParticipant" (event_id, user_id, status, joined_at)
VALUES
    (1, 1, 'going', NOW() - INTERVAL '2 days'),
    (1, 2, 'interested', NOW() - INTERVAL '1 day'),
    (2, 3, 'going', NOW() - INTERVAL '12 hours'),
    (3, 4, 'declined', NOW() - INTERVAL '6 hours'),
    (4, 5, 'going', NOW() - INTERVAL '3 hours');

INSERT INTO "Comment" (event_id, user_id, text, created_at)
VALUES
    (1, 1, 'Чекаю на доповіді про AI!', NOW() - INTERVAL '4 hours'),
    (1, 2, 'Слайди будуть доступні після події.', NOW() - INTERVAL '3 hours'),
    (2, 3, 'Хто приєднається до проекту?', NOW() - INTERVAL '2 hours'),
    (3, 4, 'Які артисти виступатимуть?', NOW() - INTERVAL '1 hour'),
    (4, 5, 'Команда готова до турніру!', NOW() - INTERVAL '30 minutes');

INSERT INTO "EventMention" (event_id, user_id)
VALUES
    (1, 3),
    (2, 1),
    (3, 5),
    (4, 2);

INSERT INTO "CommentMention" (comment_id, user_id)
VALUES
    (1, 2),
    (2, 3),
    (3, 4),
    (4, 5);

SELECT * FROM "User";
SELECT name, email FROM "User" WHERE role = 'student';

SELECT * FROM "Event";
SELECT title, location FROM "Event" WHERE status = 'published';

INSERT INTO "User" (email, password_hash, name, role)
VALUES ('newuser@example.com', 'hash_new123', 'New User', 'student');

UPDATE "User"
SET bio = 'Новий біо для Alice'
WHERE email = 'alice@example.com';

DELETE FROM "Follow"
WHERE follower_id = 3 AND followed_id = 4;

INSERT INTO "Event" (creator_id, title, description, start_time, end_time, location, visibility)
VALUES (1, 'New Event', 'Нова подія', NOW() + INTERVAL '30 days', NOW() + INTERVAL '30 days 4 hours', 'Київ', 'public');

UPDATE "Event"
SET status = 'published'
WHERE id = 3;

DELETE FROM "Comment"
WHERE id = 4;

SELECT * FROM "User" WHERE email = 'newuser@example.com';
SELECT * FROM "Event" WHERE title = 'New Event';
SELECT * FROM "Event" WHERE status = 'published';
