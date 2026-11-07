# Dotfiles

A reproducible, minimal, security-focused development environment for macOS and Linux.

This repository contains operating system configuration, development tools, shell settings, and security checks designed to make setting up a new machine predictable and auditable.

## Philosophy

The goal is not to install as many tools as possible. The goal is to build a clean, reliable development environment with a small and understandable set of dependencies.

### Core principles

1. **Security first** — minimize privileges, verify software sources, and preserve built-in operating system protections.
2. **Reproducibility** — a fresh machine should be configurable through a documented sequence of commands.
3. **Least privilege** — daily development should not require administrator rights.
4. **Minimalism** — install only tools that serve a clear purpose.
5. **Transparency** — scripts should be readable, deterministic, and explicit about their side effects.
6. **Idempotency** — running setup scripts multiple times should not create duplicate configuration or unnecessary changes.
7. **Portability** — share configuration between macOS and Linux whenever practical.
8. **No secrets in Git** — keep credentials, private keys, tokens, and machine-specific sensitive data outside this repository.

## Security Model

### Separate administrator and development accounts

A new machine uses two local accounts:

| Account | Role | Permissions |
|---|---|---|
| `admin` | System administration | Administrator |
| `dev` | Daily development | Standard user |

The account names are examples; use any names you like.

**Administrator account**

Used for operating system maintenance, privileged software installation, security settings, and actions requiring elevated permissions.

**Development account**

Used for everyday work, programming, browsing, Git, terminal tools, and running development services.

The development account must not belong to the `admin` or `sudoers` group.

### Privilege boundaries

- Run bootstrap and normal setup scripts as the development user.
- Never execute the entire bootstrap as `root`.
- Never use `sudo brew`.
- Require explicit administrator authorization for privileged operations.
- Do not change system-wide permissions merely to make an installation easier.
- Do not weaken SIP, Gatekeeper, FileVault, or other security features to install software.
- Review any command that requests elevated permissions.

A standard user does not provide complete isolation from malicious code. Processes running as that user may still access files and credentials available to the account.

### Software installation

Prefer, in order:

1. Official, signed, and notarized software distributed by its developer.
2. Reviewed packages from trusted package repositories.
3. Third-party package sources only after explicit verification.

Avoid executing remote installation scripts directly through pipelines such as `curl | bash`.

Downloaded installers should be verified before execution. A valid signature establishes the signing identity and integrity, not a guarantee of harmless behavior.

### Development isolation

Use containers or dedicated virtual machines for development workloads where practical.

Treat Docker socket access, host directory mounts, forwarded credentials, and network permissions as security-sensitive.

Containers are not a substitute for a strong security boundary when executing untrusted code.

## Repository Structure

```text
dotfiles/
├── .github/workflows/check.yml   # CI: make check on macOS
├── .editorconfig                 # Formatting rules (also used by shfmt)
├── Makefile                      # check, lint, format, bootstrap, audit
├── macos/
│   ├── bootstrap.sh
│   ├── Brewfile
│   ├── setup/
│   │   ├── xcode.sh
│   │   ├── homebrew.sh
│   │   ├── packages.sh
│   │   ├── containers.sh
│   │   ├── devpod.sh
│   │   ├── shell.sh
│   │   ├── ghostty.sh
│   │   ├── vscodium.sh
│   │   ├── starship.sh
│   │   ├── ssh.sh
│   │   └── git.sh
│   ├── config/
│   │   ├── dock.sh
│   │   ├── finder.sh
│   │   ├── keyboard.sh
│   │   ├── keyboardctl.swift
│   │   ├── keyboard-settings.sh
│   │   ├── trackpad.sh
│   │   └── screenshots.sh
│   └── security/
│       ├── audit.sh
│       ├── configure.sh          # planned
│       ├── monitoring.sh
│       ├── persistence.sh
│       ├── system.sh             # planned
│       └── updates.sh
├── linux/                        # planned
│   └── ...
├── shared/
│   ├── shell/
│   ├── git/
│   │   └── hooks/                # Global Git hooks (secret scanning)
│   ├── ssh/
│   ├── ghostty/
│   ├── vscodium/
│   └── starship/
└── README.md
```

Items marked *planned* do not exist yet. The bootstrap must call only scripts that exist and have been reviewed.

## macOS: Fresh Installation

### Step 1 — Install macOS

Perform a clean installation using official Apple recovery or installation methods.

Avoid restoring applications, executables, shell configuration, or system settings from an untrusted previous installation.

