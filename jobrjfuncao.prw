#INCLUDE "TOTVS.CH"
#INCLUDE "FILEIO.CH"

/*/{Protheus.doc} jobrjfuncao
	@type  Function
	@author Alessandro Farias
   @email alessandro@farias.net.br
	@since 19/05/2022
	@version 1.00
/*/
User Function jobrjfuncao
StartJob("U_RJFUNCAO",GetEnvServer(),.F., { "xx", "xx" } )
Return

User Function RJFUNCAO(aParam)
Local aSM0  := {}
Local nX, nHdl

If ValType(aParam) <> "U" .And. aParam[01] == "Scheddef"
   // veio do agendamento
Else
   // foi chamada de outro local
Endif

fErase( GetPathSemaforo() + "jobrjfuncao.lck" )
nHdl := fCreate( GetPathSemaforo() + "jobrjfuncao.lck" )
If nHDL < 0
	ConOut( "ERRO em jobrjfuncao.prw em " + DTOC(Date()) + " - " + Time() )
	Return .F.
EndIf

Set Deleted On
SET(_SET_DELETED, .T.)

OpenSM0()

DbSelectArea("SM0")
Set Filter To Alltrim(M0_CODFIL) == '01'
SM0->( dbSetOrder(1) )
SM0->( dbGotop() )
DO While ! SM0->( Eof() )
	aAdd(aSM0, { SM0->M0_CODIGO, Alltrim(SM0->M0_CODFIL) } )
	SM0->( dbSkip() )
EndDo
RpcClearEnv()

For nX:=1 To Len(aSM0)
	RpcClearEnv()
	RpcSetEnv( aSM0[nX][01], aSM0[nX][02] )
	RJ_FUNCAO()
Next nX

FClose( nHDL )
fErase( GetPathSemaforo() + "jobrjfuncao.lck" )
RpcClearEnv()
KillApp(.T.) // https://tdn.totvs.com/display/tec/KillApp

Return

Static Function RJ_FUNCAO()
Local aField := {;
"RJ_FUNCAO","BA1_CODFUN","BTS_CODFUN","RC6_CODFUN","REX_CODFUN","RF7_CODFUN","RFK_CODFUN","RGB_CODFUN","RI7_CODFUN","P2_CODFUN1","P2_CODFUN2",;
"P2_CODFUN3","P2_CODFUN4","P5_CODFUNC","P8_CODFUNC","PB_CODFUNC","PC_CODFUNC","PG_CODFUNC","PH_CODFUNC","PI_CODFUNC","PK_CODFUNC",;
"PL_CODFUNC","PN_CODFUNC","PT_CODFUNC","RA_CODFUNC","TJT_CODFUN","TKG_CODFUN","TM0_CODFUN","TMV_CODFUN","TN0_CODFUN","TNB_CODFUN",;
"TNC_CODFUN","TNF_CODFUN","TO5_CODFUN","TOB_CODFUN","TOC_CODFUN","TON_CODFUN","TY4_CODFUN", "AA1_FUNCAO", "ABO_FUNCAO", "DC6_FUNCAO", "DCI_FUNCAO",;
"NT9_CFUNDP", "RAL_FUNCAO", "RB2_FUNCAO", "RB4_FUNCAO", "RB5_FUNCAO", "RB7_FUNCAO", "RBD_FUNCAO", "RBT_FUNCAO", "REL_CODFUN",;
"DB_RHFUNC", "R7_FUNCAO", "TFF_FUNCAO", "TJ1_FUNC", "TJ2_FUNC", "TJ5_FUNC", "RCL_FUNCAO", "REY_CODFUN", "QS_FUNCAO",;
"TMY_NOVFUN", "TWN_FUNCAO", "V7_FUNC", "TYA_CODFUN", "VAI_FUNCAO", "TXI_FUNCAO", "TX8_FUNCAO", "TOA_CODIGO", ;
"TI0_FUNCAO", "TGC_CODFUN", "TAN_CODFUN", "TAK_CODFUN", "RE0_CODFUN"}
Local xN
Local aArqUpd := {}
Local aCpsFun := MdtVldFun()
Local nTamSrj := GetSX3Cache( "RJ_FUNCAO", "X3_TAMANHO" ) // campo default para ajustar as outras tabelas

For xN:=1 To Len(aCpsFun)
	If Ascan(aField, aCpsFun[ xN , 2 ] ) == 0
		aAdd(aField, aCpsFun[ xN , 2 ] )
	Endif
Next nCpsFun

