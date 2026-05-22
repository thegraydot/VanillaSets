# VanillaSets

World of Warcraft (WoW) Vanilla (1.12) addon to equip Best in Slot gear sets via slash commands.

## Commands

| Command | Description |
|---|---|
| `/vs help` | Show usage |
| `/vs classes` | List all classes and available specs |
| `/vs list <class> <spec> <phase>` | Print BIS gear list to chat |
| `/vs equip <class> <spec> <phase>` | Equip matching items found in your bags |

Phase is a number from 1 to 6.

For classes with only one spec (Hunter, Mage, Warlock), the spec can be omitted.

## Examples

List Best in Slot items for Warrior Fury in Phase 3:
```
/vs list warrior fury 3
```

Equip Best in Slot items for Druid Feral Tank in Phase 2:
```
/vs equip druid feral tank 2
```

List Best in Slot items for Paladin Holy in Phase 6:
```
/vs list paladin holy 6
```

List Best in Slot items for Hunter in Phase 1 (spec omitted):
```
/vs list hunter 1
```

Show all available classes and specs:
```
/vs classes
```

## Notes

- The `equip` command scans bags 0-4 and equips any matching items it finds.
- Items not present in your bags are reported as missing.
- Item names are resolved via `GetItemInfo`. If an item is not cached, it appears as `Item #XXXXX`.
