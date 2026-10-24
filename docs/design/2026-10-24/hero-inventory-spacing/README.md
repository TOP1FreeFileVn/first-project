# Hero and inventory spacing review

Captures the actual production equipment page at 360×640 and 450×800 without visual overrides. The fixture uses all 17 item definitions, four equipped items and 13 spare items, preserving the five-column inventory and original carton navigation.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs/design/2026-10-24/hero-inventory-spacing/run-review.ps1
```

The focused checks cover three complete inventory rows, clearance above the bottom navigation, four weapon forms playing their authored idle, and the fuse action retaining the header position while the inventory scrolls. Screenshots and `review.json` are written to `native/`.

The runner uses an isolated Godot profile. Fixture changes stay in memory, the original state and persistence setting are restored, and save hashes are checked before and after.

The last completed native review, before the lower clip adjustment below, passed **243 checks, 20 captures, zero failures**. At both sizes the hero section is 500 logical pixels high, the inventory is 576, and the third row ends 19 logical pixels before the navigation boundary. Both sections fit the 720-pixel page width; the normal three-row inventory needs no scrollbar. All four sampled idle forms clear the equipment columns and power plaque. The fuse action keeps the header in place and its last item remains reachable by scrolling, without widening the page. Save hashes remain `absent → absent`.

The fixture now also expects a 12-logical-pixel lower clip offset: content ends at 1088, the inventory grows to 588, and the hero and header remain at their existing positions. The scroll ends at 1080, before the actual navigation button hitboxes begin at 1082. These updated assertions also cover the fuse state and have not been rerun as part of this small adjustment. The linked captures and report remain from the completed review above.

- [360×640 page](native/full-three-rows_360x640.png)
- [450×800 page](native/full-three-rows_450x800.png)
- [Fuse and scrolling](native/fuse-scroll_360x640.png)
- [Review report](native/review.json)
