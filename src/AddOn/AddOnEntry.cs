using System;
using AlibreX;
using AddOnApi = global::AlibreAddOn;

// Alibre's loader for <DLL type="Managed"> looks for this class and these method names. Alibre's API docs
// don't describe this contract; Alibre's own Alibre Script add-on uses it. Don't rename them.
namespace AlibreAddOnAssembly
{
    public class AlibreAddOn
    {
        private static MyAddOn.AddOnInterface addOnInterface;

        public static void AddOnLoad(IntPtr hwnd, IAutomationHook automationHook, IntPtr reserved)
        {
            addOnInterface = new MyAddOn.AddOnInterface((IADRoot)automationHook.Root);
        }

        public static void AddOnInvoke(IntPtr hwnd, IntPtr automationHook, string sessionName, bool isLicensed, int reserved1, int reserved2)
        {
            // Commands arrive through IAlibreAddOn.InvokeCommand instead.
        }

        public static void AddOnUnload(IntPtr hwnd, bool forceUnload, ref bool cancel, int reserved1, int reserved2)
        {
            cancel = false;
        }

        public static AddOnApi.IAlibreAddOn GetAddOnInterface()
        {
            return addOnInterface;
        }
    }
}
