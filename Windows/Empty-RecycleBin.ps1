Function Empty-RecycleBin
{
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(Mandatory=$false)]
        [switch] $Force     # Without confirmation
    )
    if($IsWindows -eq $false) { return } # Exit the script if the OS is other than Windows

    # Since the Crear-RecycleBin CmdLet is not availble on PowerShell Core,
    # achive the same functionality using the .Net Classes.
    $Type = @'
    using System;
    using System.Runtime.InteropServices;

    namespace MyComputer
    {
        public static class RecycleBin
        {
            [DllImport("Shell32.dll", CharSet = CharSet.Unicode)]
            static extern uint SHEmptyRecycleBin(IntPtr hwnd, string pszRootPath, int dwFlags);

            public static void Empty()
            {
                SHEmptyRecycleBin(IntPtr.Zero, null, 1);
            }
        }
    }
'@
    Add-Type -TypeDefinition $Type

    # Bypass confirmation, and empty the recyclebin
    if ($PSBoundParameters.ContainsKey('Force'))
    {
        [MyComputer.RecycleBin]::Empty()
        return
    }

    # Default behaviour, with confirmation empty the recyclebin
    if($PSCmdlet.ShouldProcess('All of the contents of the Recycle Bin','Empty-RecycleBin')){  
        [MyComputer.RecycleBin]::Empty()
        return
    }
}