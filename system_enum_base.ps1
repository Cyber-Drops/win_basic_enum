<#
Il programma legge le impostazioni da un file json nella stessa directory chiamato: config.json
Il programma richiede all'utente di specificare una rete (si /no).
Elenca i nomi dei profili wlan trovati nel pc.
Si inserisce il nome del profilo.
Ritorna le informazioni del profilo con la password in chiaro.
AUTHOR: Simone Tempesta
#>
Write-Output """
   .-------------------------.
  | .-----------------------. |
  | |     Win_Basic_Enum    | |
  | |         From:         | |
  | |      S.Tempesta       | |
  | |                       | |
  | `-----------------------' |
  `-------------------------'
    / /````````````````````\ \
   / /______________________\ \
  |____________________________|
  | [][][][][][][][][][][][][] |
   `--------------------------'
"""

function Get-config {
    param ([string] $curretnPath)
    <#Legge un file di configurazione e lo formatta conn struttura json
    Param [string] path: percorso dove trovare il file, comprensivo di nome 
                        del file ed estensione
    Return [json object] json_data: oggetto di tipo powershell json#>
    $json_strings = Get-Content $curretnPath"./config.json" -Raw
    $json_data = $json_strings | ConvertFrom-Json
    return $json_data
}

function Get-ssid {
    <#Esegue il comando di sistema per richiamare i profili 
    reti Wifi salvati nel pc e ne ripulisce l'output,
    Return ssid: Hashtable, key:0 a x e value:Wifi Ssid#>
    [hashtable] $ssid = @{}
    $profile_name = netsh wlan show profiles
    $profile_name = $profile_name.Split(":")
    for (($i = 0), ($j = 0); $i -lt $profile_name.Count; $i++) {
        if (($i -gt 10)) {
            if (($i % 2) -ne 0 ) {
                $ssid[$j] = $profile_name[$i].Trim()
                $j++
            }
        }
    }
    return $ssid
}


function Get-wifi-info {
    param ([hashtable]$ssid)
    <#Esegue il comando di sistema per richiamare le info
    sui profili delle Wlan passate come parametro.
    Param ssid : Hashtable, key:0-x, value: wlan profile name
    Return wifi_info: Hashtable, key:Wlan profile name e value: info wlan profile#>
    $wifi_info = @{}
    for ($i = 0; $i -lt $ssid.Count; $i++) {
        $wifi_info[$ssid[$i]] = netsh wlan show profile name=($ssid[$i].ToString().Trim())
    }
    return $wifi_info
}

function Get-wifi-pw {
    param ([hashtable]$wifi_info)
    <#Esegue il comando di sistema per richiamare la password
    dei profili delle Wlan passate come parametro.
    Param wifi_info : Hashtable, key:Wlan profile name e value: info wlan profile
    Return wifi_pw: Hashtable, key:Wlan profile name e value: wlan password#>
    $wifi_pw = @{}
    foreach ($key in $wifi_info.Keys){
        $wifi_pw[$key] = netsh wlan show profile name=$key key=clear
    }
    return $wifi_pw
}


function main {
    param ([string] $curretnPath)
    #INIT
    Out-File -FilePath $curretnPath"\wlan.info" #creazione di un file vuoto per salvare le configurazioni, sempre vuoto all'inizio
    $json_data = Get-config($curretnPath)
    #Info computer
    if ($json_data.info_sistema.to_do -eq "si"){
        $computer_info = Get-ComputerInfo
        if ($json_data.info_sistema.to_file -eq "si") {
            Write-Output "Le informazioni sul PC saranno salvate in modalita sovrascrittura sul file: pc.info"
            $computer_info | Out-File -FilePath $curretnPath"\pc.info"
        }else {
            Write-Output $computer_info
        }
    }
    #Info Wlan
    if ($json_data.wifi_info.to_do -eq "si") {
        $ssid = Get-ssid
        $wifi_info = Get-wifi-info($ssid)
        if ($json_data.wifi_info.to_file -eq "si") {
            Write-Output "Le informazioni sulle Wlan saranno salvate in modalita sovrascrittura sul file: wlan.info"
            foreach($v in $wifi_info.values){
            $v | Out-File -FilePath $curretnPath"\wlan.info" -Append
            }  
        }else {
            Write-Output $wifi_info
        }
    }
    #Wlan Password
    if ($json_data.wifi_pw.to_do -eq "si" -and $json_data.wifi_info.to_do -eq "si") {
        $wifi_pw = Get-Wifi-Pw($wifi_info)
        $formatted_wifi_pw = $wifi_pw | ConvertTo-Json
        $formatted_wifi_pw = $formatted_wifi_pw | ConvertFrom-Json
    }elseif ($json_data.wifi_pw.to_do -eq "si" -and $json_data.wifi_info.to_do -eq "no") {
        $ssid = Get-ssid
        $wifi_info = Get-wifi-info($ssid)
        $wifi_pw = Get-Wifi-Pw($wifi_info)
        $formatted_wifi_pw = $wifi_pw | ConvertTo-Json
        $formatted_wifi_pw = $formatted_wifi_pw | ConvertFrom-Json
        }
    if ($json_data.wifi_pw.to_file -eq "si") {
        #Write-Output $formatted_wifi_pw
        if ($json_data.wifi_pw.to_do -eq "si") {
            Write-Output "Le password delle Wlan saranno salvate in modalita sovrascrittura sul file: wlan.pw"
            Out-File -FilePath $curretnPath"\wlan.pw"
            foreach($key in $wifi_pw.keys){
                $formatted_wifi_pw.$key[21] | Out-File -FilePath $curretnPath"\wlan.pw" -Append
                $formatted_wifi_pw.$key[26] | Out-File -FilePath $curretnPath"\wlan.pw" -Append
                $formatted_wifi_pw.$key[28..33] | Out-File -FilePath $curretnPath"\wlan.pw" -Append
                "---------<------>---------" | Out-File -FilePath $curretnPath"\wlan.pw" -Append
            } 
        }else {
            Write-Output "Non e' stato possibile eseguire la scrittura su fiule delle password wlan"
            Write-Output "verifica il file di configurazione, il parametro wi_pw:to_do deve essere impostato a si "
        }          
    }
    #Visualizza wlan specifica
    $answer = Read-Host "vuoi selezionare una rete specifica da visualizzare? si/no: "
    if ($answer -eq "si") {
        # mostra a video i profili wlan
        Write-Output $wifi_info.Keys
        $rete_selezionata = Read-Host "Immetti nome rete: "
        Write-Output $formatted_wifi_pw.$rete_selezionata
    }else {
        Write-Output "Revisione Wlan trovate salvate sul pc:"
        Write-Output $formatted_wifi_pw
    }
}
#start
$curretnPath = (Split-Path $MyInvocation.MyCommand.Source)
main($curretnPath)

