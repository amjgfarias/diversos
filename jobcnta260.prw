#INCLUDE "TOTVS.CH"
#INCLUDE "TOPCONN.CH"

Static __Semaforo := GetPathSemaforo()

/*/{Protheus.doc} JobCN260
   @author alessandro@farias.net.br
   @since 19/01/2023
   @updated 22/01/2023
   @costumer Touti Cosmeticos
   @developer Tupi Consultoria
/*/

User Function JobCN260(uParam) // colocar essa funcao no schedule do protheus
StartJob("U_JbCNT260",GetEnvServer(),.F., { "xx", "xx" } )
Return


User Function JbCNT260(uParam)
Local nNUMJOBS := 0
Local nJOBS    := 5 // numero de jobs simultaneos
Local aSM0	   := {}
Local dIData := dtos(date()-1)
Local dFData := dtos(date())
Local aDatas := {}
Local lWait  := .T. // se colocar .F. será multithread
Local nI, nT, ndias, cQuery
Local aEmpresas, aFiliais

nDias  := 0
Do While nDias <= STOD(dFData)-STOD(dIData)
	aadd( aDatas, STOD(dIData)+nDias )
	nDias++
Enddo

RpcClearEnv()

Set Deleted On
SET(_SET_DELETED, .T.)

OpenSM0()

aEmpresas	:= FWAllGrpCompany()
For nT:=1 To Len(aEmpresas)
	// aFiliais := FWAllFilial(/*cCompany*/,/*cUnitBusiness*/,/*cGrpCompany*/,.F./*lOnlyCode*/)
	cQuery := "SELECT CN9_FILIAL FROM CN9040 WHERE D_E_L_E_T_=' ' AND CN9_FILIAL <> '' " + CRLF
	cQuery += "GROUP BY CN9_FILIAL " + CRLF
	cQuery += "ORDER BY CN9_FILIAL " + CRLF
	MPSysOpenQuery( cQuery, "TRBSM0" )
	aFiliais := {}
	Do While ! TRBSM0->( Eof() )
		aAdd(aFiliais,TRBSM0->CN9_FILIAL)
		TRBSM0->( DbSkip() )
	Enddo
	TRBSM0->(DbCloseArea())
	For nI:=1 To Len(aFiliais)
      Aadd(aSM0, { Alltrim(aEmpresas[nT]), Alltrim(aFiliais[nI]) })
	Next nI
Next nT
RpcClearEnv()

OpenSM0()
For nT:=1 To Len(aDatas)
	For nI := 1 To Len(aSM0)
		StartJob("U_RNJCNT26",GetEnvServer(),lWait, { aSM0[nI][1], aSM0[nI][2], aDatas[nT] } )
		nNUMJOBS := VerifJob()
		If nNUMJOBS > nJOBS
			do while .T.
				Sleep( 1000 )	// aguarda 1 segundo
				If VerifJob() < nJOBS
					Exit
				Endif
			enddo
		Endif
	Next nI
Next nT
RpcClearEnv()

do while .T.
	Sleep( 1000 )	// aguarda 1 segundo
	If VerifJob() == 0
		Exit
	Endif
enddo

Return


Static Function VerifJob()
Local aLCKFile := Directory( __Semaforo + 'JBCNT260*.LCK' )
Local I
For I:=1 To Len( aLCKFile )
	FErase( __Semaforo + aLCKFile[I][1] )
Next I
Sleep( 1000 )	// aguarda 1 segundo
Return Len( aLCKFile )


User Function RNJCNT26(aCodigos)
Local lRet
Local nHdl

fErase( __Semaforo + "JBCNT260" + aCodigos[01] + aCodigos[02] + ".LCK" )
nHdl := FCREATE( __Semaforo + "JBCNT260" + aCodigos[01] + aCodigos[02] + ".LCK" )
If nHDL < 0
	Return .F.
EndIf

RpcClearEnv()
RpcSetType(3)
RpcSetEnv(aCodigos[01],aCodigos[02])
cUserName  := 'Administrador'
__cUSerID  := '000000'
__cinternet:= "AUTOMATICO"

SetModulo("SIGAGCT","GCT")
SetFunName("CNTA260")

dDataBase := aCodigos[03]

// lRet :=  CNTA260(cEmpAnt,cFilAnt) // nao usar a chamada -> cnta260
lRet := !CN260Exc(.F.) // se colocar .T. a rotina passa a usar date() ao inves de database.

FClose( nHDL )
fErase( __Semaforo + "JBCNT260" + aCodigos[01] + aCodigos[02] + ".LCK" )
RpcClearEnv()

Return
