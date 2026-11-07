// A placeholder for the add-on's DLL with the same entry point names and no Alibre references. It does
// nothing and can't run in Alibre. Pull requests from forks can't get Alibre's files, so CI compiles this
// for them to test the installer. Released installers always contain the real add-on.
namespace AlibreAddOnAssembly
{
    public class AlibreAddOn
    {
        public static void AddOnLoad() { }
        public static void AddOnInvoke() { }
        public static void AddOnUnload() { }
        public static object GetAddOnInterface() { return null; }
    }
}
