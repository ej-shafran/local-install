# pack-and-install

## Installation

```bash
npm install -g pack-and-install
```

## Usage

```bash
pack-and-install [-k] [path]
```

Will pack the NPM package at `path` into a `.tgz` file and install it, then remove the `.tgz` file. If `path` isn't passed, you will be prompted to enter it.

If you want the `.tgz` file not to be removed, use `-k` or `--keep-tar`.
