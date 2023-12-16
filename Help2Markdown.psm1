<#
    .SYNOPSIS
    Convert commend based Help in the module to Markdown documents
#>
using namespace System.Text;
using namespace System.Collections;
using namespace System.Collections.ObjectModel;
using namespace System.Collections.Generic;
using namespace System.Management.Automation;

$ErrorActionPreference = "Stop";
function SplitLines([string] $str) {
    return $str.Trim().Replace("`r`n", "`n").Replace("`r", "`n") -Split "`n"
}

class HelpGenerator {
    [CommandInfo] $CmdInfo
    [PSCustomObject] $Help

    #
    # Constructor
    #
    HelpGenerator($cmd) {
        $this.CmdInfo = $cmd
        $this.Help = Get-help -Full $cmd.Name
        $this.ParseSynopsis()
        $this.ParseDescription()
        $this.ParseParameterSets()
        $this.ParseParameterDetails()
        $this.ParseInputTypes()
        $this.ParseOutputs()
        $this.ParseExamples()
    }

    [string] GenerateMarkdown() {
        $name = $this.Help.Name
        $sb = [StringBuilder]::new();
        $sb.AppendLine(("# {0}" -f $name))
        $sb.AppendLine()

        if ($this.Synopsis) {
            foreach ($line in $this.Synopsis) {
                $sb.AppendLine($line)
            }
            $sb.AppendLine()
        }

        if ($this.Description) {
            $sb.AppendLine("## Description")
            foreach ($line in $this.Description) {
                $sb.AppendLine($line)
            }
            $sb.AppendLine()
        }

        $index = 1;
        if ($this.ParameterSets.Count -gt 0) {
            $sb.AppendLine("## Syntax")
            $sb.AppendLine()
            foreach ($parameterSet in $this.ParameterSets) {
                if ($parameterSet.Name -eq "__AllParameterSets") {
                    $sb.Append((" {0,2:d}. {1}" -f $index++, $name))
                } else {
                    $sb.AppendLine((" {0,2:d}. ({1})  " -f $index++, $parameterSet.Name))
                    $sb.Append(("     {0}" -f $name))
                }
                foreach ($param in $parameterSet.GetMarkdownList($true)) {
                    $sb.AppendFormat(" {0}", $param)
                }
                $sb.AppendLine()
            }
            $sb.AppendLine()
        }

        if ($this.ParameterDetails.Count -gt 0) {
            $sb.AppendLine("## Parameters")
            $sb.AppendLine()
            foreach ($detail in $this.ParameterDetails) {
                $sb.AppendLine(('### Parameter`-{0}`' -f $detail.Name))
                $sb.AppendLine()
                if ($detail.Description) {
                    foreach ($line in $detail.Description) { $sb.AppendLine($line) }
                    $sb.AppendLine()
                }
                $sb.Append($detail.ToMarkdownTable())
                $sb.Append($detail.ToMarkdownTable2())
                $sb.AppendLine()

            }
            $sb.AppendLine()
        }

        if ($this.InputTypes) {
            $sb.AppendLine("## Pipeline Inputs")
            $sb.AppendLine()
            foreach ($line in $this.InputTypes) {
                $sb.AppendLine((' - `{0}`' -f $line))
            }
            $sb.AppendLine()
        }
        if ($this.OutputTypes) {
            $sb.AppendLine("## Outputs")
            $sb.AppendLine()
            foreach ($line in $this.OutputTypes) {
                $sb.AppendLine((' - `{0}`' -f $line))
            }
            $sb.AppendLine()
        }
        $index = 1
        if ($this.Examples.Count -gt 0) {
            $sb.AppendLine("## Examples")
            $sb.AppendLine()
            foreach ($example in $this.Examples) {
                $sb.AppendLine(('### Example {0}. `{1}`' -f $index++, $example.Code))
                $sb.AppendLine()
                foreach ($line in $example.TextLines) {
                    $sb.AppendLine($line)
                }
            }
            $sb.AppendLine()
        }
        return $sb.ToString()
    }

