-- Query 1
SELECT 'User' AS table_name, COUNT(*) AS row_count FROM "User"
UNION ALL
SELECT 'Event', COUNT(*) FROM "Event"
UNION ALL
SELECT 'Category', COUNT(*) FROM "Category"
UNION ALL
SELECT 'EventParticipant', COUNT(*) FROM "EventParticipant"
UNION ALL
SELECT 'Comment', COUNT(*) FROM "Comment";

-- Query 2
SELECT
    status,
    COUNT(*) AS events_count
FROM "Event"
GROUP BY status
ORDER BY status;

-- Query 3
SELECT
    visibility,
    COUNT(*) AS events_count,
    AVG(capacity) AS avg_capacity,
    MIN(capacity) AS min_capacity,
    MAX(capacity) AS max_capacity
FROM "Event"
GROUP BY visibility
ORDER BY visibility;

-- Query 4
SELECT
    e.id,
    e.title,
    COUNT(ep.id) AS participants_count
FROM "Event" AS e
INNER JOIN "EventParticipant" AS ep
    ON ep.event_id = e.id
GROUP BY e.id, e.title
HAVING COUNT(ep.id) > 1
ORDER BY participants_count DESC, e.id;

-- Query 5
SELECT
    u.id,
    u.name,
    COUNT(ep.id) AS total_going_participants
FROM "User" AS u
JOIN "Event" AS e
    ON e.creator_id = u.id
LEFT JOIN "EventParticipant" AS ep
    ON ep.event_id = e.id
   AND ep.status = 'going'
GROUP BY u.id, u.name
ORDER BY total_going_participants DESC, u.name;

-- Query 6
SELECT
    c.id AS comment_id,
    e.title AS event_title,
    u.name AS author_name,
    c.text,
    c.created_at
FROM "Comment" AS c
JOIN "Event" AS e
    ON e.id = c.event_id
JOIN "User" AS u
    ON u.id = c.user_id
ORDER BY c.created_at DESC;

-- Query 7
SELECT
    e.id,
    e.title,
    COUNT(c.id) AS comments_count
FROM "Event" AS e
LEFT JOIN "Comment" AS c
    ON c.event_id = e.id
GROUP BY e.id, e.title
ORDER BY comments_count DESC, e.id;

-- Query 8
SELECT
    id,
    title,
    capacity
FROM "Event"
WHERE
    capacity IS NOT NULL
    AND capacity > (
        SELECT AVG(capacity)
        FROM "Event"
        WHERE capacity IS NOT NULL
    )
ORDER BY capacity DESC, id;

-- Query 9
SELECT
    e.id,
    e.title,
    (
        SELECT COUNT(*)
        FROM "EventParticipant" AS ep
        WHERE ep.event_id = e.id
    ) AS participants_count
FROM "Event" AS e
ORDER BY participants_count DESC, e.id;

-- Query 10
SELECT
    u.id,
    u.name,
    COALESCE(em.event_mentions_count, 0) AS event_mentions_count,
    COALESCE(cm.comment_mentions_count, 0) AS comment_mentions_count
FROM (
    SELECT
        COALESCE(em.user_id, cm.user_id) AS user_id,
        em.event_mentions_count,
        cm.comment_mentions_count
    FROM (
        SELECT
            user_id,
            COUNT(*) AS event_mentions_count
        FROM "EventMention"
        GROUP BY user_id
    ) AS em
    FULL JOIN (
        SELECT
            user_id,
            COUNT(*) AS comment_mentions_count
        FROM "CommentMention"
        GROUP BY user_id
    ) AS cm
        ON cm.user_id = em.user_id
) AS x
JOIN "User" AS u
    ON u.id = x.user_id
ORDER BY u.name;

-- Query 11
SELECT
    c.id,
    c.name,
    COUNT(ec.event_id) AS events_count
FROM "Category" AS c
LEFT JOIN "EventCategory" AS ec
    ON ec.category_id = c.id
GROUP BY c.id, c.name
HAVING COUNT(ec.event_id) > (
    SELECT AVG(events_per_category)
    FROM (
        SELECT
            COUNT(*) AS events_per_category
        FROM "Category" AS c2
        LEFT JOIN "EventCategory" AS ec2
            ON ec2.category_id = c2.id
        GROUP BY c2.id
    ) AS sub
)
ORDER BY events_count DESC, c.name;
