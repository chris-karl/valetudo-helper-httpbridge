> **Note:** This repository is a fork of
> [Hypfer/valetudo-helper-httpbridge](https://github.com/Hypfer/valetudo-helper-httpbridge).
> On top of the upstream project, it adds macOS support (Apple Silicon and Intel builds)
> and ships with updated third-party dependencies.

# valetudo-helper-httpbridge

![example](https://user-images.githubusercontent.com/974410/162291456-7675c8de-e513-41f6-a9f7-954c8c621d07.png)


valetudo-helper-httpbridge is a small utility webserver providing file upload functionality.

It comes as a single binary with no additional dependencies and requires only experience with a terminal.

Simply download the latest binary [from the releases section](https://github.com/joldjunge/valetudo-helper-httpbridge/releases)
and execute it in a terminal/powershell window.

Builds are provided for Windows (x64), Linux (x64 and armv7) and macOS (Apple Silicon `arm64` and Intel `x64`).



## Running on macOS

Pick the matching binary:

- `valetudo-helper-httpbridge-macos-arm64` — Apple Silicon (M1/M2/M3/…)
- `valetudo-helper-httpbridge-macos-x64` — Intel Macs

The binaries are signed ad-hoc but not notarized, so after downloading you'll need to make the file
executable and clear the quarantine flag Gatekeeper adds to downloaded files:

```sh
chmod +x ./valetudo-helper-httpbridge-macos-arm64
xattr -d com.apple.quarantine ./valetudo-helper-httpbridge-macos-arm64
./valetudo-helper-httpbridge-macos-arm64
```

(Alternatively, the first time you can right-click the binary in Finder and choose "Open", or allow it via
System Settings → Privacy & Security → "Open Anyway".)



## Valetudo helpers

Valetudo helpers are a series of small standalone self-contained single-purpose single-file tools built to make
usage and/or installation of Valetudo a bit easier.

As with everything Valetudo, some intermediate computer skills are required. You should know what a network is,
what HTTP is, how a terminal works and that kind of stuff.
If these topics are still new to you, don't worry. There are plenty of great resources out there to learn them.
Providing support with them, however, is a bit more than a small open source project like this one can take on.
