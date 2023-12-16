# Convert-Help2Markdown

Convert Help in the module to Markdown documents

## Syntax

  1. (Module)  
     Convert-Help2Markdown [`-Module <string>`](#parameter-module) [`[[-Cmds] <String[]>]`](#parameter-cmds) `[<CommonParameters>]`
  2. (Cmds)  
     Convert-Help2Markdown [`[-Cmds] <String[]>`](#parameter-cmds) `[<CommonParameters>]`

## Parameters

### Parameter`-Module`

Module name will be imported

| Name        | Value
|:----------- |:-------------------
| Type        | String
| Alias       | m
| Group       | Module              
| Position    | Named               
| Required    | ✅                  
| Pipeline    | -                   
| RemaingArgs |  -                 

### Parameter`-Cmds`

Command names

| Name        | Value
|:----------- |:-------------------
| Type        | String[]
| Alias       | 

| By Group    | Cmds                | Module              
|:----------- |:------------------- |:------------------- 
| Position    | 0                   | 1                   
| Required    | ✅                  |  -                 
| Pipeline    | ByValue             | ByValue             
| RemaingArgs | ✅                  | ✅                  


## Pipeline Inputs

 - `string[]`

## Outputs

 - `string`

## Examples

### Example 1. `Convert-Help2Markdown -Module Help2Markdown`

Generate help text for all commands in the Help2Markdown module.
```
# Convert-Help2Markdown

Convert Help in the module to Markdown documents

## Syntax
(Snip)
```
