INSERT INTO feeds (name, url, priority_weight, enabled) VALUES
('GameSpot', 'https://www.gamespot.com/feeds/mix/', 8, true),
('IGN', 'https://feeds.ign.com/ign/all', 9, true),
('Kotaku', 'https://kotaku.com/rss', 7, true),
('The Verge', 'https://www.theverge.com/rss/index.xml', 6, true),
('PC Gamer', 'https://www.pcgamer.com/feed/', 8, true)
ON CONFLICT (name) DO NOTHING;

SELECT name, url, enabled FROM feeds ORDER BY priority_weight DESC;
