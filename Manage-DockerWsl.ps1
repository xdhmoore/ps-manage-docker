
$DOCKER_DESKTOP_EXE="C:\Program Files\Docker\Docker\Docker Desktop.exe"
$WSL_SWAP_FILE="${env:TMP}/wsl2_swap.vhdx"

# This is not included in the git repo for now because it has a ton of unnecessary
# stuff in it. This only affects the Start-WatchSwapWidget function.
$CONEMU_CONFIG="$PSScriptRoot\watch_swap_conemu.xml"

Function Stop-Docker() {
   [CmdletBinding()]

   param([switch]$Wait=$False)

   # If ahk script runs and it's stopped, ahk script sends an unneeded {Enter}
   if((Get-DockerStatus) -ne "stopped") {
      Write-Debug "Stopping Docker..."
      & $PSScriptRoot\stop-docker.ahk

      if($Wait) {
         while((Get-DockerStatus) -ne "stopped") {
            Sleep 2;
         }
      }
   }
}

# Also stops Docker
Function Stop-Wsl() {
   [CmdletBinding()]
   param([switch]$Wait=$False)

   Write-Debug "Stopping Wsl..."
   Stop-Docker -Wait
   wsl --shutdown
   if($Wait) {
      while(Test-WslRunning) {
         Sleep 2;
      }
   }
}

# Also starts WSL2
Function Start-Docker() {
   [CmdletBinding()]
   param([switch]$Wait=$False)

   Write-Debug "Starting Docker..."
   & $DOCKER_DESKTOP_EXE
   if($Wait) {
      while((Get-DockerStatus) -ne "running") {
         Sleep 2;
      }
   }
}

Function Start-Wsl() {
   [CmdletBinding()]
   param([switch]$Wait=$False)

   Write-Debug "Starting Wsl..."
   wsl exit
   if($Wait) {
      while(!(Test-WslRunning)) {
         Sleep 2;
      }
   }
}

#Running, Stopped, Unknown
Function Get-DockerStatus() {
   [CmdletBinding()]
   param()

   Write-Debug "Checking for running docker processes..."
   # Are all the processes running, including Docker Desktop?
   $procs = @(
      Get-Process '*docker*' | select -expandproperty ProcessName | sort -Unique |
         ? { $_ -notmatch 'com.docker.service' }
   )

   Write-Debug "Found $($procs.length): $procs"

   # TODO comparing against an exact list like this is brittle. There must be
   # a better way
   if(Compare-Arrays $procs (
            'com.docker.backend',
            'com.docker.proxy',
            'com.docker.wsl-distro-proxy',
            'docker',
            'Docker Desktop'
         )) {
      #Maybe running
      Write-Debug "Might be running. Checking docker sytem info"

      if(Test-DockerInfo) {
         return "running"
      } else {
         return "unknown"
      }
   } elseif (($procs.length -eq 0) -or (($procs.length -eq 1) -and ($procs -eq "Docker Desktop"))) {
      #Maybe stopped
      Write-Debug "Might be stopped. Checking docker sytem info"
      if(!(Test-DockerInfo)) {
         return "stopped"
      } else {
         Write-Error "No docker processes, yet no docker error. This shouldn't be possible."
         return "unknown"
      }

   } else {
      return "unknown"
   }
}

Function Test-DockerInfo() {
   $ErrorActionPreference="Continue"
   (docker system info 2>$null | sls ERROR).length -eq 0
}

Function Test-WslRunning() {
   # NOTE uses of wsl depend on my encoding wrapper
   (wsl --list --verbose | sls Running).Length -gt 0
}

Function Get-WslSwapLoc() {
   # TODO parse .wslconf?
   # TODO what if tmp is different?
   return $WSL_SWAP_FILE
}

Function Get-WslMaxSwapSize() {
   # TODO what if .wslconfig doesn't exist or doesn't have an explicit swap size set
   $swapSetting=((Get-Content "~\.wslconfig" | sls '^swap *= *') -replace '^[^=]*= *(.*) *$','$1').Trim()
   if ($swapSetting -notmatch '^.*GB$') {
      Write-Error "Setting doesnt use GB units and I dont know how to convert anything else"
   }
   # GiB to bytes
   # Apparently, there's no powershell exponent operator?
   [int]($swapSetting -replace 'GB','') * 1024 * 1024 * 1024
}

