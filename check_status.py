#!/usr/bin/env python
"""Global status check script - simple runner without pytest overhead."""

import asyncio
import sys
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from tests.test_global_status import run_global_status_check


async def main():
    """Run the global status check."""
    try:
        await run_global_status_check()
        return 0
    except Exception as e:
        print(f"\n❌ Критическая ошибка: {e}")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
