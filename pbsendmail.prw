#INCLUDE "TOTVS.CH"

//** Criado por: Alessandro de Farias - amjgfarias@gmail.com - Em: 17/06/2018
User Function pbsendmail(cPara,cCopia,cConhCopia,cAssunto,_cDe,cTexto,lHtml,cFile,lConfMaiRead,aPWD,lJob)
Return StartJob("U_JobMail", GetEnvServer(),.F., { cEmpAnt,cFilAnt,__cUserID,cPara,cCopia,cConhCopia,cAssunto,_cDe,cTexto,lHtml,cFile,lConfMaiRead,aPWD,lJob } )


User Function JobMail(aDados)
Local lRet := .T.
aDados[03] := iif(Empty(aDados[03]),'000000',aDados[03])
RpcClearEnv()
RpcSetEnv( aDados[01], aDados[02] )
__cUserID := aDados[03]
cUserName := UsrRetName( __cUserID )
lRet := EnvMail(aDados[04]/*cPara*/,aDados[05]/*cCopia*/,aDados[06]/*cConhCopia*/,aDados[07]/*cAssunto*/,aDados[08]/*_cDe*/,aDados[09]/*cTexto*/,aDados[10]/*lHtml*/,aDados[11]/*cFile*/,aDados[12]/*lConfMaiRead*/,aDados[13]/*aPWD*/,aDados[14]/*lJob*/)
Return lRet


//** Criado por: Alessandro de Farias - amjgfarias@gmail.com - Em: 17/06/2018
Static Function EnvMail(cTo,cCc,cBcc,cSubject,_cDe,cBody,lHtml,uFile,lConfMaiRead,aPWD,lAuto)

Local oMailServer	:= Nil
Local lRetorno   	:= .F.
Local nSMTPPort  	:= SuperGetMV("MV_PORSMTP",.F.,587) // Porta SMTP.
Local cSMTPAddr  	:= SuperGetMV("MV_RELSERV",.F.,"")  // Endereco SMTP.  
Local cUser      	:= SuperGetMV("MV_RELACNT",.F.,"")  // Conta a ser utilizada no envio de E-Mail para os relatorios.
Local cPass      	:= SuperGetMV("MV_RELPSW" ,.F.,"")  // Senha da Conta de E-Mail para envio de relatorios.
Local lAutentica	:= SuperGetMV("MV_RELAUTH",.F.,.F.) // Servidor de EMAIL necessita de Autenticacao?
Local nSMTPTime	:= SuperGetMV("MV_RELTIME",.F.,120) // Timeout no Envio de EMAIL.
Local lSSL       	:= SuperGetMV("MV_RELSSL" ,.F.,.F.) // Define se o envio e recebimento de e-mails na rotina SPED utilizara conexao segura (SSL).
Local lTLS       	:= SuperGetMV("MV_RELTLS" ,.F.,.T.) // Informe se o servidor de SMTP possui conexao do tipo segura ( SSL/TLS ).
Local nError     	:= 0								 		   // Controle de Erro.
Local nX          := 0
Local nPortAddSrv	:= 0
Local cUserAut		:= "asdfasdfasdfasdf"
Local cPassAut		:= "asdfasdfasdfasdfasdfasdfasdf"
Local cFrom			:= "asdfasdf@asdfasdfasdf.com.br"
Local aAnexos     := {}

Default cTo       := ""
Default cCc       := ""
Default cBcc      := ""
Default cSubject  := ""
Default cBody     := ""
Default _cDe		:= "asdfasdf@asdfasdfasdf.com.br"
Default lAuto     := .F.
Default lConfMaiRead	:= .F.
Default aPWD		:= {}
Default uFile     := ""

If aPWD <> Nil .And. Len(aPWD) <> 0
	cDe       := cUserAut  := cUser 	 := cFrom     := aPWD[01]
	cPass 	 := cPassAut  := aPWD[02]
Endif

If ValType(uFile) == "C"
	aAnexos := StrToArray(uFile,";")
Else
	aAnexos := aClone(uFile)
Endif

oMailServer := TMailManager():New()
oMailServer:SetUseSSL(lSSL)
oMailServer:SetUseTLS(lTLS)

// Inicializacao do objeto de Email
If nError == 0
	//Prioriza se a porta está no endereço
	nPortAddSrv := AT(":",cSMTPAddr)
	If nPortAddSrv > 0
		nSMTPPort := Val(Substr(cSMTPAddr, nPortAddSrv + 1,Len(cSMTPAddr)))
		cSMTPAddr := Substr(cSMTPAddr, 0, nPortAddSrv - 1)
	EndIf
	nError := oMailServer:Init("",cSMTPAddr,cUser,cPass,,nSMTPPort)
	If nError <> 0
		Conout("Falha ao conectar:"+ oMailServer:GetErrorString(nError))
		Return .F.
	EndIf
Endif

// Define o Timeout SMTP
If ( nError == 0 .And. oMailServer:SetSMTPTimeout(nSMTPTime) <> 0 )
	nError := 1
	Conout("Falha ao definir timeout")
	Return .F.
EndIf

// Conecta ao servidor
If nError == 0
	nError := oMailServer:SmtpConnect()
	If nError <> 0
		Conout("Falha ao conectar:" + oMailServer:GetErrorString(nError))
		oMailServer:SMTPDisconnect()
		Return .F.
	EndIf
EndIf

// Realiza autenticacao no servidor
If nError == 0 .And. lAutentica
	nError	:= oMailServer:SmtpAuth(cUserAut,cPassAut)
	If nError <> 0
		Conout("Falha ao autenticar: "+oMailServer:GetErrorString(nError))
		oMailServer:SMTPDisconnect()
		Return .F.
	EndIf
EndIf

If nError == 0
	oMessage:= TMailMessage():New()
	oMessage:Clear()
	oMessage:cFrom    := cFrom
	oMessage:cTo      := cTo
	oMessage:cCc      := cCc
	oMessage:cBcc     := cBcc
	oMessage:cSubject := cSubject
	oMessage:cBody    := cBody
	//oMessage:MsgBodyType( "text/html" )
	For nX := 1 to Len(aAnexos)
		oMessage:AttachFile(aAnexos[nX])
	Next nX
	nError := oMessage:Send( oMailServer )
	If nError <> 0
		lRetorno := .F.
		Conout("TMailMessage Falha no envio do Email - " + oMailServer:GetErrorString(nError))
	Else
		lRetorno := .T.
	EndIf
	oMailServer:SmtpDisconnect()
EndIf

Return lRetorno
