# <Project> location map (shared, all bots)

Written <date, time, zone>. **Box-only, read-only pass.** Every ID below was read from a source file or a live read-only query; nothing is invented. Items not re-verified since the last plugin change are marked **[UNVERIFIED]**.

## 0. How to use this file
- Look refs up with `Game.GetFormFromFile(0x<localId>, "<Plugin>.esp")` or by editor ID. **Never hard-code a runtime (load-order) FormID**; load-order prefixes change.
- The same local ID in two plugins is two different refs. Always write IDs as `XXXXXX:Plugin.esp`.
- A "place" may span several cells (e.g. one exterior area = several cells of one worldspace). Test the set, not one cell.
- Owner's rules about places go here verbatim, with date: "<rule>" (<date>).

## 1. How to test "actor is already in X" (Papyrus)
```papyrus
Bool Function InArea(Actor a)
  Cell c = a.GetParentCell()
  Return c == CellA || c == CellB        ; list every cell that counts
EndFunction
```
Walk vs teleport: <when to PathToReference, when to MoveTo, timeouts>.

## 2. Worldspace(s)
| Name | Editor ID | ID | Plugin |
| --- | --- | --- | --- |
| <World> | `<EditorID>` | `XXXXXX` | `<Plugin>.esp` |

## 3. Areas
### 3.1 <Area name>
| What | Editor ID | Ref / Cell ID | Plugin | Notes |
| --- | --- | --- | --- | --- |
| Cell | `<CellEditorID>` | `XXXXXX` | `<Plugin>.esp` | interior / exterior grid x,y |
| Marker | `<MarkerEditorID>` | `XXXXXX` | `<Plugin>.esp` | used by <script> |

## 4. Load doors bots actually walk
| From | To | Door ref | Plugin |
| --- | --- | --- | --- |

## 5. Which scripts move actors here, and whether they check "already there"
| Script | Function | Checks already-there? | Notes |
| --- | --- | --- | --- |

## 6. Suggested shared helpers
<one helper per test, so every script uses the same definition>

## 7. Unconfirmed / traps
- <e.g. a name that looks like a place but is a mod/item>

## 8. Sources
- <file paths / queries with dates>
