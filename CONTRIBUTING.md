# Contributing

Thank you for contributing to Hibernate Installer.

## Development principles

- Keep modules small and focused.
- Prefer safe, reversible changes.
- Never overwrite system configuration without a timestamped backup.
- Keep ShellCheck clean.
- Preserve idempotency.

## Testing

Run ShellCheck before submitting changes:

```bash
shellcheck install.sh uninstall.sh lib/*.sh tests/*.sh
```

## Versioning

This project follows Semantic Versioning.
