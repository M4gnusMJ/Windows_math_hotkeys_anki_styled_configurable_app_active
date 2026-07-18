#Requires AutoHotkey v2.0
#SingleInstance Force

SendMode "Input"
SetWorkingDir A_ScriptDir

global ActionOrder := [
    "inline", "display", "fraction", "partial", "cases",
    "matrix", "squareRoot", "integral", "aligned", "parentheses"
]
global ActionLabels := Map(
    "inline", "inline", "display", "display", "fraction", "fraction",
    "partial", "partial", "cases", "cases", "matrix", "matrix",
    "squareRoot", "square root", "integral", "integral",
    "aligned", "aligned", "parentheses", "parentheses"
)
global Snippets := Map(
    "inline", { Text: "$$", Caret: 1 },
    "display", { Text: "$$`n`n$$", Caret: 3 },
    "fraction", { Text: "\frac{}{}", Caret: 6 },
    "partial", { Text: "\partial ", Caret: 9 },
    "cases", { Text: "\begin{cases}`n`t`n\end{cases}", Caret: 15 },
    "matrix", { Text: "\begin{bmatrix}`n`t`n\end{bmatrix}", Caret: 17 },
    "squareRoot", { Text: "\sqrt{}", Caret: 6 },
    "integral", { Text: "\int_{}^{} ", Caret: 11 },
    "aligned", { Text: "\begin{aligned}`n`t`n\end{aligned}", Caret: 17 },
    "parentheses", { Text: "\left(\right)", Caret: 6 }
)
global Config := LoadConfig()
global ActiveHook := ""

#HotIf IsAllowedApplication()
^m::StartMathChord()
#HotIf

LoadConfig() {
    global ActionOrder
    iniPath := A_ScriptDir "\math-hotkeys.ini"
    timeoutValue := IniRead(iniPath, "General", "TimeoutMs", "2000")
    timeoutMs := IsNumber(timeoutValue) ? Round(timeoutValue) : 2000
    timeoutMs := Max(100, Min(10000, timeoutMs))
    showStatus := IniRead(iniPath, "General", "ShowStatus", "1") != "0"

    defaults := Map(
        "inline", "M", "display", "E", "fraction", "F", "partial", "D",
        "cases", "C", "matrix", "B", "squareRoot", "S", "integral", "I",
        "aligned", "A", "parentheses", "P"
    )
    iniNames := Map(
        "inline", "Inline", "display", "Display", "fraction", "Fraction",
        "partial", "Partial", "cases", "Cases", "matrix", "Matrix",
        "squareRoot", "SquareRoot", "integral", "Integral",
        "aligned", "Aligned", "parentheses", "Parentheses"
    )
    keys := Map()
    for action in ActionOrder {
        configured := IniRead(iniPath, "Keys", iniNames[action], defaults[action])
        keys[action] := NormalizeKey(configured, defaults[action])
    }

    defaultApplications := "Code.exe,notepad.exe,notepad++.exe,Obsidian.exe,Typora.exe,MarkText.exe,sublime_text.exe,msedge.exe|Overleaf"
    applications := IniRead(iniPath, "Applications", "Allow", defaultApplications)
    return {
        TimeoutMs: timeoutMs,
        ShowStatus: showStatus,
        Keys: keys,
        Applications: applications
    }
}

NormalizeKey(value, fallback) {
    value := Trim(value)
    return StrLen(value) = 1 ? StrUpper(value) : fallback
}

IsAllowedApplication(*) {
    global Config
    try {
        processName := StrLower(WinGetProcessName("A"))
        windowTitle := StrLower(WinGetTitle("A"))
    } catch {
        return false
    }

    ; Always defer to the Joplin plugin's native CodeMirror transactions.
    if processName = "joplin.exe"
        return false

    for rawRule in StrSplit(Config.Applications, ",") {
        rule := Trim(rawRule)
        if rule = ""
            continue
        separator := InStr(rule, "|")
        if separator {
            ruleProcess := StrLower(Trim(SubStr(rule, 1, separator - 1)))
            titleText := StrLower(Trim(SubStr(rule, separator + 1)))
            if processName = ruleProcess && titleText != "" && InStr(windowTitle, titleText)
                return true
        } else if processName = StrLower(rule) {
            return true
        }
    }
    return false
}

StartMathChord(*) {
    global ActiveHook, Config
    if IsObject(ActiveHook) && ActiveHook.InProgress
        ActiveHook.Stop()

    if Config.ShowStatus {
        ToolTip BuildStatus()
        SetTimer HideStatus, -Config.TimeoutMs
    }

    endKeys := "{Escape}{Enter}{Tab}{Backspace}{Delete}{Insert}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}"
    endKeys .= "{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}"
    ActiveHook := InputHook("L1 T" . (Config.TimeoutMs / 1000), endKeys)
    ActiveHook.VisibleNonText := true
    ActiveHook.KeyOpt("{Escape}", "+S")
    ActiveHook.OnEnd := FinishMathChord
    ActiveHook.Start()
}

FinishMathChord(input) {
    global ActiveHook
    HideStatus()
    ActiveHook := ""

    if input.EndReason != "Max"
        return

    action := FindAction(input.Input)
    if action != ""
        InsertSnippet(action)
    else if input.Input != ""
        SendText input.Input
}

FindAction(key) {
    global ActionOrder, Config
    key := StrUpper(key)
    for action in ActionOrder {
        if key = StrUpper(Config.Keys[action])
            return action
    }
    return ""
}

InsertSnippet(action) {
    global Snippets
    snippet := Snippets[action]
    SendText snippet.Text
    moveLeft := StrLen(snippet.Text) - snippet.Caret
    if moveLeft > 0
        Send "{Left " . moveLeft . "}"
}

BuildStatus() {
    global ActionOrder, ActionLabels, Config
    message := "Math: "
    for index, action in ActionOrder {
        if index > 1
            message .= ", "
        message .= Config.Keys[action] " " ActionLabels[action]
    }
    return message ", Esc cancel"
}

HideStatus(*) {
    ToolTip
}
