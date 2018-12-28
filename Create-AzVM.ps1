#requires -Modules Az

if( -not $(Get-AzContext) ) {  return }
Get-Date