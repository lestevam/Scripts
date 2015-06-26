'Executar < cscript CriadorDeSitesIIS.vbs >
Dim SiteName
Dim SiteNameFTP
Dim PhysicalPath
Dim SiteApplications
Dim Application
Dim Pool
Dim Port
Dim PortFTP
Dim DevApplications
Dim MaxSleep : MaxSleep = 1000

'Array(NomeAplicacao,ApontamentoAplicacao)
SiteApplications = Array(Array("aplicacao1","caminho1"), Array("aplicacao2","caminho2"))

' Array(NomeDoSite, CaminhoDoSite, PortaSite, PortaFTP, ArrayAplicacoesSeremCriadas)
SITE1 = Array("DEV1", "D:\DEV1\", 8810, 8811,SiteApplications)
SITE2 = Array("DEV2", "D:\DEV2\", 8820, 8821,SiteApplications)

Set dic = CreateObject("Scripting.Dictionary")
dic.Add 1,SITE1
dic.Add 2,SITE2

Set oWebAdmin = GetObject("winmgmts:root\WebAdministration")
for dev = 1 to dic.Count 
	SiteName = dic.Item(dev)(0)
	SiteNameFTP = SiteName&"_FTP"
	PhysicalPath = dic.Item(dev)(1)
	Port = dic.Item(dev)(2)
	PortFTP = dic.Item(dev)(3)
	DevApplications = dic.Item(dev)(4)
	
	'Wscript.Echo UBound(dic.Item(dev)(4))+1
	Wscript.Echo "Iniciando procedimento para " & SiteName
	Call DeleteSite(SiteName)
	Call DeleteSite(SiteNameFTP)
	Call RemovePools()
	Call CreateNewSite()
	Call CreateNewFTP()
	Call SettingFTP()
	Call CreatePools()
	Call SettingPoolSite()
	Call CreateSiteApplications()
	Call SettingPoolApplications()
	Call GeneralSettings()
	
	If check() Then 
		Wscript.Echo "==> " & SiteName & " criado com sucesso!" & chr(13) & chr(13)
	Else 
		Wscript.Echo "XXX ERRO:  ao criar site " & Sitename & chr(13) & chr(13)
	End If
	
Next

Function isExistsSite(site)
	Dim retorno : retorno = 0
	Set oSites = oWebAdmin.InstancesOf("Site")
	For Each oSite in oSites
		If ( oSite.Name = site ) Then
			retorno = 1
			Exit For
		End If
	Next
	isExistsSite = retorno
End Function

Function check()
	check = (isExistsSite(Sitename) AND isExistsSite(SiteNameFTP))
End Function

Sub CreateNewSite()
	Set SiteBinding = oWebAdmin.Get("BindingElement").SpawnInstance_
	SiteBinding.BindingInformation = "*:"&PORT&":"
	SiteBinding.Protocol = "HTTP"
	BindingsArray = array(SiteBinding)
	Set SiteDefinition = oWebAdmin.Get("Site")
	SiteDefinition.Create SiteName, BindingsArray, PhysicalPath
	WScript.Sleep(MaxSleep)
	WScript.Echo "Criando (SITE): " & SiteName
End Sub

Sub CreateNewFTP()
	Set SiteBinding = oWebAdmin.Get("BindingElement").SpawnInstance_
	SiteBinding.BindingInformation = "*:"&PortFTP&":"
	SiteBinding.Protocol = "FTP"
	BindingsArray = array(SiteBinding)
	Set SiteDefinition = oWebAdmin.Get("Site")
	SiteDefinition.Create SiteNameFTP, BindingsArray, PhysicalPath
	WScript.Sleep(MaxSleep)
	WScript.Echo "Criando (FTP): " & SiteNameFTP
End Sub

Sub DeleteSite(SiteDelete)
	Set oSites = oWebAdmin.InstancesOf("Site")
	if isExistsSite(SiteDelete) Then
		Wscript.Echo "Site deletado: " & SiteDelete & chr(13)
		Set delSite = oWebAdmin.Get("Site.Name='" & SiteDelete & "'")
		delSite.Delete_
	End If
	WScript.Sleep(MaxSleep)
End Sub

Sub SettingFTP()
	Set adminManager = createObject("Microsoft.ApplicationHost.WritableAdminManager")
	adminManager.CommitPath = "MACHINE/WEBROOT/APPHOST"
	Set sitesSection = adminManager.GetAdminSection("system.applicationHost/sites", "MACHINE/WEBROOT/APPHOST")
	Set siteDefaultsElement = sitesSection.ChildElements.Item("siteDefaults")
	Set ftpServerElement = siteDefaultsElement.ChildElements.Item("ftpServer")
	Set securityElement = ftpServerElement.ChildElements.Item("security")
	Set sslElement = securityElement.ChildElements.Item("ssl")
	sslElement.Properties.Item("controlChannelPolicy").Value = "SslAllow"
	Set authenticationElement = securityElement.ChildElements.Item("authentication")
	Set anonymousAuthenticationElement = authenticationElement.ChildElements.Item("anonymousAuthentication")
	Set basicAuthenticationElement = authenticationElement.ChildElements.Item("basicAuthentication")
	basicAuthenticationElement.Properties.Item("enabled").Value = true
	Set authorizationSection = adminManager.GetAdminSection("system.ftpServer/security/authorization", "MACHINE/WEBROOT/APPHOST/"&SiteNameFTP)
	Set authorizationCollection = authorizationSection.Collection
	Set addElement = authorizationCollection.CreateNewElement("add")
	addElement.Properties.Item("accessType").Value = "Allow"
	addElement.Properties.Item("roles").Value = "FTPUsers"
	addElement.Properties.Item("permissions").Value = "Read, Write"
	authorizationCollection.AddElement(addElement)      
	adminManager.CommitChanges()
	WScript.Sleep(MaxSleep)
	WScript.Echo "Configurando FTP " & SiteNameFTP
End Sub

Sub CreatePools()
	SET ApplicationPoolDefinition = oWebAdmin.Get("ApplicationPool")
	On Error Resume Next
	Set SiteNamePool = oWebAdmin.Get("ApplicationPool.Name='" & SiteName &"'")
	If SiteNamePool Is Nothing Then
		ApplicationPoolDefinition.Create(SiteName)	
		WScript.Sleep(MaxSleep)
		WScript.Echo "Criando Pool para: " & SiteName
	End If
	On Error GOTO 0
	For id = 0 to UBound(DevApplications)
		Dim namePool : namePool = SiteName & "_" & Replace(DevApplications(id)(0), "/","_")
		ApplicationPoolDefinition.Create(namePool)	
		WScript.Sleep(MaxSleep)
		WScript.Echo "Criando Pool para: " & namePool
	Next
End Sub

Sub RemovePools()
	For id = 0 to UBound(DevApplications)
		Dim namePool : namePool = SiteName & "_" & Replace(DevApplications(id)(0),"/","_")
		Set existingPools = oWebAdmin.InstancesOf("ApplicationPool")
		For Each p In existingPools
			If p.Name = namePool Then
				p.Delete_
				WScript.Sleep(MaxSleep)
				WScript.Echo "Removendo Pool para: " & namePool
			ElseIf p.Name = SiteName Then
				p.Delete_
				WScript.Sleep(MaxSleep)
				WScript.Echo "Removendo Pool para: " & SiteName			
			End If
		Next
	Next
End Sub

Sub CreateSiteApplications
	Set ApplicationDefinition = oWebAdmin.Get("Application")
	For id = 0 to UBound(DevApplications)
		ApplicationDefinition.Create "/"&DevApplications(id)(0), SiteName, PhysicalPath&DevApplications(id)(1)&"\"
		WScript.Sleep(MaxSleep)	
		WScript.Echo "Configurando aplicacao: /" & DevApplications(id)(0) & " apontando para " & PhysicalPath & DevApplications(id)(1)&"\"
	Next
End Sub

Sub SettingPoolSite()
	Set oSite = oWebAdmin.Get("Site.Name='"&SiteName&"'")
	oSite.ApplicationDefaults.ApplicationPool = SiteName
	oSite.Put_
	WScript.Sleep(MaxSleep)	
	Wscript.Echo "Configurando pool para site " & SiteName
End Sub

Sub SettingPoolApplications()
	For id = 0 to UBound(DevApplications)
		Set pools = oWebAdmin.Get("Application.SiteName='"&SiteName&"',Path='/" & DevApplications(id)(0) & "'")
		pools.ApplicationPool = SiteName & "_" & Replace(DevApplications(id)(0),"/","_")
		pools.Put_
		WScript.Sleep(MaxSleep)	
		WScript.Echo "Configurando pools para aplicacao: /" & DevApplications(id)(0) 
	Next
End Sub

Sub GeneralSettings()
	Set adminManager = CreateObject("Microsoft.ApplicationHost.WritableAdminManager")
	adminManager.CommitPath = "MACHINE/WEBROOT/APPHOST"
	Set aspSection = adminManager.GetAdminSection("system.webServer/asp", "MACHINE/WEBROOT/APPHOST/"&SiteName)
	aspSection.Properties.Item("enableParentPaths").Value = True
	aspSection.Properties.Item("scriptErrorSentToBrowser").Value = True
	aspSection.Properties.Item("appAllowDebugging").Value = True
	Set limitsElement = aspSection.ChildElements.Item("limits")
	limitsElement.Properties.Item("bufferingLimit").Value = 1073741823
	limitsElement.Properties.Item("maxRequestEntityAllowed").Value = 1073741823
	limitsElement.Properties.Item("scriptTimeout").Value = "00:20:00"
	Set sessionElement = aspSection.ChildElements.Item("session")
	sessionElement.Properties.Item("timeout").Value = "05:00:00"
	adminManager.CommitChanges()
End Sub