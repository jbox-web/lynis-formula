# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This fork is one of the clones described in `../CLAUDE.md` (toolchain, CI,
lint, the `template-formula` layout). This file only records what is specific to
`lynis-formula`.

## Commands

```bash
bundle install
bin/kitchen list                                  # 3 instances: default-<platform>
bin/kitchen converge default-debian-13-3008-2
bin/kitchen verify   default-debian-13-3008-2
bin/kitchen test     default-debian-11-3006-27    # full cycle on one instance
pre-commit run --all-files
```

There is a single Kitchen suite, `default`, fed by `test/salt/pillar/default.sls`.
`.kitchen/logs/` may still hold `repo-*` logs: that suite was removed together
with the repository state, ignore them.

## What the formula does

Three state groups, included by `lynis/init.sls`:

- `lynis.package` — installs `lynis` (plus `lynis-plugins` when
  `install_plugins` is true) from the repositories **already configured on the
  host**. The formula manages no package repository: the source and repo states
  were dropped (`bacccc8`); the CISOfy repository, if wanted, belongs to
  apt-formula. The Amazon Linux 2 EPEL and Gentoo `portage_config` branches in
  `package/install.sls` are upstream leftovers no platform exercises.
- `lynis.config` — one `file.managed` per entry of `lynis:config:profiles`,
  written to `<config_dir>/<profile>.prf` from `profile.tmpl.jinja`.
- `lynis.service` — not a daemon: a systemd `lynis.service` (oneshot,
  `<bin> audit system --cronjob`) plus `lynis.timer` (`OnCalendar`,
  `RandomizedDelaySec`, `Persistent=true`), both under `/etc/systemd/system/`.
  The report stays on the host (`/var/log/lynis-report.dat`). With
  `audit:enabled: false` the same state stops and disables the timer, then
  removes both units; `daemon-reload` runs on unit changes in both branches.

## Pillar shape and the profile template

```yaml
lynis:
  config:
    profiles:
      <profile>:               # -> /etc/lynis/<profile>.prf
        <lynis-option>:        # e.g. skip-test; becomes `<option>=<name>`
          - name: KRNL-5788
            description: ...   # rendered as a `# Description:` comment
            reason: ...        # rendered as a `# Reason:` comment
```

Merged pillars can list the same entry twice. The template writes an entry once
per `name|description` pair; same name with a different description is kept on
purpose (distinct comments). The test pillar carries a deliberate duplicate of
`KRNL-5788`, and `config_spec.rb` asserts it appears exactly once — keep both
when editing either.

## Deviations from the template layout

- `map.jinja` layers only `defaults.yaml` and `osfamilymap.yaml` (then pillar
  `lookup`, then pillar root). There is no `osarchmap`, `osmap` or
  `osfingermap`; add the file *and* the `filter_by` level before using one.
- `lynis._mapdata` runs in the suite's `state_top`, but there are no reference
  dumps under `test/integration/default/files/_mapdata/` and no control reads
  `/tmp/salt_mapdata_dump.yaml`: a change to `defaults.yaml` or the test pillar
  has no dump to update.
- TOFS lookup ids, for per-minion template overrides:
  `lynis/config/install/profile/<profile>` and `lynis/service/unit/{service,timer}`.
- `release.config.js`, `release-rules.js` and `pre-commit_semantic-release.sh`
  are upstream semantic-release files; no fork runs them.