    [string[]] $Synopsis = $null
    [void] ParseSynopsis() {
        if ($this.Help.Category -eq "Function") {
            $this.Synopsis = SplitLines $this.Help.Synopsis
        }
    }
    [string[]] $Description = $null
    [void] ParseDescription() {
        if ($this.Help.description) {
            $this.Description = SplitLines $this.Help.description.Text
        }
    }
    [List[ParameterDetailTable]] $ParameterDetails = [List[ParameterDetailTable]]::new()
    [void] ParseParameterDetails() {
        foreach ($paramHelp in $this.Help.parameters.parameter) {
            $this.ParameterDetails.Add([ParameterDetailTable]::new($this.CmdInfo.Parameters.Item($paramHelp.name), $paramHelp))
        }
    }

    [List[ParameterSetHelp]] $ParameterSets = [List[ParameterSetHelp]]::new()
    [void] ParseParameterSets() {
        $cmdsParameters = [HashSet[string]]::new()
        $this.Help.parameters.parameter.name | ForEach-Object { $cmdsParameters.Add($_) }
        foreach ($parameterSet in $this.CmdInfo.ParameterSets) {
            $this.ParameterSets.Add([ParameterSetHelp]::new($parameterSet, $cmdsParameters))
        }
    }
    [string[]] $InputTypes = $null
    [void] ParseInputTypes() {
        if ($this.Help.inputTypes) {
            $this.InputTypes = SplitLines $this.Help.inputTypes.inputType.type.name |
                ForEach-Object { $_.Trim() }
        }
    }
    [string[]] $OutputTypes = $null
    [void] ParseOutputs() {
        $outputs = $this.CmdInfo.OutputType
        if ($outputs.Count -eq 0) { return }
        $results = [string[]]::new($outputs.Count)
        for ($i = 0; $i -lt $outputs.Count; $i++) {
            $results[$i] = Get-TypeName -Type $outputs[$i].Type
        }
        $this.OutputTypes = $results
    }
    [List[ExampleHelp]] $Examples = [List[ExampleHelp]]::new()
    [void] ParseExamples() {
        if (-not $this.Help.examples.example) { return }
        $this.Help.examples.example | ForEach-Object {
            $this.Examples.Add([ExampleHelp]::new($_))
        }
    }
}

