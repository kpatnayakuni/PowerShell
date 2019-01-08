Function Empty-RecycleBin
{
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(Mandatory=$false)]
        [switch] $Force
    )
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
    if ($PSBoundParameters.ContainsKey('Force'))
    {
        [MyComputer.RecycleBin]::Empty()
        return
    }

    if($PSCmdlet.ShouldProcess('All of the contents of the Recycle Bin','Empty-RecycleBin')){  
        [MyComputer.RecycleBin]::Empty()
        return
    }
}