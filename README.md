# Help2Markdown
Convert Help to Markdown Document

## Usage

```powershell
Convert-Help2Markdown Command-Name ...
```

See: [Convert-Help2Markdown for command detail](docs/Convert-Help2Markdown.md)

### Example

```
PS1> Convert-Help2markdown Get-Help
# Get-Help

## Syntax

  1. (AllUsersView)
     Get-Help [`[[-Name] <string>]`](#parameter-name) [`[-Path <string>]`](#parameter-path) [`[-Category <String[]>]`](#parameter-category) [`[-Full]`](#parameter-full) [`[-Component <String[]>]`](#parameter-component) [`[-Functionality <String[]>]`](#parameter-functionality) [`[-Role <String[]>]`](#parameter-role) `[<CommonParameters>]`
  2. (DetailedView)
     Get-Help [`[[-Name] <string>]`](#parameter-name) [`[-Path <string>]`](#parameter-path) [`[-Category <String[]>]`](#parameter-category) [`-Detailed`](#parameter-detailed) [`[-Component <String[]>]`](#parameter-component) [`[-Functionality <String[]>]`](#parameter-functionality) [`[-Role <String[]>]`](#parameter-role) `[<CommonParameters>]`
  3. (Examples)
     Get-Help [`[[-Name] <string>]`](#parameter-name) [`[-Path <string>]`](#parameter-path) [`[-Category <String[]>]`](#parameter-category) [`-Examples`](#parameter-examples) [`[-Component <String[]>]`](#parameter-component) [`[-Functionality <String[]>]`](#parameter-functionality) [`[-Role <String[]>]`](#parameter-role) `[<CommonParameters>]`
  4. (Parameters)
     Get-Help [`[[-Name] <string>]`](#parameter-name) [`[-Path <string>]`](#parameter-path) [`[-Category <String[]>]`](#parameter-category) [`-Parameter <String[]>`](#parameter-parameter) [`[-Component <String[]>]`](#parameter-component) [`[-Functionality <String[]>]`](#parameter-functionality) [`[-Role <String[]>]`](#parameter-role) `[<CommonParameters>]`
  5. (Online)
     Get-Help [`[[-Name] <string>]`](#parameter-name) [`[-Path <string>]`](#parameter-path) [`[-Category <String[]>]`](#parameter-category) [`[-Component <String[]>]`](#parameter-component) [`[-Functionality <String[]>]`](#parameter-functionality) [`[-Role <String[]>]`](#parameter-role) [`-Online`](#parameter-online) `[<CommonParameters>]`

(Snip)

PS1>
```

## Install

clone the repository directly to your PowerShell Module directory.
```
$ pwsh
PS1> cd ($env:PSModulePath -split ":")[0]
PS1> git clone git@github.com:teramako/Help2Markdown.psm.git Help2Markdown
Cloning into 'Help2Markdown.psm'...
(snip)
```

or create symbolic link to the repository.
```
$ git clone git@github.com:teramako/Help2Markdown.psm.git
Cloning into 'Help2Markdown.psm'...
(snip)
$ ln -s $PWD/Help2Markdown.psm <PSModulePath>/Help2Markdown
```

