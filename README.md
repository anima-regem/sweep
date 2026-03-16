# Sweep

Swipe your gallery clean.

Sweep is an Android-first Flutter app that turns gallery cleanup into a swipe workflow.

## Implemented PRD Scope

- Gallery scan engine with selectable scan scope:
  - Entire Gallery
  - Specific Folder
  - Camera Roll Only
  - WhatsApp Media
  - Screenshots
  - Downloads
- Local media index persistence using Hive
- Smart discovery modes:
  - Largest Files
  - Oldest Media
  - Random Mode
  - Duplicate Detector
  - Screenshots
  - WhatsApp Media
  - Camera Roll
  - Downloads
  - Folder Swipe
- Full swipe interaction:
  - Swipe left: mark for deletion
  - Swipe right: keep
  - Swipe up: tag/organize + move to folder
  - Swipe down: skip
  - Card stack depth, tilt, overlay feedback, haptics
- Deletion review system (Trash):
  - Restore item(s)
  - Permanently delete item(s)
  - Delete all
  - Deletion summary before commit
- Tagging system:
  - Create tags
  - Assign multiple tags
  - Browse media by tag
- Bulk selection mode (Explore):
  - Delete / Move / Tag in batch
- Storage insights dashboard:
  - Total count
  - Total size
  - Largest videos
  - Duplicate count
  - Folder usage
  - Reclaimable storage meter
- Home, Swipe, Trash, Explore, Tags, and Profile tabs

## Notes

- The app uses `photo_manager` for real gallery indexing.
- Permanent delete and folder move attempt native gallery operations for real assets.
- If media permissions are denied or unavailable, Sweep falls back to a generated local demo index so all features remain usable.

## Run

```bash
flutter pub get
flutter run
```

.
