"""Add popular gaming news RSS feeds.

Revision ID: 002
Revises: 001
Create Date: 2025-01-17 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
from datetime import datetime
from uuid import uuid4


# revision identifiers
revision: str = "002"
down_revision: Union[str, None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add popular gaming news feeds."""
    # Insert 5 popular gaming news aggregators
    feeds_data = [
        {
            'id': str(uuid4()),
            'name': 'GameSpot News',
            'url': 'https://www.gamespot.com/feeds/news/',
            'priority_weight': 8,
        },
        {
            'id': str(uuid4()),
            'name': 'IGN Gaming News',
            'url': 'https://feeds.ign.com/ign/all',
            'priority_weight': 9,
        },
        {
            'id': str(uuid4()),
            'name': 'Kotaku Gaming',
            'url': 'https://kotaku.com/feed',
            'priority_weight': 7,
        },
        {
            'id': str(uuid4()),
            'name': 'The Verge Gaming',
            'url': 'https://www.theverge.com/rss/gaming.xml',
            'priority_weight': 6,
        },
        {
            'id': str(uuid4()),
            'name': 'PC Gamer News',
            'url': 'https://www.pcgamer.com/feeds',
            'priority_weight': 8,
        },
    ]

    for feed in feeds_data:
        op.execute(f"""
            INSERT INTO feeds (id, name, url, enabled, priority_weight, last_fetch_at, 
                               last_fetch_success, consecutive_failures, created_at, updated_at)
            VALUES ('{feed['id']}', '{feed['name']}', '{feed['url']}', true, 
                    {feed['priority_weight']}, now(), true, 0, now(), now())
        """)


def downgrade() -> None:
    """Remove gaming feeds."""
    feed_names = [
        'GameSpot News',
        'IGN Gaming News',
        'Kotaku Gaming',
        'The Verge Gaming',
        'PC Gamer News',
    ]
    
    for name in feed_names:
        op.execute(f"DELETE FROM feeds WHERE name = '{name}'")
