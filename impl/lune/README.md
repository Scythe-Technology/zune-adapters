# Adapter for Lune

**Lune**: `0.10.5`

**.luaurc**:
```json
{
    "aliases": {
        "lune": "path/to/./impl/lune",
        ...
    }
}
```

## **Notes**
`zune`'s task scheduler may behave differently than the `lune`'s task scheduler, which may lead to some differences in behavior when using tasks/async related API in this `lune` adapter.

`lune`/`mlua`'s limitations would not apply to this adapter, and most likely will not copy limitations.
- For example maximum number of threads, maximum number of tasks, etc.

## **Compatability**
| status | defintion |
|--------|-----------|
| ✅ | Complete adapter compatibility with the runtime's API |
| ❌️ | No adapter compatibility implemented |
| `#%` | Percent of adapter compatibility implemented (amount is based on number of api namespaces/functions) |

### `@lune`
| library | supported | notes |
|---------|-----------|-------|
| fs | ✅ | |
| net | ✅ | |
| luau | ✅ | |
| task | ✅ | |
| stdio | ✅ | |
| regex | ✅ | |
| serde | `91.66%` (5.5/6) | missing `brotli` |
| process | ✅ | |
| roblox | ❌️ | WIP, [luau-roblox](https://github.com/Scythe-Technology/luau-roblox) can be used here (no XML) |
| datetime | ✅ | |
