# [Documentation](docs/documentation.md)
## Installation
Importing Party as a local package from [releases](https://github.com/Fanatrick/GMParty/releases) rather than cloning the repo is encouraged. The only difference between the two is that `src` often includes in-development stuff, demos and examples so it can be self-sufficiently ran as a GameMaker project.

### Importing into your own projects
- Download the latest [release](https://github.com/Fanatrick/GMParty/releases).
- Import a `GMParty-X.X.X.yymps` local package via GM-IDE `Tools -> Import Local Package`
	- All files and directories are necessary except `GMParty/hooks`. If you're not interested in overriding the native particle system you can freely omit that whole directory. See [Hooks](docs/dev/hooks.md).

**or**

- Clone the repo via `github` cli:
	- `gh repo clone Fanatrick/GMParty`
- Open the project in GM-IDE and export `Tools -> Create Local Package`
- Import files from local package to your project's directory, optionally omitting `GMParty/hooks`.

---
<- [Requirements and limitations](docs/setup/requirements.md)
-> [Configuration](docs/setup/configuration.md)

