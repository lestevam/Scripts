# Exemplo para busca de objetos por regexp
Get-ChildItem -Path C:\DIRETORIO -Recurse | Where-Object{ $_.Name -Match '(regexp1)|(regexp2)' }

# Exemplo para renomear arquivos ou pasta por regexp escapando caracteres de colchetes (bug ps 2.0)
Get-ChildItem -Path C:\DIRETORIO -Recurse | Where-Object{ $_.Name -Match '(.*\[.*)|(.*\].*)' } | ForEach-Object -Process {Rename-item -Path ($_.FullName -replace '\[','`[' -replace '\]','`]')  -NewName ($_.name -replace "\[|\]","_") -WhatIf}

# Exemplo para escrever no terminal
Get-ChildItem -Path C:\DIRETORIO -Recurse | Where-Object{ $_.Name -Match '(regextp1)' } | ForEach-Object { Write-Host $_.FullName }


##########################################################################
##### Remove diretórios desncessários ####################################
##########################################################################
$regExp = '(regexp1)|(regexp2)'
$oldPath = 'C:\DIRETORIO\'
Get-ChildItem -Path $oldPath -Recurse | Where-Object{ $_.Name -Match $regExp } | ForEach-Object {
    try
    {
        Remove-Item ($_.FullName -replace '\[','`[' -replace '\]','`]') -ErrorAction SilentlyContinue -Force -Confirm:$false -Recurse
        Write-Host "Removendo Item: " $_.FullName
    }
    catch
    {
        Write-Host "Erro ao remover arquivo" $_.FullName
    }
    Write-Host "--------------------------------------------------------------------------------------------------------------------------"
}

##########################################################################
##### Copia arquivos para diretório de backup ############################
##########################################################################
$regExp = '(regexp1)|(regexp2)'
$regExpExclude = "(regexp1)|(regexp2)"
$oldPath = 'C:\DIRETORIO\'
$pathBkp = 'C:\DIRETORIO\BACKUP\'
Get-ChildItem -Path $oldPath -Recurse | Where-Object{ ! $_.PSIsContainer -and $_.Name -Match $regExp -and $_.FullName -inotmatch $regExpExclude } | ForEach-Object {
    try
    {
        $pathNew = $_.FullName -replace [regex]::Escape($oldPath),""
        $newPath = Join-Path $pathBkp $pathNew
        Write-Host "Arquivo: " $_.FullName;
        Write-host "Novo Caminho: " $newPath
        New-Item -Path $newPath -ItemType file -Force | out-null
        $_ | Copy-Item -Destination $newPath
    }
    catch
    {
        Write-Host "Erro ao copiar arquivo" $_.FullName
    }

    try
    {
        # Trata bug do powershell 2.0 em reconhecer colchetes em caminhos de arquivos
        Remove-Item ($_.FullName -replace '\[','`[' -replace '\]','`]')
        Write-Host "Removendo Item: " $_.FullName
    }
    catch
    {
        Write-Host "Erro ao remover arquivo"  $_.FullName
    }
    Write-Host "--------------------------------------------------------------------------------------------------------------------------"
}

##########################################################################
##### Realize varredura de arquivos com números que devem ser copiados ###############
##########################################################################
$pathFileText = 'C:\DIRETORIO\arquivo.txt'
$oldPath = 'C:\DIRETORIO\'
$date = Get-Date -format 'd/MM/yyyy HH:mm';
Add-Content $pathFileText  "Inicio do Processamento $date"
$regExp = '(regexp)'
$regExpExclude = "(regexp)"
Get-ChildItem -Path $oldPath -Recurse | Where-Object{ ! $_.PSIsContainer -and $_.Name -Match $regExp -and $_.FullName -inotmatch $regExpExclude } | ForEach-Object {
    write-host $_.FullName;
    Add-Content $pathFileText $_.FullName
}
$data = Get-Date -format 'd/MM/yyyy HH:mm';
Add-Content $pathFileText "Final de Processamento $data"
Add-Content $pathFileText "_____________________________________________________________________________________________________________________"


##########################################################################
##### Remove diretórios vazios #################################
##########################################################################
$pathFileText = 'C:\DIRETORIO\arquivo.txt'
$oldPath = 'C:\DIRETORIO\'
$date = Get-Date -format 'd/MM/yyyy HH:mm';
Add-Content $pathFileText  "Inicio do Processamento $date"
Get-ChildItem $oldPath -recurse | Where {$_.PSIsContainer -and @(Get-ChildItem -LiteralPath:$_.fullname).Count -eq 0} | Sort-Object FullName -descending | foreach {
        write-host $_.FullName;
        Remove-Item $_.FullName -ErrorAction SilentlyContinue -Force -Confirm:$false -Recurse
    };
$data = Get-Date -format 'd/MM/yyyy HH:mm';
Add-Content $pathFileText "Final de Processamento $data"
Add-Content $pathFileText "_____________________________________________________________________________________________________________________"
