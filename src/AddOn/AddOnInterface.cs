using System;
using System.IO;
using System.Reflection;
using System.Windows.Forms;
using AlibreAddOn;
using AlibreX;

namespace MyAddOn
{
    /// <summary>
    /// Puts one button in Alibre's ribbon, on the Add-ons tab. Clicking it opens a welcome window.
    /// Replace ShowWelcome with what your add-on does.
    /// </summary>
    public sealed class AddOnInterface : IAlibreAddOn
    {
        private const int RootMenuId = 1;
        private const int ButtonMenuId = 2;

        // The oldest Alibre build this add-on supports. Alibre loads an add-on into every installed version.
        private const int MinimumBuild = 28000;

        // FriendlyName from project.psd1, which the build stores as the DLL's title.
        private static readonly string FriendlyName =
            ((AssemblyTitleAttribute)Attribute.GetCustomAttribute(Assembly.GetExecutingAssembly(), typeof(AssemblyTitleAttribute))).Title;

        private readonly bool isVersionSupported;

        public AddOnInterface(IADRoot root)
        {
            isVersionSupported = CheckVersion(root.Version);
        }

        // IADRoot.Version ends with the build number after its last separator.
        private static bool CheckVersion(string version)
        {
            string[] parts = (version ?? string.Empty).Split(new[] { ',', '.', ' ' }, StringSplitOptions.RemoveEmptyEntries);
            int build;
            return parts.Length == 0 || !int.TryParse(parts[parts.Length - 1], out build) || build >= MinimumBuild;
        }

        public int RootMenuItem => RootMenuId;

        public bool HasSubMenus(int menuId) => menuId == RootMenuId;

        public Array SubMenuItems(int menuId) => menuId == RootMenuId ? new[] { ButtonMenuId } : null;

        public string MenuItemText(int menuId)
        {
            switch (menuId)
            {
                case RootMenuId: return FriendlyName;
                case ButtonMenuId: return "Say Hello";
                default: return null;
            }
        }

        public bool PopupMenu(int menuId) => false;

        // The root item must be enabled too, or the whole menu is greyed out.
        public ADDONMenuStates MenuItemState(int menuId, string sessionIdentifier)
        {
            return menuId == RootMenuId || isVersionSupported
                ? ADDONMenuStates.ADDON_MENU_ENABLED
                : ADDONMenuStates.ADDON_MENU_GRAYED;
        }

        public string MenuItemToolTip(int menuId)
        {
            if (menuId != ButtonMenuId)
            {
                return null;
            }
            return isVersionSupported
                ? "Opens a welcome window"
                : "Requires Alibre Design build " + MinimumBuild + " or later";
        }

        // Returning null means the command is finished, so there's no command object to manage.
        public IAlibreAddOnCommand InvokeCommand(int menuId, string sessionIdentifier)
        {
            if (menuId == ButtonMenuId)
            {
                ShowWelcome();
            }
            return null;
        }

        private static void ShowWelcome()
        {
            MessageBox.Show("Welcome to the dummy add-on!", FriendlyName, MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        // Found from this DLL's own folder, because the working directory is Alibre's.
        public string MenuIcon(int menuId)
        {
            string dll = Assembly.GetExecutingAssembly().Location;
            return Path.ChangeExtension(dll, ".ico");
        }

        public bool UseDedicatedRibbonTab() => false;

        public bool HasPersistentDataToSave(string sessionIdentifier) => false;

        public void LoadData(IStream pCustomData, string sessionIdentifier)
        {
        }

        public void SaveData(IStream pCustomData, string sessionIdentifier)
        {
        }

        public void setIsAddOnLicensed(bool isLicensed)
        {
        }
    }
}
