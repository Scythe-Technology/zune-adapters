# Adapter for Lune

**Lune**: `0.10.2`

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

Usage errors also would not be the same as `lune`, stack traces, error messages, may differ when running code.
- Some errors are converted to match `lune` but not all cases are handled.

When using `type`/`typeof` on known `lune` userdata, this adapter would not likely not return any unique type names because the implementations are table based, mocking the properties, methods, and metamethods of the original userdata type. If you need exact unique type names as how `lune` has it, you would most likely need to override the `type`/`typeof` global.

Extra unexpected features can occur in this adapter, such as extra compression format that does not exist in `lune` but exists in `zune`, or other features that are not present in `lune` but are present in `zune`. These features would not be documented in this adapter's documentation, and could be considered as an extension of the original `lune` API.
- For example, more `HashAlgorithm` options, like `"sha3_shake128"`. Undocumented in `adapter` types, but available at runtime.
- Second example, more `EncodeDecodeFormat` and `CompressDecompressFormat` options, like `"base64"` and `"flate"`. Undocumented in `adapter` types, but available at runtime.

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
