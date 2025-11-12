oh-my-posh --init --shell pwsh --config C:\Users\peter\OneDrive\DevEnv\PowerShell\myParadox.omp.json | Invoke-Expression
#oh-my-posh --init --shell pwsh --config C:\Users\peter\OneDrive\DevEnv\PowerShell\jandedobbeleer.omp.json | Invoke-Expression

set-alias d docker
set-alias dc docker-compose

Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Key Shift+Tab -Function TabCompleteNext

$null = Register-EngineEvent -SourceIdentifier 'PowerShell.OnIdle' -MaxTriggerCount 1 -Action {
    Import-Module -Name Terminal-Icons
    Import-Module posh-git

    Set-PSReadLineKeyHandler -Key Ctrl+B `
        -BriefDescription DotnetBuildCurrentDirectory `
        -LongDescription "Build the current directory" `
        -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet build")
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }

    Set-PSReadLineKeyHandler -Key Ctrl+T `
        -BriefDescription DotnetTestCurrentDirectory `
        -LongDescription "Test the current directory" `
        -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet test")
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }

    Set-PSReadLineKeyHandler -Key Ctrl+R `
        -BriefDescription DotnetRunCurrentDirectory `
        -LongDescription "dotnet run" `
        -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("dotnet run")
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }

    Set-PSReadLineKeyHandler -Key Ctrl+G `
        -BriefDescription OpenGitExtensions `
        -LongDescription "Open GitExtensions in the current directory" `
        -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("gitextensions openrepo")
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }

    Set-PSReadLineKeyHandler -Key Ctrl+DownArrow `
        -BriefDescription CheckoutMain `
        -LongDescription "Checkout the main/master branch" `
        -ScriptBlock {
        $allBranches = @(git branch --list)
        $allowedBranches = @('main', 'master')
        $branch = $allBranches | Select-String -Pattern $allowedBranches -SimpleMatch
        $command = "git checkout " + $branch.ToString().Trim('*', ' ')

        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert(" | git pull")
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }

    Set-PSReadLineKeyHandler -Key Ctrl+Shift+C `
        -BriefDescription StartVisualStudioCode `
        -LongDescription "Start Visual Studio Code" `
        -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("code .")
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }

    Set-PSReadLineKeyHandler -Key Ctrl+Shift+DownArrow `
        -BriefDescription GitPull `
        -LongDescription "Git pull" `
        -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("git pull")
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }

    # dotnet auto completion
    dotnet completions script pwsh | out-String | Invoke-Expression -ErrorAction SilentlyContinue

    # Winget
    ## auto completion
    Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    Register-ArgumentCompleter -Native -CommandName npm -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        $Local:ast = $commandAst.ToString().Replace(' ', '')
        if ($Local:ast -eq 'npm') {
            $command = 'run install start outdated'
            $array = $command.Split(' ')
            $array | 
            Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object {
                New-Object -Type System.Management.Automation.CompletionResult -ArgumentList $_
            }
        }
        if ($Local:ast -eq 'npmrun') {
            $scripts = (Get-Content .\package.json | ConvertFrom-Json).scripts
            $scripts |
            Get-Member -MemberType NoteProperty |
            Where-Object { $_.Name -like "$wordToComplete*" } |
            ForEach-Object {
                New-Object -Type System.Management.Automation.CompletionResult -ArgumentList $_.Name
            }
        }
    }

}