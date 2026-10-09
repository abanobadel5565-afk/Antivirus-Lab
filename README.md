# Antivirus Lab

A small bash antivirus simulation made of two scripts:

| File | Purpose |
|---|---|
| `antivirusd.sh` | Daemon that watches a folder and moves suspicious files to quarantine |
| `restore.sh` | Interactive tool to review quarantined files and restore false positives |
| `whitelist` | Plain text file listing files that are trusted and must never be quarantined again |

## Requirements

- Linux with `bash`
- Standard tools: `find`, `grep`, `cmp`, `ls`, `sed`, `mv`, `cp`, `rm`
- Both scripts must be executable:

```bash
chmod +x antivirusd.sh restore.sh
```

## Folder layout

```
antivirus-lab/
├── antivirusd.sh
├── restore.sh
├── whitelist
├── watch/        # folder being monitored
└── quarantine/   # suspicious files are moved here
```

**Important:** run both scripts from inside the `antivirus-lab` folder (`cd ~/antivirus-lab`). The whitelist path is `./whitelist`, so both scripts must see the same working directory to share the same file.

## 1. The daemon: `antivirusd.sh`

### Usage

```bash
./antivirusd.sh <watch_dir> <quarantine_dir> <seconds>
```

Example:

```bash
./antivirusd.sh watch quarantine 5
```

### How it works

1. Every `<seconds>` seconds, the daemon saves a listing of the watch folder (`ls -l`) and compares it with the previous one.
2. If nothing changed, it prints `Nothing has been detected`.
3. If something changed, it prints `New files have been detected` and scans every file in the watch folder.
4. A file is flagged as malicious if:
   - its extension is one of: `exe`, `bat`, `vbs`, `scr`, `ps1`, **or**
   - its content contains one of the keywords: `virus`, `trojan`, `malware`, `worm`, `ransomware` (case-insensitive).
5. Flagged files are copied to the quarantine folder and removed from the watch folder.
6. Files found in the whitelist are skipped (see below).

Stop the daemon with `Ctrl+C` (or `kill %1` if it runs in the background).

## 2. Reviewing quarantined files: `restore.sh`

### Usage

```bash
./restore.sh <watch_dir> <quarantine_dir>
```

Example:

```bash
./restore.sh watch quarantine
```

### How it works

1. Lists all files currently in quarantine, numbered. If it is empty, it prints `No malicious files to review.` and exits.
2. Asks you to choose a file by its number. An invalid number prints `Your Index is out of boundaries` and exits with code 1.
3. Asks whether to restore the file (`y` / `n`):
   - `y`: the file is moved back to the watch folder **and added to the whitelist**.
   - `n`: nothing is changed; the file stays in quarantine.
   - anything else: `Wrong Choice!` and exit code 1.

## 3. Whitelist (Bonus 2)

Without a whitelist, a restored file would be flagged again on the next scan, because its extension or content has not changed. The whitelist solves this.

### How a file gets added

When you restore a file with `restore.sh` (answer `y`), the script:

1. moves the file from the quarantine folder back to the watch folder, and
2. appends the **file name** as a new line at the end of the `whitelist` file:

```bash
echo "$name" >> "$whitelist"
```

(`>>` appends, so earlier entries are kept.)

### How the daemon checks it

During every scan, after the extension and keyword checks, `antivirusd.sh` looks for the file name in the whitelist:

```bash
if grep -Fxq "$filename" "$WhiteList"; then
    malicious="no"
fi
```

- `-F` treats the name as plain text, not a regular expression
- `-x` requires the whole line to match, so `a.exe` does not match `a.exe.bak`
- `-q` makes `grep` silent; only its exit code is used

If the name is found, the file is marked safe and is **not** quarantined, even if it still matches a flagged extension or keyword.

### Persistence

The whitelist is a regular file on disk, so it survives stopping and restarting the daemon. The next run reads the same `whitelist` file and keeps respecting it.

### Limitation

Only the **file name** is stored, not the full path or the content. This means any file with a whitelisted name is trusted, in any folder. A stricter design would store the full path or a SHA-256 hash of the file.

## Quick test

```bash
cd ~/antivirus-lab
./antivirusd.sh watch quarantine 5 &

echo "x" > watch/test.exe       # create a flagged file
sleep 7
ls quarantine                   # test.exe should be here

./restore.sh watch quarantine   # choose 1, then y
cat whitelist                   # should contain: test.exe

sleep 7
ls watch                        # test.exe should still be here (not re-quarantined)

kill %1                         # stop the daemon
```

To prove persistence, start the daemon again and check that `test.exe` is still not moved.

## Notes

- The daemon creates two helper files in the working folder: `newDirectoryReport` and `currentDirectoryReport`. They are used to detect changes in the watch folder.
- Filenames containing spaces are not fully supported by `restore.sh`.