SX3->(DbSetOrder(2)) // X3_CAMPO
For xN:=1 To Len(aField)
	If SX3->(dbseek(Padr(aField[xN],10)))
		If Ascan(aArqUpd, SX3->X3_ARQUIVO ) == 0
			aAdd(aArqUpd, SX3->X3_ARQUIVO )
		Endif
		RecLock("SX3",.F.)
		SX3->X3_TAMANHO := nTamSrj
		If Empty(SX3->X3_F3)
			SX3->X3_F3 := "SRJ"
		Endif
		SX3->( MsUnlock() )
	Endif
Next xN

__SetX31Mode(.F.)
For xN := 1 To Len(aArqUpd)
	Begin Transaction
	ChkFile( aArqUpd[xN],.F. )
	End Transaction
	If Select(aArqUpd[xN]) > 0
		(aArqUpd[xN])->(dbCloseArea())
	EndIf
	DbSelectArea("SX6")
	DropIdxSql( RetSqlName( aArqUpd[xN] ) )
	X31UpdTable(aArqUpd[xN])
	If __GetX31Error()
		grv2txt( "jobrjfuncao.log", "x31updtable error " + aArqUpd[xN] + " Empresa " + cEmpAnt + "  " + Time() )
   else
		grv2txt( "jobrjfuncao.log", "x31updtable ok    " + aArqUpd[xN] + " Empresa " + cEmpAnt + "  " + Time() )
	EndIf
	Begin Transaction
	ChkFile( aArqUpd[xN],.F. )
	End Transaction
	If Select(aArqUpd[xN]) > 0
		(aArqUpd[xN])->(dbCloseArea())
	EndIf
Next xN
VarInfo("jobrjfuncao-aField",aField)
VarInfo("jobrjfuncao-aArqUpd",aArqUpd)

Return Nil


Static Function MdtVldFun()
Local nSX9
Local nTamFun	:= GetSX3Cache( "RJ_FUNCAO", "X3_TAMANHO" )
Local aSX9		:= NGRETSX9( "SRJ" , { "TAF" , "TAK" , "TAN" , "TOA" , "TJ7" , "TGC", "BTS", "SR2" } )
Local aCpsFun	:= {}
Local aArea		:= GetArea()
Local aAreaSX3	:= SX3->( GetArea() )
For nSX9 := 1 To Len( aSX9 )
	If TamSx3(aSX9[ nSX9 , 4 ])[1] <> nTamFun
		aAdd( aCpsFun , { aSX9[ nSX9 , 3 ] , aSX9[ nSX9 , 4 ] } )
	EndIf
Next nSX9
RestArea( aAreaSX3 )
RestArea( aArea )
Return aCpsFun


Static Function DropIdxSql(cTableNAme)
Local cAliasTOP := GetNextAlias()
Local cQuery := ""
If cTableNAme == Nil
	Return
Endif
cQuery += "SELECT 'drop index [' + su.name + '].[' + so.name + '].[' + si.name + ']' as COMMAND " + CRLF
cQuery += "FROM sysindexes si with (nolock) " + CRLF
cQuery += "JOIN sysobjects so with (nolock) ON si.id = so.id " + CRLF
cQuery += "JOIN sysusers su   with (nolock) ON su.uid = so.uid " + CRLF
cQuery += "WHERE INDEXPROPERTY(si.id,si.name, 'IsStatistics') = 0 " + CRLF
cQuery += "AND si.name not like '%_PK' " + CRLF
cQuery += "AND so.name like '"+cTableNAme+"' " + CRLF
cQuery += "AND OBJECTPROPERTY(so.id, 'IsUserTable') = 1 " + CRLF
dbUseArea(.T.,'TOPCONN', TCGenQry(,,cQuery), cAliasTOP,.F.,.T.)
(cAliasTOP)->( DbGoTop() )
Do While ! (cAliasTOP)->(Eof() )
	ConOut((cAliasTOP)->COMMAND)
	TCSqlExec( (cAliasTOP)->COMMAND )
	(cAliasTOP)->( DbSkip() )
EndDo
(cAliasTOP)->(dbCloseArea())
Return


Static Function grv2txt( cArquivo, cTexto )
Local nHdl := 0
If !File(cArquivo)
	nHdl := FCreate(cArquivo)
Else
	nHdl := FOpen(cArquivo, FO_READWRITE)
Endif
FSeek(nHdl,0,FS_END)
cTexto += Chr(13)+Chr(10)
FWrite(nHdl, cTexto, Len(cTexto))
FClose(nHdl)
Return