class ExampleHelp {
    [string] $Code
    [string[]] $TextLines
    ExampleHelp($example) {
        $this.Code = $example.code
        $this.TextLines = SplitLines $example.remarks.Text
    }
}
class ParameterSetHelp {
    [CommandParameterSetInfo] $ParameterSet
    [string] $Name
    [ordered] $Parameters = [ordered]@{}
    ParameterSetHelp([CommandParameterSetInfo] $set) {
        $this.SetParameters($set)
    }
    ParameterSetHelp([CommandParameterSetInfo] $set, [ICollection[string]] $IncludeList) {
        $this.SetParameters($set)
        $this.SetIncludeList($IncludeList)
    }
    [void] SetParameters([CommandParameterSetInfo] $set) {
        $this.ParameterSet = $set
        $this.Name = $set.Name;
        foreach ($param in $set.Parameters) {
            $this.Parameters.Add($param.Name, [ParameterInfoHelp]::new($param))
        }
    }
    [void] SetIncludeList([ICollection[string]] $IncludeList) {
        foreach ($info in $this.Parameters.Values) {
            $info.DontShow = ($info.Name -notin $IncludeList)
        }
    }
    [string] ToString() {
        $results = [List[string]]::new()
        $hasCommonParameter = $false
        foreach ($info in $this.Parameters.Values) {
            if ($info.DontShow) {
                $hasCommonParameter = $true
                continue
            }
            $results.Add($info.ToString())
        }
        if ($hasCommonParameter) {
            $results.Add("[<CommonParameters>]")
        }
        return $results -join " "
    }
    [List[string]] GetMarkdownList() {
        return $this.GetMarkdownList($false)
    }
    [List[string]] GetMarkdownList([bool] $SetLink) {
        $results = [List[string]]::new()
        $hasCommonParameter = $false
        foreach ($info in $this.Parameters.Values) {
            if ($info.DontShow) {
                $hasCommonParameter = $true
                continue
            }
            $results.Add($info.GetSyntaxMarkdown($SetLink))
        }
        if ($hasCommonParameter) {
            $results.Add('`[<CommonParameters>]`')
        }
        return $results
    }
}
$TypeDict = [psobject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Get
function Get-TypeName {
    [CmdletBinding(DefaultParameterSetName="Type")]
    param(
        [Parameter(Mandatory, ParameterSetName="Type", Position=0)]
        [type] $Type,
        [Parameter(Mandatory, ParameterSetName="TypeName", Position=0)]
        [string] $TypeName
    )
    if ($TypeName -and $TypeName -is [string]) {
        try {
            Write-Verbose ("Try to convert to type: {0}" -f $TypeName)
            $Type = [type]$TypeName
            if ($null -eq $Type) {
                return $TypeName
            }
            Write-Verbose ("Type: {0}" -f $Type)
        } catch {
            Write-Warning $_.Exception
            return $TypeName
        }
    }
    foreach ($keyValue in $TypeDict.GetEnumerator()) {
        if ($keyValue.Value -eq $type) {
            return $keyValue.Key
        }
    }
    return $type.Name
}

class ParameterDetailTable {
    [string] $Name
    [string[]] $Description = ""
    [string] $DefaultValue = ""
    [string] $Type
    [string[]] $Aliases
    [ordered] $Table = @{}
    ParameterDetailTable([ParameterMetadata] $metaData, $help) {
        $this.Name = $metaData.Name
        $this.Description = SplitLines $help.description.Text
        if ($help.defaultValue) {
            $this.DefaultValue = $help.defaultValue
        }
        $this.Aliases = $metaData.Aliases | ForEach-Object { $_ }
        $this.Type = $metaData.ParameterType.Name
        foreach ($_ in $metaData.ParameterSets.GetEnumerator()) {
            $this.ParseParameterMetadata($_.Key, $_.Value)
        }
    }
    [void] ParseParameterMetadata([string] $setName, [ParameterSetMetadata] $meta) {
        if ($setName -eq "__AllParameterSets") {
            $setName = "(ALL)"
        }
        $paramTable = @{
            Name = $setName;
            Position = $(if ($meta.Position -ge 0) { $meta.Position } else { "Named" });
            Required = $(if ($meta.IsMandatory) { "✅" } else { " -" });
            Pipeline = "-"
            RemainingArgs = $(if ($meta.ValueFromRemainingArguments) { "✅" } else { " -" })
        };
        $pipeLines = @()
        if ($meta.ValueFromPipeline) {
            $pipeLines += "ByValue"
        }
        if ($meta.ValueFromPipelineByPropertyName) {
            $pipeLines += "ByProperty"
        }
        if ($pipeLines) {
            $paramTable.Pipeline = $pipeLines -join "/"
        }
        $this.Table.Add($setName, $paramTable)
    }
    [string] ToMarkdownTable() {
        $sb = [StringBuilder]::new();
        $sb.AppendLine(("| Name        | Value"));
        $sb.AppendLine(("|:----------- |:{0}" -f ("-" * 19)));
        $sb.AppendLine(("| Type        | {0}" -f $this.Type));
        $sb.AppendLine(("| Alias       | {0}" -f ($this.Aliaes -join ", ")));
        if ($this.DefaultValue) {
        $sb.AppendLine(("| Default     | {0}" -f $this.DefaultValue));
        }
        return $sb.ToString();
    }
    [string] ToMarkdownTable2() {
        $sb = [StringBuilder]::new();
        if ($this.Table.Count -gt 1) {
            $sb.AppendLine();
            $this.Table.Values.Name      | ForEach-Object -Begin { $sb.Append("| By Group    "); } -Process { $sb.AppendFormat("| {0,-20}", $_); } -End { $sb.AppendLine() }
            $this.Table.Values.Name      | ForEach-Object -Begin { $sb.Append("|:----------- "); } -Process { $sb.AppendFormat("|:{0} ", ("-" * 19)); } -End { $sb.AppendLine() }
        } else {
            $this.Table.Values.Name      | ForEach-Object -Begin { $sb.Append("| Group       "); } -Process { $sb.AppendFormat("| {0,-20}", $_); } -End { $sb.AppendLine() }
        }
        $this.Table.Values.Position      | ForEach-Object -Begin { $sb.Append("| Position    "); } -Process { $sb.AppendFormat("| {0,-20}", $_); } -End { $sb.AppendLine() }
        $this.Table.Values.Required      | ForEach-Object -Begin { $sb.Append("| Required    "); } -Process { $sb.AppendFormat("| {0,-19}", $_); } -End { $sb.AppendLine() }
        $this.Table.Values.Pipeline      | ForEach-Object -Begin { $sb.Append("| Pipeline    "); } -Process { $sb.AppendFormat("| {0,-20}", $_); } -End { $sb.AppendLine() }
        $this.Table.Values.RemainingArgs | ForEach-Object -Begin { $sb.Append("| RemaingArgs "); } -Process { $sb.AppendFormat("| {0,-19}", $_); } -End { $sb.AppendLine() }
        return $sb.ToString()
    }
}
class ParameterInfoHelp {
    hidden [CommandParameterInfo] $Info
    [string] $Id
    [string] $Name
    [string] $ParameterString
    hidden [bool] $DontShow = $false
    ParameterInfoHelp($info) {
        $this.Info = $info
        $this.Name = $info.Name
        $this.Id = "parameter-{0}" -f $this.Name.ToLower()

        $sb = [StringBuilder]::new();
        if (-not $this.Info.IsMandatory) {
            $sb.Append("[")
        }
        if ($this.Info.Position -ge 0 ) {
            $sb.Append("[")
        }
        $sb.AppendFormat("-{0}", $this.Name);
        if ($this.Info.Position -ge 0 ) {
            $sb.Append("]")
        }
        if (-not $this.Info.ParameterType.Equals([SwitchParameter])) {
            $sb.AppendFormat(" <{0}>", (Get-TypeName($this.Info.ParameterType)));
        }
        if (-not $this.Info.IsMandatory) {
            $sb.Append("]")
        }
        $this.ParameterString = $sb.ToString()
    }
    [string] ToString(){ return $this.ParameterString }
    [string] GetSyntaxMarkdown() {
        return $this.GetSyntaxMarkdown($false)
    }
    [string] GetSyntaxMarkdown([bool] $SetLink) {
        if ($SetLink) {
            return ('[`{1}`](#{0})' -f $this.Id, $this.ParameterString)
        }
        return '`{0}`' -f $this.ParameterString
    }
}

function Convert-Help2Markdown {
    <#
        .SYNOPSIS
        Convert Help in the module to Markdown documents

        .DESCRIPTION

        .PARAMETER Module
        Module name will be imported

        .PARAMETER Cmds
        Command names

        .INPUTS
        string[]

        .EXAMPLE
        PS> Convert-Help2Markdown -Module Help2Markdown

        Generate help text for all commands in the Help2Markdown module.
        ```
        # Convert-Help2Markdown

        Convert Help in the module to Markdown documents

        ## Syntax
        (Snip)
        ```
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(ParameterSetName="Module", Mandatory)]
        [string] $Module,
        [Parameter(ParameterSetName="Module", ValueFromPipeline, position=1, ValueFromRemainingArguments)]
        [Parameter(ParameterSetName="Cmds", Mandatory, ValueFromPipeline, position=0, ValueFromRemainingArguments)]
        [string[]] $Cmds
    )
    begin {
        $commands = [System.Collections.Generic.HashSet[string]]::new();
        if ($Module) {
            Import-Module $Module -Force -Verbose:$false
        }
    }
    process {
        if ($Cmds -and $Cmds.Count -gt 0) {
            $Cmds | ForEach-Object {
                $null = $commands.Add($_);
            }
        } elseif ($Module) {
            Get-Command -Module $Module | ForEach-Object {
                $null = $commands.Add($_.Name)
            }
        }
    }
    end {
        if ($commands.Count -eq 0 -and $Module) {
            $commands = Get-Command -Module $Module
        }
        if ($commands.Count -eq 0) {
            Write-Error ("Target commands are empty. Abort.")
        }
        $commands | Get-Command  | ForEach-Object {
            Write-Verbose ("{0} ({1})" -f $_.Name, $_.ModuleName)
            $md = [HelpGenerator]::new($_);
            $md.GenerateMarkdown()
        }
    }
}
Set-Alias help2md Convert-Help2Markdown
