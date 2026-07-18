# Hotkeys
| Key | Action | No selection | Selected text |
| --- | --- | --- | --- |
| `M` | Inline math | `$<caret>$` | Wraps in `$…$`; unwraps a complete single-dollar selection |
| `E` | Display math | `$$`, empty line, `$$` | Wraps between delimiter-only `$$` lines; unwraps a complete display |
| `F` | Fraction | `\frac{<caret>}{}` | Places the selection in the numerator |
| `D` | Partial | `\partial <caret>` | Places the selection after `\partial ` |
| `C` | Cases | `\begin{cases}` body `\end{cases}` | Places the selection in the body |
| `B` | Matrix | `\begin{bmatrix}` body `\end{bmatrix}` | Places the selection in the body |
| `S` | Square root | `\sqrt{<caret>}` | Places the selection in the radicand |
| `I` | Integral | `\int_{}^{} <caret>` | Places the selection in the integrand position |
| `A` | Aligned | `\begin{aligned}` body `\end{aligned}` | Places the selection in the body |
| `P` | Parentheses | `\left(<caret>\right)` | Places the selection between the parentheses |

## Requirements and launch

Install [AutoHotkey v2](https://www.autohotkey.com/) and double-click `math-hotkeys.ahk`. The script declares `#Requires AutoHotkey v2.0` and was syntax-checked with the current stable v2 release, 2.0.26, on 2026-07-18. AutoHotkey v1 is not supported.

The repository does not add a Windows startup entry. To launch it automatically, create a shortcut to `math-hotkeys.ahk` and place the shortcut in the folder opened by `Win+R`, `shell:startup`. Otherwise, launch it manually when wanted.

Keep `math-hotkeys.ini` beside the script. Restart the script from its notification-area icon after editing the INI.

## Configuration

`[General]` controls the chord timeout (clamped to 100–10000 milliseconds) and tooltip:

```ini
[General]
TimeoutMs=2000
ShowStatus=1
```

`[Keys]` contains one case-insensitive character per action. Invalid entries fall back to their defaults. Duplicate keys use fixed precedence: Inline, Display, Fraction, Partial, Cases, Matrix, Square Root, Integral, Aligned, Parentheses.

`[Applications]` is a comma-separated allowlist. A bare entry matches a process name. A `process.exe|Title text` entry additionally requires the active window title to contain that text, case-insensitively. The default Edge rule therefore activates only in tabs whose window title contains `Overleaf`:

```ini
[Applications]
Allow=Code.exe,notepad.exe,notepad++.exe,Obsidian.exe,Typora.exe,MarkText.exe,sublime_text.exe,msedge.exe|Overleaf
```

`Joplin.exe` is always excluded even if it is added to the allowlist. This lets the plugin preserve CodeMirror selections, native multi-selection mapping, and one-step undo.

## Behavior and limitations

Press and release `Ctrl+M`, then press the configured second key within two seconds. Matching is case-insensitive. `Escape` cancels and common unrelated non-text keys pass through; unrelated printable characters are re-sent on a best-effort basis. A temporary tooltip lists the mappings when enabled.

The companion sends text and caret-navigation keystrokes only. It never reads or writes the clipboard. Consequently, a current selection is replaced by the empty global snippet: filling or wrapping selected text is a Joplin-only feature. Simulated multi-line input can also produce more than one undo step depending on the target application.

The default snippets use LF/Enter-style newlines. The receiving editor decides how those keystrokes are represented in its document.