Before proceeding, install available macOS security updates.

### Step 2 — Create the administrator account

During macOS setup, create the initial account:

```text
Username: admin
Role: Administrator
```

Use a unique, strong password.

Keep this account exclusively for administrative tasks.

### Step 3 — Create the development account

While signed in as `admin`:

1. Open **System Settings → Users & Groups**.
2. Create a new Standard user.
3. Assign a separate password.
4. Sign out of `admin`.
5. Sign in to the development account.

Verify its privileges:

```bash
id
```

The development user should not be a member of the `admin` group.

### Step 4 — Configure essential macOS security

Open System Settings and configure:

- FileVault — enabled.
- Firewall — enabled.
- Gatekeeper — enabled.
- System Integrity Protection — enabled.
- Automatic security updates — enabled.
- Automatic login — disabled.
- Screen lock — require a password immediately.

Store the FileVault recovery key securely outside this repository and away from the Mac itself.

Check that the development user is authorized to unlock the FileVault-protected disk.

### Step 5 — Install Apple Command Line Tools

The bootstrap includes a check for Xcode Command Line Tools.

If needed:

```bash
xcode-select --install
```

Complete the interactive installation before proceeding.

### Step 6 — Clone the repository

From the development account:

```bash
mkdir -p ~/Development
cd ~/Development

git clone <repository-url> dotfiles
cd dotfiles
```

Replace `<repository-url>` with the actual repository address.

Do not run commands from a cloned repository before reviewing its scripts and source.

### Step 7 — Run the bootstrap

```bash
./macos/bootstrap.sh
```

Do not use `sudo`.

The bootstrap installs and configures, in order:

1. Apple Command Line Tools (check only).
2. Homebrew.
3. Brewfile packages.
4. Docker Compose integration for Colima and DevPod for dev containers.
5. Zsh, Ghostty, VSCodium, and Starship configuration.
6. SSH client configuration and an SSH key.
7. Git configuration, commit signing, and global hooks.

macOS preferences (Dock, Finder, trackpad, keyboard, screenshots) are applied only on request:

```bash
./macos/bootstrap.sh --macos-defaults
```

The bootstrap does not change security settings and does not run audits; see steps 4 and 9.

Some steps require interactive approval. A bootstrap may stop after a prerequisite is installed and need to be run again.

