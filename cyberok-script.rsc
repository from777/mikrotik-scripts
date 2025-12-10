# CyberOK update script
# Скачивает список IP и добавляет в address-list 

/system script remove [find name="update-cyberok-list"]

/system script add name="update-cyberok-list" source={
:local listName "cyberok-ban"
:local url "https://raw.githubusercontent.com/tread-lightly/CyberOK_Skipa_ips/main/lists/skipa_cidr.txt"
:local fileName "cyberok-temp.txt"

:log info "CyberOK: Start update"

:do {
/tool fetch url=$url mode=https dst-path=$fileName
:log info "CyberOK: File downloaded"
} on-error={
:log error "CyberOK: Download failed"
:error "Download failed"
}

:delay 3s

:if ([:len [/file find name=$fileName]] = 0) do={
:log error "CyberOK: File not found"
:error "File not found"
}

:log info "CyberOK: Removing old list"
/ip firewall address-list remove [find where list=$listName]

:log info "CyberOK: Adding new IPs"
:local content [/file get $fileName contents]
:local lineStart 0
:local lineEnd 0
:local line ""
:local countAdded 0

:for i from=0 to=([:len $content] - 1) do={
:local char [:pick $content $i]
:if ($char = "\n") do={
:set lineEnd $i
:set line [:pick $content $lineStart $lineEnd]
:if ([:pick $line ([:len $line] - 1)] = "\r") do={
:set line [:pick $line 0 ([:len $line] - 1)]
}
:if ([:len $line] > 7) do={
:do {
/ip firewall address-list add list=$listName address=$line
:set countAdded ($countAdded + 1)
} on-error={}
}
:set lineStart ($i + 1)
}
}

:if ($lineStart < [:len $content]) do={
:set line [:pick $content $lineStart [:len $content]]
:if ([:len $line] > 7) do={
:do {
/ip firewall address-list add list=$listName address=$line
:set countAdded ($countAdded + 1)
} on-error={}
}
}

/file remove $fileName

:local logMsg ("CyberOK: Update done. Added: " . $countAdded)
:log info $logMsg
}

# Scheduler - раз в неделю в 4 утра
/system scheduler remove [find name="auto-update-cyberok"]
/system scheduler add name="auto-update-cyberok" interval=1w start-time=04:00:00 on-event="update-cyberok-list"