Function Start-WatchSwapWidget() {

   # This uses a custom conemu config to display the 'Watch-Swap'
   # function output in its own tiny window as a sort of hacky widget
   & "$ConEmu" `
      -NoUpdate `
      -LoadCfgFile $CONEMU_CONFIG `
      -runlist pwsh -nol -c Watch-Swap
      # Debugging: add -noe to not exit when we're done
}


Function Watch-Swap() {
   $swapFile = Get-WslSwapLoc
   Write-Host 'Loading swap info...'

   While($true) {

      $swap = Get-Size $swapFile
      Clear-Host
      # TODO see if you can reimplement this differently without this swapsize flag, can you cache the output somehow
      # and retain the coloring?
      Show-Swap -SwapSize $swap
      Sleep 10
   }
}

# TODO another meter for memory information would be useful. maybe:
# main system swap file?
# --------- WSL 2 ON ---------------------
#  other mem used      vmmem used
# [|||||||||||||||IIIIIIIIIIIIIIIIII                   ]

# like 'top' for a single file
# or Watch-Swap
# TODO add -Watch flag?
Function Show-Swap($SwapSize) {
   if ($SwapSize) {
      $currSwap = $SwapSize
      #$currSwap=(16106127360 * 1.2)
   } else {
      $currSwap = Get-Size (Get-WslSwapLoc)
   }
   # TODO - based on wslconf or hard-coded, build/display bar of how much it is using of calculated max, including over-the-max
   # Also display text values
   # Refresh every 30s? Show countdown till refresh and blinking "Refreshing..." during refresh?
   # -Watch flag


   $maxSwap=Get-WslMaxSwapSize
   $width=50

   # Cases:

   # $currSwap -le $maxSwap
   # [ooooooooooo         ]

   # $currSwap -gt $maxSwap
   # [oooooooooooooo||||||]

   # $currSwap == 0
   # [                    ]

   if ($currSwap -le $maxSwap) {
      $swapWidth=$width * $currSwap/$maxSwap
      $overWidth=0
   } else {
      $swapWidth=$width * $maxSwap/$currSwap
      $overWidth=$width * ($currSwap - $maxSwap) / $currSwap
   }

   # TODO:
   # WSL2 Swap File:                         9.1/15 GiB
   # [||||||||||||||||||||||||||||||||                ]
   $title = "WSL2 Swap:"
   $displayCurrSwap = '{0:0.#}' -f ($currSwap / (1024 * 1024 * 1024))
   $displayMaxSwap = '/{0:0.#} GiB' -f ($maxSwap / (1024 * 1024 * 1024))
   $padding = ' ' * (2 + $width - ($title.length + $displayCurrSwap.length + $displayMaxSwap.length))
   Write-Host -NoNewLine ($title + $padding)
   Write-Host -NoNewLine -ForegroundColor ($currSwap -le $maxSwap ? 'Green' : 'Red') $displayCurrSwap
   Write-Host $displayMaxSwap

   Write-Host -NoNewline "["
   Write-Host -ForegroundColor Green -NoNewline ("|" * $swapWidth)
   Write-Host -ForegroundColor Red -NoNewline ("|" * $overWidth)
   Write-Host -NoNewline (" " * ($width - $overWidth - $swapWidth))
   Write-Host "]"
}

Function Restart-Docker() {
   [CmdletBinding()]

   param(
      [switch]$Wait=$False,
      [switch]$Wsl=$False
   )

   # TODO could put this in an async job instead. Then wouldn't have to always
   # wait for stop
   if ($Wsl) {
      Stop-Wsl -Wait
   } else {
      Stop-Docker -Wait
   }

   if ($Wait) {
      Start-Docker -Wait
   } else {
      Start-Docker
   }
}

Function Restart-Wsl {
   [CmdletBinding()]

   param([switch]$Wait=$False)

   # TODO could put this in an async job instead. Then wouldn't have to always
   # wait for stop
   Stop-Wsl -Wait

   if ($Wait) {
      Start-Wsl -Wait
   } else {
      Start-Wsl
   }
}

Function Get-MaxMemory($Unit) {

   $mem = Get-CimInstance -Class CIM_PhysicalMemory | Select-Object -ExpandProperty Capacity
   switch($Unit) {
      "GiB" {
         return $mem / 1024 / 1024 / 1024
      }
      "" {
         return $mem
      }
      default {
         Write-Error "Unknown unit type: $Unit"
      }
   }
}
<#

#Get-CimInstance -Class CIM_PhysicalMemory -ComputerName localhost -ErrorAction Stop | Select-Object *
#Get-CIMInstance Win32_OperatingSystem | Select FreePhysicalMemory,TotalVisibleMemory

[virtual memory of other apps | memory of vmmem | free virtual memory]
|---------------total virtual memory---------------------------------|


[used physical memory | swap space | free space ]
[-----total virtual memory ---------------------]


#>
