DROP TABLE IF EXISTS posts;
CREATE TABLE posts (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    title TEXT NOT NULL,
    subtitle TEXT NOT NULL,
    content TEXT NOT NULL,
    show INTEGER DEFAULT 1,
    slug TEXT NOT NULL UNIQUE
);

DROP TABLE IF EXISTS tags;
CREATE TABLE tags (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    tag_name TEXT NOT NULL,
    UNIQUE(tag_name)
);

DROP TABLE IF EXISTS post_tags;
CREATE TABLE post_tags (
    post_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    FOREIGN KEY(post_id) REFERENCES posts(id),
    FOREIGN KEY(tag_id) REFERENCES tags(id),
    UNIQUE(post_id, tag_id)
);