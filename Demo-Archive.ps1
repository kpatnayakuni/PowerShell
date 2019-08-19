### Examples are from Microsoft Docs
## Zip the files 

# Example 1: Create an archive file
Compress-Archive -LiteralPath C:\Reference\Draftdoc.docx, C:\Reference\Images\diagram2.vsd -CompressionLevel Optimal -DestinationPath C:\Archives\Draft.Zip

# Example 2: Create an archive with wildcard characters
Compress-Archive -Path C:\Reference\* -CompressionLevel Fastest -DestinationPath C:\Archives\Draft

# Example 3: Update an existing archive file
Compress-Archive -Path C:\Reference\* -Update -DestinationPath C:\Archives\Draft.Zip

# Example 4: Create an archive from an entire folder
Compress-Archive -Path C:\Reference -DestinationPath C:\Archives\Draft

## Unzip the file 

# Example 1: Extract the contents of an archive
Expand-Archive -LiteralPath C:\Archives\Draft.Zip -DestinationPath C:\Reference

#Example 2: Extract the contents of an archive in the current folder
Expand-Archive -Path Draft.Zip -DestinationPath C:\Reference