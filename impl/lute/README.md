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