After the bootstrap, set your Git identity and rerun the Git step so that the signing key is registered:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
bash macos/setup/git.sh
```

Then add the SSH public key to GitHub twice — as an authentication key and as a signing key. `macos/setup/ssh.sh` prints the exact `gh ssh-key add` commands.

### Step 8 — Configure security monitoring

Install and configure:

**BlockBlock**

Monitors persistence mechanisms and other supported suspicious activity.

Official website: https://objective-see.org/products/blockblock.html

**LuLu**

Controls outbound network connections through a macOS Network Extension.

Official website: https://objective-see.org/products/lulu.html

Recommended initial configuration:

- Keep active protection enabled.
- Avoid broad trust rules for unknown programs.
- Review new persistence alerts.
- Review connections from scripting runtimes and development tools.
- Check system permissions requested by security software.

These tools supplement macOS protections; they do not guarantee malware prevention.

### Step 9 — Verify the security baseline

After validating the system, record an initial snapshot of launch persistence. The audit compares against this snapshot and reports a warning until it exists:

```bash
bash macos/security/persistence.sh snapshot
```

Then run the audit:

```bash
bash macos/security/audit.sh
bash macos/security/monitoring.sh
```

Review failures before proceeding.

Do not automatically replace the baseline when changes are detected.

## macOS Script Reference

### Bootstrap and installation

| Script | Purpose |
|---|---|
| `macos/bootstrap.sh` | Orchestrates macOS setup; `--macos-defaults` also applies OS preferences |
| `macos/setup/xcode.sh` | Checks or initiates installation of Apple Command Line Tools |
| `macos/setup/homebrew.sh` | Installs or configures Homebrew and disables analytics |
| `macos/setup/packages.sh` | Checks and installs packages declared in the Brewfile |
| `macos/setup/containers.sh` | Configures the Docker CLI and Compose integration |
| `macos/setup/devpod.sh` | Sets DevPod to the local Docker provider and VSCodium, disables telemetry |
| `macos/setup/shell.sh` | Links the shared Zsh configuration |
| `macos/setup/ghostty.sh` | Links Ghostty configuration |
| `macos/setup/vscodium.sh` | Links VSCodium user settings |
| `macos/setup/starship.sh` | Links Starship prompt configuration |
| `macos/setup/ssh.sh` | Includes shared SSH defaults and creates an Ed25519 key if none exists |
| `macos/setup/git.sh` | Configures shared Git settings, commit signing, and global hooks |

### Operating system preferences

| Script | Purpose |
|---|---|
| `macos/config/dock.sh` | Minimal Dock layout |
| `macos/config/finder.sh` | Finder preferences for development |
| `macos/config/keyboard.sh` | Configures allowed keyboard layouts |
| `macos/config/keyboardctl.swift` | Native macOS keyboard input-source utility |
| `macos/config/keyboard-settings.sh` | Key repeat and text-input preferences |
| `macos/config/trackpad.sh` | Trackpad preferences |
| `macos/config/screenshots.sh` | Screenshot location and behavior |

The intended keyboard layouts are ABC and Ukrainian.

Tracking speed is intentionally left at the macOS default.

### Security

| Script | Purpose |
|---|---|
| `macos/security/audit.sh` | Audits macOS security configuration |
| `macos/security/configure.sh` | *Planned:* applies safe user-level security preferences |
| `macos/security/system.sh` | *Planned:* opens security-related System Settings |
| `macos/security/monitoring.sh` | Checks monitoring tools and components |
| `macos/security/persistence.sh` | Detects changes in launch persistence files |
| `macos/security/updates.sh` | Reports software update configuration |

## Package Management

### Homebrew

Homebrew is used primarily for CLI tools and selected desktop applications.

The macOS installation uses the Apple Silicon prefix:

```text
/opt/homebrew
```

GUI casks may be configured to install into:

```text
~/Applications
```

This supports installation by a Standard user for applications that do not require privileged installer actions.

Some casks still require administrative privileges or system extensions.

Homebrew must not be executed as `root`.

### Brewfile

The list of approved packages is stored at:

```text
macos/Brewfile
```

Check dependencies:

```bash
brew bundle check --file=macos/Brewfile
```

Install approved dependencies:

```bash
bash macos/setup/packages.sh
```

Inspect available updates:

```bash
brew update
brew outdated
```

Apply updates deliberately after review:

```bash
brew upgrade
```

Avoid adding unreviewed third-party taps or packages.

## Development Environment

### Shell

- Interactive shell: Zsh.
- Bootstrap scripts: Bash.
- Shared configuration: `shared/shell/`.
- No Oh My Zsh or remote plugin installer required.

Optional CLI enhancements:

- zoxide — directory navigation.
- bat — syntax-highlighted file viewing.
- eza — enhanced file listing.
- git-delta — improved Git diffs.
- starship — customizable prompt.
- zsh-autosuggestions — suggestions from history while typing.
- zsh-syntax-highlighting — command-line highlighting.
- mise — per-project tool versions (Node.js, Rust, Python, …).
- direnv — per-project environment variables from `.envrc`.

Each tool is loaded only if it is installed. Plugins are sourced from Homebrew or common Linux package paths; no plugin manager is used.

Completion directories are fully security-checked by `compinit` at most once a day; the dump is cached in `~/.cache/zsh/`.

### Terminal

Ghostty is the primary terminal emulator.

Configuration:

```text
shared/ghostty/config.ghostty
```

The configuration is linked into the user's Ghostty config directory.

### Editor

VSCodium is the code editor.

Configuration:

```text
shared/vscodium/settings.json
```

The file is linked to `~/Library/Application Support/VSCodium/User/settings.json`, so changes made in the Settings UI land in the repository. Keep it strict JSON (no comments or trailing commas): `make lint` validates it with `jq`.

Martian Mono is used for the editor, terminal, debug console, SCM input, Markdown preview, and chat. The workbench UI (sidebar, status bar, menus) has no font setting and keeps the system font.

### Git

Git configuration is shared across machines.

Private identification and authentication should remain outside the repository.

Recommended practices:

- Separate SSH keys for unrelated accounts.
- Passphrase-protected private keys.
- Explicit Git identity configuration.
- Verified SSH host keys.

**Commit signing.** Commits and annotated tags are always signed with the SSH key (`gpg.format = ssh`). The key path is machine-specific and is written to `~/.gitconfig` by `macos/setup/git.sh`. Until it is set, commits fail by design. Your own key is added to `~/.config/git/allowed_signers`, so `git log --show-signature` can verify signatures locally.

**Secret scanning.** `core.hooksPath` points to `shared/git/hooks/`. Before every commit, the pre-commit hook runs `gitleaks` on staged changes and blocks the commit if it finds a secret. Bypass a false positive once with `git commit --no-verify`.

Because `core.hooksPath` disables a repository's own `.git/hooks`, every hook in `shared/git/hooks/` is a symlink to a dispatcher that afterwards runs the repository hook of the same name. Repositories that set their own `core.hooksPath` (husky, lefthook) bypass the global hooks, including the secret scan.

### SSH

`shared/ssh/config` holds shared client defaults: Keychain integration, `IdentitiesOnly`, and hashed `known_hosts`. `macos/setup/ssh.sh` includes it at the end of `~/.ssh/config`, so host-specific settings written above it take precedence. It creates an Ed25519 key only if none exists and never overwrites keys.

The key passphrase is stored in the macOS Keychain; `zprofile` loads it into the agent at login so commit signing works before the first SSH connection.

### Containers

Colima provides a Linux virtual machine for local Docker workloads.

Docker CLI and Compose are installed separately.

Useful commands:

```bash
colima start
docker info
docker compose version
colima stop
```

Colima should not be started automatically by every bootstrap run.

### Dev containers

Microsoft's Dev Containers extension is licensed only for Microsoft's VS Code builds and is not available in VSCodium. DevPod is used instead: it reads the same `.devcontainer/devcontainer.json`, runs the container on Colima's Docker, and opens VSCodium connected to it over SSH.

`macos/setup/devpod.sh` selects the `docker` provider and the `codium` IDE, and turns off telemetry.

```bash
colima start
devpod up ~/path/to/project      # create or start, then open VSCodium
devpod stop project              # stop the workspace containers
devpod delete project            # remove them
```

### Editor and AI tools

- VSCodium — primary source-code editor.
- OpenCode — AI coding agent.
- Zen Browser — general-purpose browser.

AI tools should receive only the filesystem access and permissions needed for the current project.

Avoid exposing private SSH keys, cloud credentials, browser profiles, or personal data to development agents.

## Persistence Monitoring

The persistence checker tracks launch configuration in locations such as:

```text
~/Library/LaunchAgents/
/Library/LaunchAgents/
/Library/LaunchDaemons/
```

Create a trusted baseline:

```bash
bash macos/security/persistence.sh snapshot
```

Check for changes:

```bash
bash macos/security/persistence.sh check
```

Inspect differences:

```bash
bash macos/security/persistence.sh diff
```

Review unexpected modifications before updating the baseline.

The checker does not cover every persistence mechanism and cannot be trusted as a tamper-proof security monitor against an attacker controlling the local user or root account.

## Secrets and Sensitive Data

Never commit:

- SSH private keys.
- API tokens or passwords.
- Cloud provider credentials.
- Cryptocurrency wallet secrets or recovery phrases.
- Browser sessions or cookies.
- FileVault recovery keys.
- Production `.env` files.

Use Keychain or an appropriate secrets manager.

If the system has previously been compromised, rotate potentially exposed credentials and generate fresh SSH keys on the clean system.

## Linux Support

Linux setup will live in:

```text
linux/
```

Shared settings should remain in:

```text
shared/
```

Linux-specific setup will use its native package management and permission model.

The same principles apply:

- Separate administrative and development responsibilities.
- Minimum required privileges.
- Reviewed software sources.
- Explicit configuration.
- No secrets in Git.
- Reproducible, idempotent scripts.

Linux setup is planned and should not be considered complete until its scripts are implemented and tested.

## Maintenance

After changing a configuration script:

1. Review the diff.
2. Run `make check`: shellcheck, shfmt, Zsh/Git/SSH config syntax, Swift type-check, and a gitleaks scan.
3. Run the individual script.
4. Verify the resulting configuration.
5. Commit the change.

`make format` applies the shfmt style defined in `.editorconfig`. `make help` lists all targets. CI (`.github/workflows/check.yml`) runs `make check` on every push and pull request.

Periodically review installed software, security permissions, update status, and persistence changes.

Do not treat a successful bootstrap or audit as proof that the operating system is free of malware.

## Non-Goals

This repository is not intended to:

- Disable macOS security features for convenience.
- Install arbitrary software automatically.
- Store credentials or recovery information.
- Give everyday applications administrator privileges.
- Replace endpoint security software with shell scripts.
- Guarantee complete isolation of untrusted code.
- Restore untrusted executables or system settings from a previously compromised installation.

## License

Add a license before publishing or accepting contributions.