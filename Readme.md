# LeiOS Base Files Branding Package

This is the `leios.system.base-files` package. It does **not** replace Debian's
`base-files` package; instead it depends on it and applies LeiOS-specific
branding using `dpkg-divert`.

## What this package does

- Diverts a small set of files installed by Debian `base-files`:
  - `/usr/lib/os-release`
  - `/etc/lsb-release`
  - `/etc/issue`
  - `/etc/issue.net`
  - `/etc/legal`
  - `/etc/motd`
- Installs the LeiOS versions of these files.
- Ships raw branding templates under:

  ```
  /usr/share/leios/system/utils/base-files/dynamic-raw-files/
  ```

  and an installer script at:

  ```
  /usr/share/leios/system/utils/base-files/install.sh
  ```

- During configuration, `install.sh` is executed. It reads the current LeiOS
  metadata from `/usr/share/leios/system/utils/branding-meta-files/`
  (supplied by `leios.system.branding-meta-files`), replaces the
  `{{INSERT_LEIOS_*}}` placeholders in the templates, and writes the final
  files to `/usr/lib/os-release` (with `/etc/os-release` as a relative
  symlink), `/etc/lsb-release`, `/etc/issue`, and `/etc/issue.net`.

## Why this design?

Because LeiOS is a rolling-release distribution, the version information changes
frequently. With this split:

- `leios.system.base-files` only needs to be rebuilt when branding logic or
  file contents change.
- `leios.system.branding-meta-files` is rebuilt for each rolling release and
  simply provides the new metadata.
- Debian's upstream `base-files` can be updated independently, without
  requiring any manual merge into this repository.

## Building

```bash
make package
```

For example:

```bash
make package
```

This produces the `.deb` package in `deb-build/`. The actual branding version
is read from `leios.system.branding-meta-files` at install time.
