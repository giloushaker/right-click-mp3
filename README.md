# Right Click MP3

Right-click a video or music file in Windows Explorer → **Convert To** → **MP3**. Done.

Made for people who just want an MP3 for an old MP3 player and should not have to
learn a video editor, dodge ads, or upload their files to a website.

**[Website and download →](https://giloushaker.github.io/right-click-mp3/)**

- Works on a whole selection at once — select 40 files, pick the format once.
- Saves the new file next to the original. Nothing is overwritten or deleted.
- Uses [ffmpeg](https://ffmpeg.org/) under the hood, downloaded on first use, no admin rights.
- No ads, no telemetry, no bundled extras. MIT licensed, all source in this repo.

**Converts to:** MP3 (192 or 320 kbps), AAC/M4A, WAV, FLAC.
**Reads:** mp4, mkv, mov, avi, webm, wmv, m4a, aac, ogg, opus, wma, wav, flac, mp3.

## Install

1. Download `Right-Click-MP3-Setup.exe` from the
   [latest release](https://github.com/giloushaker/right-click-mp3/releases/latest).
2. Run it. It installs for your user only, so Windows never asks for an
   administrator password.
3. Windows may show a blue "Windows protected your PC" box because the installer
   is not code-signed yet — click **More info** → **Run anyway**.

That is it. The menu is available immediately, no reboot or sign-out.

### Install from source instead

```powershell
# download and unzip the repo, then from that folder:
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-user.ps1
```

Same result, nothing is compiled. `-NoCopy` registers the menu against the
current folder instead of copying to `%LOCALAPPDATA%\Programs\RightClickMP3`.

## Use

1. Select one or more files in File Explorer.
2. Right-click → **Convert To** → pick a format.
   On Windows 11 it is under **Show more options** (or press `Shift+F10`).
3. A small progress window appears with a Cancel button. The new files land in
   the same folder as the originals.

The first conversion asks permission to download ffmpeg (~30 MB) into your user
folder. After that it starts instantly.

You can also open **Right Click MP3** from the Start menu to pick files by hand.

## Uninstall

Any one of these:

- **Settings → Apps → Installed apps → Right Click MP3 → Uninstall.**
- Or run the uninstall script:
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\Programs\RightClickMP3\uninstall-user.ps1"
  ```

Either removes the right-click menu, the Start menu shortcut, the program folder
and its copy of ffmpeg. Nothing is left in the registry, and your converted files
are untouched.

## Files

| File | What it does |
| --- | --- |
| `convert.ps1` | The converter: queue, ffmpeg calls, progress window |
| `convert.vbs` | Starts `convert.ps1` without a black console window |
| `install-user.ps1` | Adds the Explorer menu under `HKCU`, no admin |
| `uninstall-user.ps1` | Removes the menu, the shortcut and the files |
| `ffmpeg-get.ps1` | Downloads ffmpeg into your user folder |
| `installer.iss` | [Inno Setup](https://jrsoftware.org/isinfo.php) script for the `.exe` |
| `docs/` | The GitHub Pages site |

## How it handles a multi-file selection

Explorer runs the command once per selected file. The first process becomes the
worker and converts the entire selection; the others hand over their file and
exit. One progress window, not forty.

If the output name is taken, the new file becomes `song (1).mp3`.

## License

MIT — see [LICENSE](LICENSE). ffmpeg is downloaded separately and stays under its
own license.
