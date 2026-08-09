$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent
$source = Join-Path $projectRoot "image\answer-files"
$outputDirectory = Join-Path $projectRoot "build"
$output = Join-Path $outputDirectory "answer-files.iso"
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

if (-not ("ImapiStreamWriter" -as [type])) {
  Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;

public static class ImapiStreamWriter
{
    public static void Write(object source, string outputPath, int blockSize, int totalBlocks)
    {
        IntPtr unknown = Marshal.GetIUnknownForObject(source);
        try
        {
            IStream stream = (IStream)Marshal.GetTypedObjectForIUnknown(unknown, typeof(IStream));
            byte[] buffer = new byte[blockSize];
            using (FileStream file = new FileStream(outputPath, FileMode.Create, FileAccess.Write))
            {
                for (int block = 0; block < totalBlocks; block++)
                {
                    stream.Read(buffer, blockSize, IntPtr.Zero);
                    file.Write(buffer, 0, blockSize);
                }
            }
        }
        finally
        {
            Marshal.Release(unknown);
        }
    }
}
"@
}

$fileSystemImage = New-Object -ComObject IMAPI2FS.MsftFileSystemImage
$fileSystemImage.FileSystemsToCreate = 3
$fileSystemImage.Root.AddTree($source, $false)
$result = $fileSystemImage.CreateResultImage()
[ImapiStreamWriter]::Write($result.ImageStream, $output, $result.BlockSize, $result.TotalBlocks)

Write-Host "Created answer ISO: $output"
