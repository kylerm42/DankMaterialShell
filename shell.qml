//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Common
import qs.Modals
import qs.Modals.Clipboard
import qs.Modals.Common
import qs.Modals.Settings
import qs.Modals.Spotlight
import qs.Modules
import qs.Modules.AppDrawer
import qs.Modules.DankDash
import qs.Modules.ControlCenter
import qs.Modules.Dock
import qs.Modules.Lock
import qs.Modules.Notifications.Center
import qs.Modules.Notifications.Popup
import qs.Modules.OSD
import qs.Modules.ProcessList
import qs.Modules.Settings
import qs.Modules.TopBar
import qs.Services

ShellRoot {
    id: root

    Component.onCompleted: {
        PortalService.init()
        // Initialize DisplayService night mode functionality
        DisplayService.nightModeEnabled
    }

    function executePowerAction(action) {
        switch (action) {
        case "logout":
            SessionService.logout()
            break
        case "suspend":
            SessionService.suspend()
            break
        case "reboot":
            SessionService.reboot()
            break
        case "poweroff":
            SessionService.poweroff()
            break
        }
    }

    WallpaperBackground {}

    Lock {
        id: lock

        anchors.fill: parent
    }

    Variants {
        model: SettingsData.getFilteredScreens("topBar")

        delegate: TopBar {
            modelData: item
            notepadVariants: notepadSlideoutVariants
        }
    }

    Variants {
        model: SettingsData.getFilteredScreens("dock")

        delegate: Dock {
            modelData: item
            contextMenu: dockContextMenuLoader.item ? dockContextMenuLoader.item : null
            Component.onCompleted: {
                dockContextMenuLoader.active = true
            }
        }
    }

    Loader {
        id: dankDashPopoutLoader

        active: false
        asynchronous: true

        sourceComponent: Component {
            DankDashPopout {
                id: dankDashPopout
            }
        }
    }

    LazyLoader {
        id: dockContextMenuLoader

        active: false

        DockContextMenu {
            id: dockContextMenu
        }
    }

    LazyLoader {
        id: notificationCenterLoader

        active: false

        NotificationCenterPopout {
            id: notificationCenter
        }
    }

    Variants {
        model: SettingsData.getFilteredScreens("notifications")

        delegate: NotificationPopupManager {
            modelData: item
        }
    }

    LazyLoader {
        id: controlCenterLoader

        active: false

        ControlCenterPopout {
            id: controlCenterPopout

            onPowerActionRequested: (action, title, message) => {
                                        if (SettingsData.skipPowerConfirmation) {
                                            root.executePowerAction(action)
                                        } else {
                                            powerConfirmModalLoader.active = true
                                            if (powerConfirmModalLoader.item) {
                                                powerConfirmModalLoader.item.confirmButtonColor = action === "poweroff" ? Theme.error : action === "reboot" ? Theme.warning : Theme.primary
                                                powerConfirmModalLoader.item.show(title, message, function () {
                                                    root.executePowerAction(action)
                                                }, function () {})
                                            }
                                        }
                                    }
            onLockRequested: {
                lock.activate()
            }
        }
    }

    LazyLoader {
        id: wifiPasswordModalLoader

        active: false

        WifiPasswordModal {
            id: wifiPasswordModal
        }
    }

    LazyLoader {
        id: networkInfoModalLoader

        active: false

        NetworkInfoModal {
            id: networkInfoModal
        }
    }

    LazyLoader {
        id: batteryPopoutLoader

        active: false

        BatteryPopout {
            id: batteryPopout
        }
    }

    LazyLoader {
        id: vpnPopoutLoader

        active: false

        VpnPopout {
            id: vpnPopout
        }
    }

    LazyLoader {
        id: powerMenuLoader

        active: false

        PowerMenu {
            id: powerMenu

            onPowerActionRequested: (action, title, message) => {
                                        if (SettingsData.skipPowerConfirmation) {
                                            root.executePowerAction(action)
                                        } else {
                                            powerConfirmModalLoader.active = true
                                            if (powerConfirmModalLoader.item) {
                                                powerConfirmModalLoader.item.confirmButtonColor = action === "poweroff" ? Theme.error : action === "reboot" ? Theme.warning : Theme.primary
                                                powerConfirmModalLoader.item.show(title, message, function () {
                                                    root.executePowerAction(action)
                                                }, function () {})
                                            }
                                        }
                                    }
        }
    }

    LazyLoader {
        id: powerConfirmModalLoader

        active: false

        ConfirmModal {
            id: powerConfirmModal
        }
    }

    LazyLoader {
        id: processListPopoutLoader

        active: false

        ProcessListPopout {
            id: processListPopout
        }
    }

    SettingsModal {
        id: settingsModal
    }

    LazyLoader {
        id: appDrawerLoader

        active: false

        AppDrawerPopout {
            id: appDrawerPopout
        }
    }

    // Pre-load AppDrawer after a short delay to reduce IPC response time
    Timer {
        interval: 500  // Wait 0.5 seconds after startup
        running: true
        repeat: false
        onTriggered: {
            if (!appDrawerLoader.active) {
                appDrawerLoader.active = true
            }
        }
    }

    IpcHandler {
        target: "appdrawer"

        function show(): string {
            appDrawerLoader.active = true
            if (appDrawerLoader.item) {
                appDrawerLoader.item.centerWhenCalledViaIpc = true
                appDrawerLoader.item.show()
            }
            return "APPDRAWER_SHOW_SUCCESS"
        }

        function hide(): string {
            if (appDrawerLoader.item) {
                appDrawerLoader.item.close()
            }
            return "APPDRAWER_HIDE_SUCCESS"
        }

        function toggle(): string {
            if (appDrawerLoader.item) {
                appDrawerLoader.item.centerWhenCalledViaIpc = true
                // Use the same immediate call pattern as the widget
                appDrawerLoader.item.shouldBeVisible ? appDrawerLoader.item.close() : appDrawerLoader.item.open()
            }
            return "APPDRAWER_TOGGLE_SUCCESS"
        }
    }

    SpotlightModal {
        id: spotlightModal
    }

    ClipboardHistoryModal {
        id: clipboardHistoryModalPopup
    }

    NotificationModal {
        id: notificationModal
    }

    LazyLoader {
        id: processListModalLoader

        active: false

        ProcessListModal {
            id: processListModal
        }
    }

    Variants {
        id: notepadSlideoutVariants
        model: SettingsData.getFilteredScreens("notepad")

        delegate: Loader {
            id: notepadLoader
            property var modelData: item
            active: false
            
            sourceComponent: Component {
                NotepadSlideout {
                    id: notepadSlideout
                    modelData: notepadLoader.modelData
                    
                    Component.onCompleted: {
                        notepadLoader.loaded = true
                    }
                }
            }
            
            property bool loaded: false
            
            function ensureLoaded() {
                if (!active) {
                    active = true
                }
                return item
            }
        }
    }

    LazyLoader {
        id: powerMenuModalLoader

        active: false

        PowerMenuModal {
            id: powerMenuModal

            onPowerActionRequested: (action, title, message) => {
                                        if (SettingsData.skipPowerConfirmation) {
                                            root.executePowerAction(action)
                                        } else {
                                            powerConfirmModalLoader.active = true
                                            if (powerConfirmModalLoader.item) {
                                                powerConfirmModalLoader.item.confirmButtonColor = action === "poweroff" ? Theme.error : action === "reboot" ? Theme.warning : Theme.primary
                                                powerConfirmModalLoader.item.show(title, message, function () {
                                                    root.executePowerAction(action)
                                                }, function () {})
                                            }
                                        }
                                    }
        }
    }

    IpcHandler {
        function open() {
            powerMenuModalLoader.active = true
            if (powerMenuModalLoader.item)
                powerMenuModalLoader.item.open()

            return "POWERMENU_OPEN_SUCCESS"
        }

        function close() {
            if (powerMenuModalLoader.item)
                powerMenuModalLoader.item.close()

            return "POWERMENU_CLOSE_SUCCESS"
        }

        function toggle() {
            powerMenuModalLoader.active = true
            if (powerMenuModalLoader.item)
                powerMenuModalLoader.item.toggle()

            return "POWERMENU_TOGGLE_SUCCESS"
        }

        target: "powermenu"
    }

    IpcHandler {
        function open(): string {
            processListModalLoader.active = true
            if (processListModalLoader.item)
                processListModalLoader.item.show()

            return "PROCESSLIST_OPEN_SUCCESS"
        }

        function close(): string {
            if (processListModalLoader.item)
                processListModalLoader.item.hide()

            return "PROCESSLIST_CLOSE_SUCCESS"
        }

        function toggle(): string {
            processListModalLoader.active = true
            if (processListModalLoader.item)
                processListModalLoader.item.toggle()

            return "PROCESSLIST_TOGGLE_SUCCESS"
        }

        target: "processlist"
    }

    IpcHandler {
        function open(tab: string): string {
            dankDashPopoutLoader.active = true
            if (dankDashPopoutLoader.item) {
                switch (tab.toLowerCase()) {
                case "media":
                    dankDashPopoutLoader.item.currentTabIndex = 1
                    break
                case "weather":
                    dankDashPopoutLoader.item.currentTabIndex = SettingsData.weatherEnabled ? 2 : 0
                    break
                default:
                    dankDashPopoutLoader.item.currentTabIndex = 0
                    break
                }
                dankDashPopoutLoader.item.setTriggerPosition(Screen.width / 2, Theme.barHeight + Theme.spacingS, 100, "center", Screen)
                dankDashPopoutLoader.item.dashVisible = true
                return "DASH_OPEN_SUCCESS"
            }
            return "DASH_OPEN_FAILED"
        }

        function close(): string {
            if (dankDashPopoutLoader.item) {
                dankDashPopoutLoader.item.dashVisible = false
                return "DASH_CLOSE_SUCCESS"
            }
            return "DASH_CLOSE_FAILED"
        }

        function toggle(tab: string): string {
            dankDashPopoutLoader.active = true
            if (dankDashPopoutLoader.item) {
                if (dankDashPopoutLoader.item.dashVisible) {
                    dankDashPopoutLoader.item.dashVisible = false
                } else {
                    switch (tab.toLowerCase()) {
                    case "media":
                        dankDashPopoutLoader.item.currentTabIndex = 1
                        break
                    case "weather":
                        dankDashPopoutLoader.item.currentTabIndex = SettingsData.weatherEnabled ? 2 : 0
                        break
                    default:
                        dankDashPopoutLoader.item.currentTabIndex = 0
                        break
                    }
                    dankDashPopoutLoader.item.setTriggerPosition(Screen.width / 2, Theme.barHeight + Theme.spacingS, 100, "center", Screen)
                    dankDashPopoutLoader.item.dashVisible = true
                }
                return "DASH_TOGGLE_SUCCESS"
            }
            return "DASH_TOGGLE_FAILED"
        }

        target: "dash"
    }

    IpcHandler {
        function getFocusedScreenName() {
            if (CompositorService.isHyprland && Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.monitor) {
                return Hyprland.focusedWorkspace.monitor.name
            }
            if (CompositorService.isNiri && NiriService.currentOutput) {
                return NiriService.currentOutput
            }
            return ""
        }

        function getNotepadInstanceForScreen(screenName: string) {
            if (!screenName || notepadSlideoutVariants.instances.length === 0) {
                return
            }
            
            for (var i = 0; i < notepadSlideoutVariants.instances.length; i++) {
                var loader = notepadSlideoutVariants.instances[i]
                if (loader.modelData && loader.modelData.name === screenName) {
                    loader.ensureLoaded()
                    return
                }
            }
        }

        function getActiveNotepadInstance() {
            if (notepadSlideoutVariants.instances.length === 0) {
                return null
            }
            
            if (notepadSlideoutVariants.instances.length === 1) {
                return notepadSlideoutVariants.instances[0].ensureLoaded()
            }
            
            var focusedScreen = getFocusedScreenName()
            if (focusedScreen) {
                var focusedInstance = getNotepadInstanceForScreen(focusedScreen)
                if (focusedInstance) {
                    return focusedInstance
                }
            }
            
            for (var i = 0; i < notepadSlideoutVariants.instances.length; i++) {
                var loader = notepadSlideoutVariants.instances[i]
                if (loader.active && loader.item && loader.item.notepadVisible) {
                    return loader.item
                }
            }
            
            return notepadSlideoutVariants.instances[0].ensureLoaded()
        }

        function open(): string {
            var instance = getActiveNotepadInstance()
            if (instance) {
                instance.show()
                return "NOTEPAD_OPEN_SUCCESS"
            }
            return "NOTEPAD_OPEN_FAILED"
        }

        function close(): string {
            var instance = getActiveNotepadInstance()
            if (instance) {
                instance.hide()
                return "NOTEPAD_CLOSE_SUCCESS"
            }
            return "NOTEPAD_CLOSE_FAILED"
        }

        function toggle(): string {
            var instance = getActiveNotepadInstance()
            if (instance) {
                instance.toggle()
                return "NOTEPAD_TOGGLE_SUCCESS"
            }
            return "NOTEPAD_TOGGLE_FAILED"
        }

        target: "notepad"
    }

    Variants {
        model: SettingsData.getFilteredScreens("toast")

        delegate: Toast {
            modelData: item
            visible: ToastService.toastVisible
        }
    }

    Variants {
        model: SettingsData.getFilteredScreens("osd")

        delegate: VolumeOSD {
            modelData: item
        }
    }

    Variants {
        model: SettingsData.getFilteredScreens("osd")

        delegate: MicMuteOSD {
            modelData: item
        }
    }

    Variants {
        model: SettingsData.getFilteredScreens("osd")

        delegate: BrightnessOSD {
            modelData: item
        }
    }

    Variants {
        model: SettingsData.getFilteredScreens("osd")

        delegate: IdleInhibitorOSD {
            modelData: item
        }
    }
}
