# Adapter for Lute

**Lute**: `0.1.0-nightly.20250905`

**.luaurc**:
```json
{
    "aliases": {
        "lute": "path/to/./impl/lute/runtime",
        "std": "path/to/./impl/lute/std",
        ...
    }
}
```

## **Compatability**
### `@lute`
| library | supported |
|---------|-----------|
| fs | ✅ |
| vm | ✅ |
| luau | ✅ |
| net | `75%` (1.5/2) |
| crypto | ✅ |
| system | `87.5%` (7/8) |
| time | ✅ |
| process | ✅ |
| task | ✅ |
### `@std`
| library | supported |
|---------|-----------|
| table | ✅ |
| task | ✅ |
| time | ✅ |
| vector | ✅ |