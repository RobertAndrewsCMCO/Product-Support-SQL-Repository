If(OBJECT_ID('tempdb..#MSPHDRS0') Is Not Null)
    Begin Drop Table #MSPHDRS0
    End;
    If(OBJECT_ID('tempdb..#MSPSEGS0') Is Not Null)
    Begin Drop Table #MSPSEGS0
    End;
    If(OBJECT_ID('tempdb..#MSPDETL0') Is Not Null)
    Begin Drop Table #MSPDETL0
    End;
    If(OBJECT_ID('tempdb..#MISCCHARGECODES') Is Not Null)
    Begin Drop Table #MISCCHARGECODES
    End;
    If(OBJECT_ID('tempdb..#misccombos') Is Not Null)
    Begin Drop Table #misccombos
    End;
    If(OBJECT_ID('tempdb..#miscxref') Is Not Null)
    Begin Drop Table #miscxref
    End;
    If(OBJECT_ID('tempdb..#LBRCHARGECODES') Is Not Null)
    Begin Drop Table #LBRCHARGECODES
    End;
    If(OBJECT_ID('tempdb..#lbrcombos') Is Not Null)
    Begin Drop Table #lbrcombos
    End;
    If(OBJECT_ID('tempdb..#lbrxref') Is Not Null)
    Begin Drop Table #lbrxref
    End;
    If(OBJECT_ID('tempdb..#MSPDETL02') Is Not Null)
    Begin Drop Table #MSPDETL02
    End;
    If(OBJECT_ID('tempdb..#PARENT') Is Not Null)
    Begin Drop Table #PARENT
    End;
    If(OBJECT_ID('tempdb..#PSSR') Is Not Null)
    Begin Drop Table #PSSR
    End;
    If(OBJECT_ID('tempdb..#VERT') Is Not Null)
    Begin Drop Table #VERT
    End;
    If(OBJECT_ID('tempdb..#CIP') Is Not Null)
    Begin Drop Table #CIP
    End;
    If(OBJECT_ID('tempdb..#wophdrs0') Is Not Null)
    Begin Drop Table #wophdrs0
    End;
	If(OBJECT_ID('tempdb..#LINEITEM') Is Not Null)
    Begin Drop Table #LINEITEM
    End;
	  If(OBJECT_ID('tempdb..#ACTUAL_ROLLUP') Is Not Null)
    Begin Drop Table #ACTUAL_ROLLUP
    End;
	  If(OBJECT_ID('tempdb..#TLSELL_SEG') Is Not Null)
    Begin Drop Table #TLSELL_SEG
    End;
	 If(OBJECT_ID('tempdb..#VARIANCE_SEG') Is Not Null)
    Begin Drop Table #VARIANCE_SEG
    End;
		If(OBJECT_ID('tempdb..#VARIANCE_FLAT_RATE_ALL') Is Not Null)
    Begin Drop Table #VARIANCE_FLAT_RATE_ALL   End;
	If(OBJECT_ID('tempdb..#VARIANCE_PARTS') Is Not Null)
    Begin Drop Table #VARIANCE_PARTS   End;
	If(OBJECT_ID('tempdb..#VARIANCE_LABOR') Is Not Null)
    Begin Drop Table #VARIANCE_LABOR   End;
	If(OBJECT_ID('tempdb..#VARIANCE_MISC') Is Not Null)
    Begin Drop Table #VARIANCE_MISC   End;
	 If(OBJECT_ID('tempdb..#WARRANTY') Is Not Null)
    Begin Drop Table #WARRANTY
    End;
	
	If(OBJECT_ID('tempdb..#SUPPLIES_SELL') Is Not Null)
    Begin Drop Table #SUPPLIES_SELL
    End;
	If(OBJECT_ID('tempdb..#MASTER_DATASET') Is Not Null)
    Begin Drop Table #MASTER_DATASET
    End;
	If(OBJECT_ID('tempdb..#MGR_Region') Is Not Null)
    Begin Drop Table #MGR_Region    End;
	If(OBJECT_ID('tempdb..#CVA_CUST') Is Not Null)
    Begin Drop Table #CVA_CUST    End;
	If(OBJECT_ID('tempdb..#STORES') Is Not Null)
    Begin Drop Table #STORES    End;
	If(OBJECT_ID('tempdb..#CostCenter') Is Not Null)
    Begin Drop Table #CostCenter   End;
	If(OBJECT_ID('tempdb..#Repstackemails') Is Not Null)
    Begin Drop Table #Repstackemails   End;
	If(OBJECT_ID('tempdb..#REVENUE_ACCTS') Is Not Null)
    Begin Drop Table #REVENUE_ACCTS   End;
	
    --Take invoice header detail and attach customer information
	SELECT MSPHDRS0.* into #MSPHDRS0
    FROM DBS.dbo.MSPHDRS0 MSPHDRS0 WITH(NOLOCK)
        join DBS.dbo.cipname0 cipname0 WITH(NOLOCK) on MSPHDRS0.CUNO=cipname0.CUNO
    --WHERE MSPHDRS0.IVDAT8 BETWEEN 20230101 and 20230999
    WHERE CAST(try_convert(date,str(MSPHDRS0.IVDAT8),112) as date) >='2025-08-01'

	
    --Bring in segment-level information
	SELECT MSPSEGS0.*, MCCC, LBCC, PACC 
	into #MSPSEGS0
    FROM DBS.dbo.MSPSEGS0 MSPSEGS0 WITH(NOLOCK) 
        INNER JOIN #MSPHDRS0 on MSPSEGS0.IVNO1=#MSPHDRS0.IVNO1
    WHERE MSPSEGS0.WOOPNO='';

	--Bring in detail-level information 
    SELECT MSPDETL0.*, MCCC, LBCC, PACC,
    case when RCDTP not in('A') then ''
    when sos1 in('750','760','770','780') then 'USED PARTS'
	when  SOS1 in ('600') then 'EXCHANGE PARTS'
    when SOS1 in ('000','020') and left(rtrim(ltrim(cmcd)),1) = '1' then '1-UNDERCARRIAGE'
    when SOS1 in ('000','020') and left(rtrim(ltrim(cmcd)),1) = '2' then '2-ENGINE'
    when SOS1 in ('000','020') and left(rtrim(ltrim(cmcd)),1) = '3' then '3-GROUND ENGAGING TOOLS'
    when SOS1 in ('000','020') and left(rtrim(ltrim(cmcd)),1) = '5' then '5-DRIVE TRAIN AND STEERING PARTS'
    when SOS1 in ('000','020') and left(rtrim(ltrim(cmcd)),1) = '6' then '6-HYDRAULICS'
    when sos1 in ('000','020','100') and left(rtrim(ltrim(cmcd)),1) = '7' then '7-FILTERS AND FLUIDS'
    when SOS1 in ('000','020') and left(rtrim(ltrim(cmcd)),1) = '8' then '8-ELECTRONICS & ELECTRICAL COMPONENTS'
    when (SOS1 in ('000','020') and left(rtrim(ltrim(cmcd)),1) = '9') OR cmcd is null OR left(rtrim(ltrim(cmcd)),1) = '9' or cmcd='' then '9-STRUCTURAL PARTS'
	--when SOS1 in ('000','020') then '9-STRUCTURAL PARTS'
    when sos1 not in('000','020','100','750','760','770','780') then 'ALL OTHER?'
    else'ALL OTHER?'
    End
    as commodity
     into #MSPDETL0
    FROM DBS.dbo.MSPDETL0 MSPDETL0 WITH(NOLOCK) 
        INNER JOIN #MSPSEGS0 on MSPDETL0.IVNO1=#MSPSEGS0.IVNO1 and MSPDETL0.WOSGNO=#MSPSEGS0.WOSGNO

    UPDATE #MSPDETL0 SET CGCD = replace(CGCD, 0x3F, '%') -- UPDATES #MSPDETL0 CGCD

    --Create 
	SELECT CIPNAME0.PRCUNO, parent.cunm PRCUNM, CIPNAME0.CUNO, CIPNAME0.CUNM INTO #PARENT 
    FROM DBS.dbo.CIPNAME0 CIPNAME0 with (nolock)
        LEFT JOIN DBS.dbo.cipname0 parent with (nolock) on cipname0.prcuno=parent.cuno
    -- where CIPNAME0.CUNM like '%KIEWIT%' or parent.cunm like '%KIEWIT%'


    select A.*, B.epidno, C.EmpEmail, Nickname, FirstName, LastName, EmpName, MgrName
    into #repstackemails
    from GDM.dbo.RepAssignments A
    left join DBS.dbo.UMPEPID0 B on a.SLMT=b.SLMT and a.DIVI=b.DIVI and a.slmn=b.SLMN
    left join HR_DataStore.dbo.EmployeeMaster C on B.EPIDNO=C.EmpNum



    /* Charlene PSSR Table
    SELECT cipname0.CUNO, cipname0.CUNM,
        MAX(CASE WHEN REPSTACK.DIVI='C' AND REPSTACK.SLMT='2' THEN REPSTACK.REP ELSE '' END) "MSR",
		--MAX(CASE WHEN EM_MSR.Nickname IS NULL THEN CONCAT(EM_MSR.FirstName,' ', EM_MSR.LastName) ELSE CONCAT(EM_MSR.Nickname, ' ', EM_MSR.LastName) END) EmpName_MSR,
		MAX(CASE WHEN EM_MSR.MgrName IS NOT NULL THEN EM_MSR.MgrName ELSE '' END) MgrName_MSR,

        MAX(CASE WHEN REPSTACK.DIVI='C' AND REPSTACK.SLMT='3' AND REPSTACK.FIELD = 'FIELD 2' THEN REPSTACK.REP ELSE '' END) "PSSR",
		--MAX(CASE WHEN EM_PSSR.Nickname IS NULL THEN CONCAT(EM_PSSR.FirstName,' ', EM_PSSR.LastName) ELSE CONCAT(EM_PSSR.Nickname, ' ', EM_PSSR.LastName) END) EmpName_PSSR,
		MAX(CASE WHEN EM_PSSR.MgrName IS NOT NULL THEN EM_PSSR.MgrName ELSE '' END) MgrName_PSSR
	into #pssr
    FROM DBS.dbo.CIPNAME0 cipname0 WITH (NOLOCK)
        LEFT OUTER JOIN GDM.dbo.RepAssignments REPSTACK WITH(NOLOCK) ON CIPNAME0.CUNO=REPSTACK.CUNO 

		LEFT OUTER JOIN HR_DataStore.dbo.EmployeeMaster EM_PSSR WITH(NOLOCK) ON REPSTACK.REP = CASE WHEN EM_PSSR.Nickname IS NULL THEN CONCAT(EM_PSSR.FirstName,' ', EM_PSSR.LastName) ELSE CONCAT(EM_PSSR.Nickname, ' ', EM_PSSR.LastName) END
																				AND REPSTACK.DIVI = 'C' AND REPSTACK.SLMT = '3'
		LEFT OUTER JOIN HR_DataStore.dbo.EmployeeMaster EM_MSR WITH(NOLOCK) ON REPSTACK.REP = CASE WHEN EM_MSR.Nickname IS NULL THEN CONCAT(EM_MSR.FirstName,' ', EM_MSR.LastName) ELSE CONCAT(EM_MSR.Nickname, ' ', EM_MSR.LastName) END
																				AND REPSTACK.DIVI = 'C' AND REPSTACK.SLMT = '2'
    group by cipname0.CUNO, cipname0.CUNM */

    SELECT cuno, cunm, 
        isnull((select top 1 rep from #repstackemails E1 where C.cuno=E1.CUNO and slmt='2' and divi='C' order by rep desc),'') as MSR,
        isnull((select top 1 EmpEmail from #repstackemails E1 where C.cuno=E1.CUNO and slmt='2' and divi='C' order by rep desc),'') as MSR_Email,
        isnull((select top 1 MgrName from #repstackemails E1 where C.cuno=E1.CUNO and slmt='2' and divi='C' order by rep desc),'') as MgrName_MSR,
        isnull((select top 1 rep from #repstackemails E1 where C.cuno=E1.CUNO and slmt='3' and FIELD='FIELD 2' and divi='C' order by rep desc),'') as PSSR,
        isnull((select top 1 EmpEmail from #repstackemails E1 where C.cuno=E1.CUNO and slmt='3' and FIELD='FIELD 2' and divi='C' order by rep desc),'') as PSSR_Email,
        isnull((select top 1 MgrName from #repstackemails E1 where C.cuno=E1.CUNO and slmt='3' and FIELD='FIELD 2' and divi='C' order by rep desc),'') as MgrName_PSSR
    
    into #pssr
    from DBS.dbo.CIPNAME0 C








/*SET Region By Manager*/
	SELECT CASE WHEN #PSSR.MgrName_PSSR = 'WILLIAM HELTZEL' THEN 'Coal Fields'
				 WHEN #PSSR.MgrName_PSSR = 'MATTHEW COCOWITCH' THEN 'Western CI'
				 WHEN #PSSR.MgrName_PSSR = 'TIMOTHY MCCAULEY' AND #PSSR.PSSR = 'SAM STALLARD' THEN 'SAM'
				 WHEN #PSSR.MgrName_PSSR = 'JOSHUA MARTIN' THEN 'EAST'
                 WHEN #PSSR.MgrName_PSSR = 'THAREN PETERSON' THEN 'MD-DEL'
				 WHEN #PSSR.MgrName_PSSR = 'BRADLEY SHEPPARD' THEN 'NOVA'
			ELSE 'Other'
			END AS Region,#PSSR.MgrName_PSSR
	into #MGR_Region
	FROM #PSSR

    /** vertical industry by customer **/
    select scpdivf0.CUNO, scpdivf0.DIVI, SCPDIVF0.idcd01 "Industry Code", SCPCODE0i.ds4 "Industry", left(SCPCODE0i.ds4,2) "L2 - Industry",
    case when left(SCPCODE0i.ds4,2) in ('AG', 'EQ', 'FY', 'GV', 'IM', 'LG', 'LL', 'PL', 'QA', 'WA') then 'CI - Construction Industries'
        when left(SCPCODE0i.ds4,2) = ('MN') then 'RI - Resource Industries'
        when left(SCPCODE0i.ds4,2) in ('EP', 'CS', 'IN', 'MA', 'PE', 'ST', 'ST') then 'E&T - Energy & Transportation'
    end as "CAT Industry Vertical"
    INTO #VERT
    from DBS.DBO.scpdivf0 scpdivf0  WITH(NOLOCK)
        LEFT JOIN DBS.DBO.SCPCODE0 SCPCODE0i  WITH(NOLOCK)  ON scpdivf0.idcd01=SCPCODE0i.keyda1 AND 'D'=SCPCODE0i.rcdcd -- D=industry

    /** CIP **/
    select CIPNAME0.cuno, CIPNAME0.cunm, CIPNAME0.divi, CIPNAME0.IVTYPI
    into #CIP
    from DBS.dbo.CIPNAME0 CIPNAME0 with (nolock)

    /** wophdrs0 **/
    SELECT wophdrs0.* into #wophdrs0
    FROM DBS.dbo.wophdrs0 wophdrs0 WITH(NOLOCK)
    WHERE CAST(try_convert(date,str(wophdrs0.IVDT8),112) as date) >='2025-08-01'

	
	SELECT   CUNO, CUNM, IVTYPI 
	INTO #CVA_CUST
	FROM      DBS.dbo.cipname0                         
	WHERE    etyc IN                          
		(SELECT   entcd6                       
			FROM      DBS.dbo.fnpecac0                     
			WHERE    LEFT(acctnu,5) IN ('21092','21090') )

	SELECT F.ENTCD6
	INTO #REVENUE_ACCTS
	FROM DBS.DBO.FNPECAC0 F WHERE LEFT(ACCTNU,2) IN ('42','43')
	GROUP BY F.ENTCD6

	SELECT  RTRIM(LTRIM(A."STNO")) as "StoreNumber", A.STORE AS "StoreName"
	INTO #STORES
    FROM   GDM.dbo.Stores_Consolidated A WITH(NOLOCK)

	SELECT RTRIM(LTRIM([CSCC])) AS CSCC,[COST CENTER]
	INTO #CostCenter
    FROM GDM.dbo.Service_CostCenter C WITH(NOLOCK)

	/** LINE ITEM PULL**/
	SELECT H.IVDAT8, H.IVNO1, H.RFDCNO, H.RESPAR, H.CUNO, H.DIVI, H.SLSREP, H.SLMN, S.WOSGNO, D.RCDTP,D.STN1,D.CGCD,D.CMCD, D.CSCC, D.BECTYC, D.SOS1,D.ACCTNO,D.LNNO5P, D.LNNOSX, --THIS IS WHERE WE ADD PART NUMBER
			ROUND(CASE WHEN D.RCDTP = 'A' THEN 
									(CASE WHEN ivtyp in('P','C') then 1 when hdsgii in('H','S') then 1 when ptdolp>1 then 0 else ptdolp END * (UNSEL-abs(adjamt))*qty5 )
				WHEN D.RCDTP  IN ('B','T')	THEN 
									CASE WHEN hdsgii in('H','S') then 1 when lbdolp>1 then 0 ELSE lbdolp END  * (UNSEL-abs(adjamt))*qty5 
				WHEN D.RCDTP IN ('C','V') THEN 
									case when ivtyp in('C','P') then 1 when hdsgii in('H','S') then 1 when rcdtp='V' then 1 
										 when D.CGCD in ('%S6', '%P6') and msdolp<>0 and msdolp<=1 then 1 when msdolp>1 then 0 else msdolp END * (UNSEL-abs(adjamt))*qty5
		   END,2) AS NET_SELL_AMT,
		  
		  
		   ROUND(CASE WHEN D.RCDTP = 'A' THEN 
									CASE WHEN ivtyp in('P','C') then 1 when hdsgii in('H','S') then 1 when ptdolp>1 then 0 else ptdolp END * UNCS*qty5 
				WHEN D.RCDTP  IN ('B','T')	THEN 
									CASE WHEN hdsgii in('H','S') then 1 when lbdolp>1 then 0 ELSE lbdolp END * UNCS*qty5 
				WHEN D.RCDTP IN ('C','V') THEN 
									case when ivtyp in('C','P') then 1 when hdsgii in('H','S') then 1 when rcdtp='V' then 1 
										 when D.CGCD in ('%S6', '%P6') and msdolp<>0 and msdolp<=1 then 1 when msdolp>1 then 0 else msdolp END * UNCS*qty5 
		   END,2) AS DEALER_NET,
		   D.commodity
	INTO #LINEITEM 
	FROM #MSPHDRS0 H 
	JOIN #MSPSEGS0 S ON H.IVNO1 = S.IVNO1 
	JOIN #MSPDETL0 D ON S.IVNO1 = D.IVNO1 AND S.WOSGNO = D.WOSGNO
	WHERE S.WOOPNO = ''																		--If you not look for blank you could duplicate counts because of operations

	/**ROLL ACTUALS UP TO SEGMENT LEVEL PARTS AND MISC **/
		SELECT H.IVDAT8, H.IVNO1, H.RFDCNO, H.CUNO, S.WOSGNO,S.STN1, S.CSCC,   --THIS IS WHERE WE ADD PART NUMBER
		   ROUND(SUM(CASE WHEN D.RCDTP = 'A' THEN   -- PARTS
									CASE WHEN ivtyp in('P','C') then 1 when hdsgii in('H','S') then 1 when ptdolp>1 then 0 else ptdolp END * (UNSEL-abs(adjamt))*qty5 END),2) AS SUM_PARTS, 
			ROUND(SUM(CASE WHEN D.RCDTP  IN ('B','T')	THEN   --LABOR and TRAVEL
									CASE WHEN hdsgii in('H','S') then 1 when lbdolp>1 then 0 ELSE lbdolp END  * (UNSEL-abs(adjamt))*qty5 END ),2) AS SUM_LABOR,
			ROUND(SUM(CASE WHEN D.RCDTP IN ('C','V') THEN  --MISC
									case when ivtyp in('C','P') then 1 when hdsgii in('H','S') then 1 when rcdtp='V' then 1 
										 when D.CGCD in ('%S6', '%P6') and msdolp<>0 and msdolp<=1 then 1 when msdolp>1 then 0 else msdolp END * (UNSEL-abs(adjamt))*qty5 END),2) AS SUM_MISC,
		  ROUND(SUM( CASE WHEN D.RCDTP = 'A' THEN 
									CASE WHEN ivtyp in('P','C') then 1 when hdsgii in('H','S') then 1 when ptdolp>1 then 0 else ptdolp END * UNCS*qty5  END),2) AS SUM_PARTS_DLR_NET,
		  ROUND(SUM(CASE	WHEN D.RCDTP  IN ('B','T')	THEN 
									CASE WHEN hdsgii in('H','S') then 1 when lbdolp>1 then 0 ELSE lbdolp END * UNCS*qty5 END),2) AS SUM_LABOR_DLR_NET,
		  ROUND(SUM(CASE WHEN D.RCDTP IN ('C','V') THEN  
									case when ivtyp in('C','P') then 1 when hdsgii in('H','S') then 1 when rcdtp='V' then 1 
										 when D.CGCD in ('%S6', '%P6') and msdolp<>0 and msdolp<=1 then 1 when msdolp>1 then 0 else msdolp END * UNCS*qty5 END),2) AS SUM_MISC_DLR_NET
	INTO #ACTUAL_ROLLUP
	FROM #MSPHDRS0 H 
	LEFT JOIN #MSPSEGS0 S ON H.IVNO1 = S.IVNO1 
	LEFT JOIN #MSPDETL0 D ON S.IVNO1 = D.IVNO1 AND S.WOSGNO = D.WOSGNO
	WHERE S.WOOPNO = '' AND D.RCDTP IN ('A','C','V','B','T')     --NOTES FOR CHARLENE: RCDTP A is PARTS, RCDTYP B is Labor, RCDTYP T is Travel/Warrenty(Labor), RCDTYP C is MISC, RCDTYP V is zone charges(misc)
	GROUP BY H.IVDAT8, H.IVNO1, H.RFDCNO, H.CUNO, S.WOSGNO, S.STN1, S.CSCC
	
	
	---H.IVDAT8, H.IVNO1, H.RFDCNO, H.CUNO, H.DIVI,S.WOSGNO, D.RCDTP,D.STN1,D.CGCD,D.CMCD, D.CSCC, D.BECTYC, D.SOS1,D.ACCTNO,D.LNNO5P, D.LNNOSX,NET_SELL_AMT,DEALER_NET,Commodity
	SELECT H.IVNO1, S.WOSGNO, SUM(ROUND(UNSEL * QTY5,2)) AS SUM_SUPPLIES_SELL,SUM( ROUND(UNCS*QTY5,2)) AS SUM_SUPP_DLR_NET
	INTO #SUPPLIES_SELL
	FROM #MSPHDRS0 H 
	JOIN #MSPSEGS0 S ON H.IVNO1 = S.IVNO1 
	JOIN #MSPDETL0 D ON S.IVNO1 = D.IVNO1 AND S.WOSGNO = D.WOSGNO 
	WHERE D.CGCD IN ('%S6', '%P6')  and MSDOLP>0 and MSDOLP<=1
	GROUP BY H.IVNO1, S.WOSGNO

	/**BILLED CUSTOMER**/
	SELECT  H.IVDAT8, H.IVNO1, H.RFDCNO, H.RESPAR, H.CUNO, H.DIVI,H.SLSREP, H.SLMN, S.WOSGNO,S.STN1, S.CSCC, S.FARATE, S.PARATE, S.LBRATE,S.MCRATE, --TLSELL is total SELL
		CASE WHEN H.IVTYP IN ('P','C') THEN S.LBDAMT + S.PADAMT + S.MCDAMT ELSE TLSELL - S.IQWALD END  AS TLSELL, 
		CASE WHEN H.ivtyp in('P','C') then 1 when ptdolp>1 then 0 else ptdolp END * S.PAAMT AS PRTS_AMT, 
		CASE WHEN H.ivtyp in('P','C') then 1 when LBDOLP>1 then 0 else LBDOLP END * S.LBAMT AS LABOR_AMT,
		CASE WHEN H.ivtyp in('P','C') then 1 when MSDOLP>1 then 0 else MSDOLP END * S.MCAMT AS MISC_AMT, 
		S.IQWALD
	INTO #TLSELL_SEG
	FROM #MSPHDRS0 H 
	LEFT JOIN #MSPSEGS0 S ON H.IVNO1 = S.IVNO1 

	/**CALCULATE VARIANCE**/
	SELECT T.IVDAT8, T.IVNO1, T.RFDCNO, T.RESPAR, T.CUNO, T.DIVI,T.SLSREP, T.SLMN, T.WOSGNO, '' AS RCDTP,T.STN1, '' AS CGCD,'' AS CMCD,T.CSCC, '' AS BECTYC,'' AS SOS1,'' AS ACCTNO,
	0 AS LNNO5P,0 AS LNN0SX, T.TLSELL - ISNULL(A.SUM_PARTS,0) - ISNULL(A.SUM_LABOR,0) - ISNULL(A.SUM_MISC,0)  AS SUM_NET_SELL_AMT, 0 AS SUM_DEALER_NET, '' AS COMMODITY
	INTO #VARIANCE_FLAT_RATE_ALL
	FROM #TLSELL_SEG T
	LEFT JOIN #ACTUAL_ROLLUP A ON T.IVNO1 = A.IVNO1 AND T.WOSGNO = A.WOSGNO
	WHERE T.TLSELL - ISNULL(A.SUM_PARTS,0) - ISNULL(A.SUM_LABOR,0) - ISNULL(A.SUM_MISC,0) <> 0 AND FARATE = 'F'

	SELECT T.IVDAT8, T.IVNO1, T.RFDCNO, T.RESPAR, T.CUNO, T.DIVI,T.SLSREP, T.SLMN, T.WOSGNO, '' AS RCDTP,T.STN1, '' AS CGCD,'' AS CMCD,T.CSCC, '' AS BECTYC,'' AS SOS1,'' AS ACCTNO,
	0 AS LNNO5P,0 AS LNN0SX, ROUND(T.PRTS_AMT - ISNULL(A.SUM_PARTS,0),2) AS SUM_NET_PART_AMT, 0 AS SUM_DEALER_NET, '' AS COMMODITY
	INTO #VARIANCE_PARTS
	FROM #TLSELL_SEG T
	LEFT JOIN #ACTUAL_ROLLUP A ON T.IVNO1 = A.IVNO1 AND T.WOSGNO = A.WOSGNO
	WHERE T.PRTS_AMT - ISNULL(A.SUM_PARTS,0) <> 0 AND FARATE <> 'F' and PARATE = 'F'

	SELECT T.IVDAT8, T.IVNO1, T.RFDCNO, T.RESPAR, T.CUNO, T.DIVI,T.SLSREP, T.SLMN, T.WOSGNO, '' AS RCDTP,T.STN1, '' AS CGCD,'' AS CMCD,T.CSCC, '' AS BECTYC,'' AS SOS1,'' AS ACCTNO,
	0 AS LNNO5P,0 AS LNN0SX, T.LABOR_AMT - ISNULL(A.SUM_LABOR,0) AS SUM_NET_LABOR_AMT, 0 AS SUM_DEALER_NET, '' AS COMMODITY
	INTO #VARIANCE_LABOR
	FROM #TLSELL_SEG T
	LEFT JOIN #ACTUAL_ROLLUP A ON T.IVNO1 = A.IVNO1 AND T.WOSGNO = A.WOSGNO
	WHERE T.LABOR_AMT - ISNULL(A.SUM_LABOR,0) <> 0 AND FARATE <> 'F' and LBRATE = 'F'

	SELECT T.IVDAT8, T.IVNO1, T.RFDCNO, T.RESPAR, T.CUNO, T.DIVI,T.SLSREP, T.SLMN, T.WOSGNO, '' AS RCDTP,T.STN1, '' AS CGCD,'' AS CMCD,T.CSCC, '' AS BECTYC,'' AS SOS1,'' AS ACCTNO,
	0 AS LNNO5P,0 AS LNN0SX, (T.MISC_AMT + ISNULL(SS.SUM_SUPPLIES_SELL,0)) - ISNULL(A.SUM_MISC,0) AS SUM_NET_MISC_AMT, 0 AS SUM_DEALER_NET, '' AS COMMODITY
	INTO #VARIANCE_MISC
	FROM #TLSELL_SEG T
	LEFT JOIN #ACTUAL_ROLLUP A ON T.IVNO1 = A.IVNO1 AND T.WOSGNO = A.WOSGNO
	LEFT JOIN #SUPPLIES_SELL SS ON T.IVNO1 = SS.IVNO1 AND T.WOSGNO = SS.WOSGNO
	WHERE (T.MISC_AMT + ISNULL(SS.SUM_SUPPLIES_SELL,0)) - ISNULL(A.SUM_MISC,0) <> 0 AND FARATE <> 'F' and MCRATE = 'F'

	SELECT T.IVDAT8, T.IVNO1, T.RFDCNO, T.RESPAR, T.CUNO, T.DIVI,T.SLSREP, T.SLMN, T.WOSGNO, '' AS RCDTP,T.STN1, '' AS CGCD,'' AS CMCD,T.CSCC, '' AS BECTYC,'' AS SOS1,'' AS ACCTNO,
	0 AS LNNO5P,0 AS LNN0SX, T.IQWALD AS SUM_NET_MISC_AMT, 0 AS SUM_DEALER_NET, '' AS COMMODITY
	INTO #WARRANTY
	FROM #TLSELL_SEG T	
	LEFT JOIN #ACTUAL_ROLLUP A ON T.IVNO1 = A.IVNO1 AND T.WOSGNO = A.WOSGNO
	WHERE T.IQWALD <> 0

	---H.IVDAT8, H.IVNO1, H.RFDCNO, H.CUNO, H.DIVI,S.WOSGNO, D.RCDTP,D.STN1,D.CGCD,D.CMCD, D.CSCC, D.BECTYC, D.SOS1,D.ACCTNO,D.LNNO5P, D.LNNOSX,NET_SELL_AMT,DEALER_NET,Commodity
	SELECT A.*, case when A.cuno in(select cuno from #CVA_CUST) then W.cuno else A.cuno end as Usercuno 
	INTO #MASTER_DATASET
	FROM
	(SELECT *,CASE WHEN RCDTP = 'A' THEN 'PARTS' WHEN RCDTP IN ('B','T') THEN 'LABOR' WHEN RCDTP IN ('C', 'V') THEN 'MISC' ELSE '' END AS TYPE  FROM #LINEITEM
	UNION ALL
    SELECT *, 'VAR_FR' AS TYPE FROM #VARIANCE_FLAT_RATE_ALL
	UNION ALL
	SELECT *, 'VAR_PARTS' AS TYPE FROM #VARIANCE_PARTS
	UNION ALL
	SELECT *, 'VAR_LABOR' AS TYPE FROM #VARIANCE_LABOR
	UNION ALL
	SELECT *, 'VAR_MISC' AS TYPE FROM #VARIANCE_MISC
	UNION ALL
	SELECT *, 'WARRANTY' AS TYPE FROM #WARRANTY) A
    left join #wophdrs0 W on A.RFDCNO=WONO




	SELECT TRY_CONVERT(date, CAST(M.IVDAT8 AS CHAR(8)), 112) 
		IVDAT8, 
		M.IVNO1, 
		M.RESPAR,
		M.RFDCNO, 
		M.CUNO, 
		M.DIVI,
		M.SLSREP,
		M.SLMN, --added sales repno
		M.WOSGNO, 
		M.RCDTP,
		M.STN1,
		M.CSCC,
		M.BECTYC,M.SOS1,M.Commodity,M.ACCTNO,--M.LNNO5P,M.LNNOSX,
		M.NET_SELL_AMT,M.DEALER_NET,M.TYPE,
		CASE WHEN M.CGCD IN ('LDA','LDC','PDA','FY1', 'M5U', 'M6T', 'MF4', 'MFT', 'PFF', 'PFI', 'PFO', 'PFY', 'SFI', 'SFT') THEN M.CGCD ELSE '' END CGCD,
		USERCUNO,
		P.CUNM AS USERCUNM,
		case when (P.PRCUNO = '' or P.PRCUNO is null) then P.CUNO else P.PRCUNO end USERPCUNO,
		 case when (P.PRCUNM = '' or P.PRCUNM is null) then P.CUNM else P.PRCUNM end USERPCUNM,
		PSSR.PSSR,
		PSSR.MgrName_PSSR,
        pssr.PSSR_Email
        MSR_Email,
		VERT.[CAT Industry Vertical],
		VERT.[Industry],
		S.StoreName,
		C.[COST CENTER],
		Cust.IVTYPI,
		CASE WHEN R.ENTCD6 IS NOT NULL THEN 'Revenue' 
		     WHEN M.TYPE IN ('VAR_FR' ,'VAR_PARTS' ,'VAR_LABOR' , 'VAR_MISC' , 'WARRANTY') THEN 'Revenue' 
			 ELSE 'Expense' END "Rev Exp Type"
	FROM #MASTER_DATASET M
	LEFT JOIN #PARENT P ON Usercuno = P.CUNO
	left join #PSSR PSSR ON M.CUNO=PSSR.CUNO
    left join #VERT VERT ON M.CUNO=VERT.CUNO and M.DIVI=VERT.DIVI
	LEFT JOIN #STORES S ON S.StoreNumber=M.STN1
    LEFT JOIN #REVENUE_ACCTS R ON R.ENTCD6 = M.ACCTNO  --JOIN on entry code to find revenue vs expense
	LEFT JOIN #CostCenter C ON M.CSCC = C.CSCC
	JOIN #CIP Cust ON Usercuno = Cust.CUNO
