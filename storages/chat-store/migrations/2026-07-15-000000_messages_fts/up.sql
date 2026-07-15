-- Full-text fuzzy search over message text.
-- trigram tokenizer: substring matching for all scripts (incl. CJK) and
-- accelerates LIKE '%needle%' queries for patterns of 3+ characters.
CREATE VIRTUAL TABLE messages_fts USING fts5(
    text_content,
    content='messages',
    content_rowid='rowid',
    tokenize='trigram'
);

-- Backfill from existing rows.
INSERT INTO messages_fts(rowid, text_content)
SELECT rowid, text_content FROM messages WHERE text_content IS NOT NULL;

CREATE TRIGGER messages_fts_ai AFTER INSERT ON messages
WHEN new.text_content IS NOT NULL
BEGIN
    INSERT INTO messages_fts(rowid, text_content)
    VALUES (new.rowid, new.text_content);
END;

CREATE TRIGGER messages_fts_ad AFTER DELETE ON messages
WHEN old.text_content IS NOT NULL
BEGIN
    INSERT INTO messages_fts(messages_fts, rowid, text_content)
    VALUES ('delete', old.rowid, old.text_content);
END;

CREATE TRIGGER messages_fts_au AFTER UPDATE OF text_content ON messages
BEGIN
    INSERT INTO messages_fts(messages_fts, rowid, text_content)
    SELECT 'delete', old.rowid, old.text_content WHERE old.text_content IS NOT NULL;
    INSERT INTO messages_fts(rowid, text_content)
    SELECT new.rowid, new.text_content WHERE new.text_content IS NOT NULL;
END;
