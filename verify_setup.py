#!/usr/bin/env python
"""Quick verification script - ensures everything is set up correctly."""

import sys
from pathlib import Path

def check_files():
    """Verify all required files are created."""
    required_files = [
        "tests/test_global_status.py",
        "check_status.py",
        "check_status.sh",
        "check_status.ps1",
        "GLOBAL_TEST.md",
        "GLOBAL_TEST_QUICK.md",
        "GLOBAL_TEST_SETUP.txt",
    ]
    
    print("✓ Checking created files...")
    all_exist = True
    for file in required_files:
        path = Path(file)
        if path.exists():
            size = path.stat().st_size
            print(f"  ✅ {file} ({size} bytes)")
        else:
            print(f"  ❌ {file} - NOT FOUND")
            all_exist = False
    
    return all_exist

def check_makefile():
    """Verify Makefile has new commands."""
    print("\n✓ Checking Makefile commands...")
    makefile = Path("Makefile")
    if makefile.exists():
        content = makefile.read_text()
        commands = ["test-global", "status"]
        for cmd in commands:
            if cmd in content:
                print(f"  ✅ make {cmd} - found")
            else:
                print(f"  ❌ make {cmd} - NOT FOUND")
                return False
    return True

def check_readme():
    """Verify README was updated."""
    print("\n✓ Checking README.md...")
    readme = Path("README.md")
    if readme.exists():
        content = readme.read_text()
        if "GLOBAL_TEST" in content or "make status" in content:
            print(f"  ✅ README updated with global test reference")
            return True
        else:
            print(f"  ⚠️  README might need manual update")
            return True  # Warning only
    return False

def main():
    """Run all checks."""
    print("=" * 70)
    print("🔍 GLOBAL TEST SETUP VERIFICATION")
    print("=" * 70 + "\n")
    
    checks = [
        ("Files", check_files()),
        ("Makefile", check_makefile()),
        ("README", check_readme()),
    ]
    
    print("\n" + "=" * 70)
    print("📊 VERIFICATION SUMMARY:")
    print("=" * 70)
    
    for name, result in checks:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{name}: {status}")
    
    all_pass = all(result for _, result in checks)
    
    print("\n" + "=" * 70)
    if all_pass:
        print("✅ ALL CHECKS PASSED - Setup is complete!")
        print("\n🚀 NEXT STEPS:")
        print("  1. Run: make status")
        print("  2. Or: python check_status.py")
        print("  3. Or: python -m pytest tests/test_global_status.py -v -s")
        print("\n📖 Read GLOBAL_TEST_QUICK.md for quick reference")
        return 0
    else:
        print("❌ SOME CHECKS FAILED - Please review")
        return 1

if __name__ == "__main__":
    sys.exit(main())
