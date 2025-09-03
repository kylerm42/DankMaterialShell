import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtCore
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Common
import qs.Modals
import qs.Modals.FileBrowser
import qs.Services
import qs.Widgets
import qs.Modals.Settings
import qs.Modals.Spotlight

pragma ComponentBehavior: Bound

PanelWindow {
    id: root

    property bool notepadVisible: false
    property bool fileDialogOpen: false
    property string currentFileName: ""
    property bool hasUnsavedChanges: false
    property url currentFileUrl
    property var modelData: null
    property bool animatingOut: false

    function show() {
        notepadVisible = true
    }

    function hide() {
        animatingOut = true
        notepadVisible = false
        hideTimer.start()
    }

    function toggle() {
        if (notepadVisible) {
            hide()
        } else {
            show()
        }
    }

    visible: notepadVisible || animatingOut
    screen: modelData
    
    anchors.top: true
    anchors.bottom: true
    anchors.right: true
    
    implicitWidth: 480
    implicitHeight: modelData ? modelData.height : 800
    
    color: "transparent"
    
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: (notepadVisible && !animatingOut) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Background click to close
    MouseArea {
        anchors.fill: parent
        enabled: notepadVisible && !animatingOut
        onClicked: mouse => {
            var localPos = mapToItem(notepadPanel, mouse.x, mouse.y)
            if (localPos.x < 0 || localPos.x > notepadPanel.width || localPos.y < 0 || localPos.y > notepadPanel.height) {
                hide()
            }
        }
    }

    StyledRect {
        id: notepadPanel
        
        anchors.fill: parent
        color: Theme.surfaceContainer
        border.color: Theme.outlineMedium
        border.width: 1
        
        focus: true  // Enable keyboard focus
        
        transform: Translate {
            x: notepadVisible ? 0 : 480
            
            Behavior on x {
                NumberAnimation {
                    duration: Theme.longDuration
                    easing.type: Theme.emphasizedEasing
                }
            }
        }

        // Keyboard shortcuts
        Keys.onPressed: (event) => {
            if (event.modifiers & Qt.ControlModifier) {
                switch (event.key) {
                case Qt.Key_S:
                    event.accepted = true;
                    root.fileDialogOpen = true
                    saveBrowser.open()
                    break;
                case Qt.Key_O:
                    event.accepted = true;
                    root.fileDialogOpen = true
                    loadBrowser.open()
                    break;
                case Qt.Key_N:
                    event.accepted = true;
                    SessionData.notepadContent = ""
                    root.currentFileName = ""
                    root.currentFileUrl = ""
                    root.hasUnsavedChanges = false
                    textArea.forceActiveFocus()
                    break;
                }
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            // Header
            Row {
                width: parent.width
                height: 40

                Column {
                    width: parent.width - closeButton.width
                    spacing: Theme.spacingXS
                    anchors.verticalCenter: parent.verticalCenter
                    
                    StyledText {
                        text: qsTr("Notepad")
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                    }
                    
                    StyledText {
                        text: (root.hasUnsavedChanges ? "● " : "") + (root.currentFileName || qsTr("Untitled"))
                        font.pixelSize: Theme.fontSizeSmall
                        color: root.hasUnsavedChanges ? Theme.primary : Theme.surfaceTextMedium
                        visible: root.currentFileName !== "" || root.hasUnsavedChanges
                        elide: Text.ElideMiddle
                        maximumLineCount: 1
                        width: parent.width - Theme.spacingM
                    }
                }

                DankActionButton {
                    id: closeButton
                    iconName: "close"
                    iconSize: Theme.iconSize - 4
                    iconColor: Theme.surfaceText
                    hoverColor: Theme.errorHover
                    onClicked: root.hide()
                }
            }

            // Text area
            StyledRect {
                width: parent.width
                height: parent.height - 140
                color: Theme.surface
                border.color: Theme.outlineMedium
                border.width: 1
                radius: Theme.cornerRadius

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 1
                    clip: true

                    TextArea {
                        id: textArea
                        text: SessionData.notepadContent
                        placeholderText: qsTr("Start typing your notes here...")
                        font.family: SettingsData.monoFontFamily
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        selectByMouse: true
                        selectByKeyboard: true
                        wrapMode: TextArea.Wrap
                        focus: root.notepadVisible
                        activeFocusOnTab: true
                        textFormat: TextEdit.PlainText
                        persistentSelection: true
                        tabStopDistance: 40
                        leftPadding: Theme.spacingM
                        topPadding: Theme.spacingM
                        rightPadding: Theme.spacingM
                        bottomPadding: Theme.spacingM
                        
                        onTextChanged: {
                            if (text !== SessionData.notepadContent) {
                                SessionData.notepadContent = text
                                root.hasUnsavedChanges = true
                                saveTimer.restart()
                            }
                        }
                        
                        Keys.onEscapePressed: (event) => {
                            root.hide()
                            event.accepted = true
                        }

                        background: Rectangle {
                            color: "transparent"
                        }
                    }
                }
            }

            // Bottom controls
            Column {
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    width: parent.width
                    spacing: Theme.spacingL

                    Row {
                        spacing: Theme.spacingS
                        DankActionButton {
                            iconName: "save"
                            iconSize: Theme.iconSize - 2
                            iconColor: Theme.primary
                            hoverColor: Theme.primaryHover
                            enabled: root.hasUnsavedChanges || SessionData.notepadContent.length > 0
                            onClicked: {
                                root.fileDialogOpen = true
                                saveBrowser.open()
                            }
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Save")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                        }
                    }

                    Row {
                        spacing: Theme.spacingS
                        DankActionButton {
                            iconName: "folder_open"
                            iconSize: Theme.iconSize - 2
                            iconColor: Theme.secondary
                            hoverColor: Theme.secondaryHover
                            onClicked: {
                                root.fileDialogOpen = true
                                loadBrowser.open()
                            }
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Open")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                        }
                    }

                    Row {
                        spacing: Theme.spacingS
                        DankActionButton {
                            iconName: "note_add"
                            iconSize: Theme.iconSize - 2
                            iconColor: Theme.surfaceText
                            hoverColor: Theme.primaryHover
                            onClicked: {
                                SessionData.notepadContent = ""
                                root.currentFileName = ""
                                root.currentFileUrl = ""
                                root.hasUnsavedChanges = false
                                textArea.forceActiveFocus()
                            }
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("New")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingL

                    StyledText {
                        text: SessionData.notepadContent.length > 0 ? qsTr("%1 characters").arg(SessionData.notepadContent.length) : qsTr("Empty")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceTextMedium
                    }
                    
                    StyledText {
                        text: qsTr("Lines: %1").arg(textArea.lineCount)
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceTextMedium
                        visible: SessionData.notepadContent.length > 0
                    }

                    StyledText {
                        text: saveTimer.running ? qsTr("Auto-saving...") : (root.hasUnsavedChanges ? qsTr("Unsaved changes") : qsTr("Auto-saved"))
                        font.pixelSize: Theme.fontSizeSmall
                        color: root.hasUnsavedChanges ? Theme.warning : (saveTimer.running ? Theme.primary : Theme.surfaceTextMedium)
                        opacity: SessionData.notepadContent.length > 0 ? 1 : 0
                    }
                }
            }
        }
    }

    Timer {
        id: saveTimer
        interval: 1000
        repeat: false
        onTriggered: {
            SessionData.saveSettings()
            root.hasUnsavedChanges = false
        }
    }

    Timer {
        id: hideTimer
        interval: Theme.longDuration
        repeat: false
        onTriggered: {
            animatingOut = false
            currentFileName = ""
            currentFileUrl = ""
            hasUnsavedChanges = false
        }
    }

    // File save/load functionality
    function saveToFile(fileUrl) {
        const cleanPath = fileUrl.toString().replace(/^file:\/\//, '')
        
        saveProcess.command = ["sh", "-c", `echo ${JSON.stringify(SessionData.notepadContent)} > ${JSON.stringify(cleanPath)}`]
        saveProcess.running = true
    }
    
    function loadFromFile(fileUrl) {
        const cleanPath = fileUrl.toString().replace(/^file:\/\//, '')
        
        loadProcess.command = ["cat", cleanPath]
        loadProcess.running = true
    }

    Process {
        id: saveProcess
        
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.hasUnsavedChanges = false
            } else {
                console.warn("Notepad: Failed to save file, exit code:", exitCode)
            }
        }
    }

    Process {
        id: loadProcess
        
        stdout: StdioCollector {
            onStreamFinished: {
                SessionData.notepadContent = text
                root.hasUnsavedChanges = false
            }
        }
        
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                console.warn("Notepad: Failed to load file, exit code:", exitCode)
            }
        }
    }

    FileBrowserModal {
        id: saveBrowser

        browserTitle: qsTr("Save Notepad File")
        browserIcon: "save"
        browserType: "notepad_save"
        fileExtensions: ["*.txt", "*.md", "*.*"]
        allowStacking: true
        saveMode: true
        defaultFileName: "note.txt"
        
        onFileSelected: (path) => {
            root.fileDialogOpen = false
            const cleanPath = path.toString().replace(/^file:\/\//, '')
            const fileName = cleanPath.split('/').pop()
            const fileUrl = "file://" + cleanPath
            
            root.currentFileName = fileName
            root.currentFileUrl = fileUrl
            
            saveToFile(fileUrl)
            close()
        }
        
        onDialogClosed: {
            root.fileDialogOpen = false
        }
    }

    FileBrowserModal {
        id: loadBrowser

        browserTitle: qsTr("Open Notepad File")
        browserIcon: "folder_open"
        browserType: "notepad_load"
        fileExtensions: ["*.txt", "*.md", "*.*"]
        allowStacking: true
        
        onFileSelected: (path) => {
            root.fileDialogOpen = false
            const cleanPath = path.toString().replace(/^file:\/\//, '')
            const fileName = cleanPath.split('/').pop()
            const fileUrl = "file://" + cleanPath
            
            root.currentFileName = fileName
            root.currentFileUrl = fileUrl
            
            loadFromFile(fileUrl)
            close()
        }
        
        onDialogClosed: {
            root.fileDialogOpen = false
        }
    }
}