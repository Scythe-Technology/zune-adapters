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

## **Notes**
`zune`'s task scheduler may behave differently than the `lute`'s task scheduler, which may lead to some differences in behavior when using tasks/async related API in this `lute` adapter.

Usage errors also would not be the same as `lute`, stack traces, error messages, may differ when running code.

When using `type`/`typeof` on known `lute` userdata, this adapter would not likely not return any unique type names because the implementations are table based, mocking the properties, methods, and metamethods of the original userdata type. If you need exact unique type names as how `lute` has it, you would most likely need to override the `type`/`typeof` global.

Extra unexpected features can occur in this adapter, such as extra compression format that does not exist in `lute` but exists in `zune`, or other features that are not present in `lute` but are present in `zune`. These features would not be documented in this adapter's documentation, and could be considered as an extension of the original `lute` API.
- For example, you can get more `Hash` options by a custom table input with `"blake3"` in `__hash` property. Undocumented in `adapter` types, but available at runtime.

## **Compatability**
| status | defintion |
|--------|-----------|
| ✅ | Complete adapter compatibility with the runtime's API |
| ❌️ | No adapter compatibility implemented |
| `#%` | Percent of adapter compatibility implemented (amount is based on number of api namespaces/functions) |

### `@lute`
| library | supported | notes |
|---------|-----------|-------|
| fs | ✅ | |
| vm | ✅ | |
| luau | ✅ | |
| net | `75%` (1.5/2) | unsupported `tls` option for `net.serve` |
| crypto | ✅ | |
| system | `87.5%` (7/8) | missing `cpus`/`cpuinfo` |
| time | ✅ | |
| process | ✅ | |
| task | ✅ | |
### `@std`
| library | supported | notes |
|---------|-----------|-------|
| table | ✅ | |
| task | ✅ | |
| time | ✅ | |
| vector | ✅ | |