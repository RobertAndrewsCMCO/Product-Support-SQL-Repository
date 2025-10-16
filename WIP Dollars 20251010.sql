SELECT 
Detail.region,
-- Detail.region2,
Detail.vertical,
Detail.repno,
Detail.pssr,
Detail.store,
Detail.[CostCenterCode],
        Detail.[CostCenter],
        Detail.[Service Type],
            Detail.wono,
            Detail.[WonoLink],
            Detail.CustomerNumber,
            Detail.customer,
            Detail.equipment_model,
            Detail.open_date,
            Detail.[projected close (BMTS)],
            Detail.[service type],  -- added 07.29.24
       Detail.parts AS parts,
       Detail.labor AS labor,
       Detail.misc AS misc,
       Detail.parts + Detail.labor + Detail.misc AS total -- combined total

FROM (
    
    SELECT WORKO.WONO AS wono,
    WORKO.CUNO [CustomerNumber],
    CONCAT('https://d10.cartermachinery.com/cgi-bin/wosnap.mac/showwo?frmWO=',TRIM(WORKO.WONO)) AS [WonoLink], 
    Store.STORE [store],
    CASE
        WHEN SCPDIVF0.IDCD01 IN ('510','511','520') THEN 'RI'
        WHEN SCPDIVF0.IDCD01 IN ('130',	'132',	'150',	'155',	'220',	'280',	'316',	'321',	'322',	'440',	'730',	'801',	'803',	'804',	'805',	'850',	'901',
            '330',	'392',	'791',	'792',	'281',	'282',	'283',	'284',	'286',	'241',	'251',	'319',	'317',	'205',	'356',	'415',	'331',
            '333',	'110',	'200',	'240',	'250',	'255',	'270',	'320',	'405',	'601',	'530',	'800',	'902',	'903',	'904') THEN 'CI'
        WHEN SCPDIVF0.IDCD01 IN ('310',	'351',	'353',	'370',	'374',	'811',	'820',	'001',	'002',	'790',	'332',	'381',	'382',	'383',	'384',	'385',	'386',	'387',	'610',
            '611',	'612',	'613',	'614',	'615',	'616',	'617',	'618',	'812',	'813',	'814',	'375',	'376',	'377',	'378',	'379',	'357',	'358',	'359',	'711',	'352',
            '712',	'361',	'334',	'340',	'350',	'355',	'360',	'710',	'740',	'380',	'388',	'389',	'391',	'393',	'394',	'395',	'396',	'397',	'399',	'441',	'442',
            '443',	'444',	'400') THEN'E&T'
        ELSE 'UNKN'
        END AS vertical,
          WORKO.CUNM AS customer,
          WORKO.EQMFMD AS equipment_model,
          WORKO.OPNDT8 AS open_date,
          LEFT(USPWOSS0_Open.SS1NOTE, 8) AS [projected close (BMTS)],
          SCPDIVF0.CUNO AS cuno,
          SCPSMFM0.SLMN AS repno,
           CASE 
            WHEN WORKO.RESPAR = 'MR' AND SCPSMFM0.SLMNM IS NULL Then 'TIM MCCAULEY' -- Place Holder
            WHEN SCPSMFM0.SLMNM = 'STEVE JONES' THEN 'SCOTTIE MAGGARD' --place holder for Steve Jones Exit; Maggard entry 01.13 
            ELSE SCPSMFM0.SLMNM 
            END AS pssr,
        CASE WHEN REPSTACK.REP LIKE 'GB%' THEN '03325' ELSE EM_PSSR.MgrNum END [ManagerNum]
        ,CASE WHEN REPSTACK.REP LIKE 'GB%' AND EM_PSSR.MgrName = '' THEN 'BRADLEY SHEPPARD' ELSE EM_PSSR.MgrName END [ManagerName]
        ,CASE WHEN EM_PSSR.MgrName = 'MICHAEL ESTEP' THEN 'WEST RI'
		 WHEN EM_PSSR.MgrName = 'MATTHEW COCOWITCH' THEN 'WEST CI'
		 WHEN EM_PSSR.MgrName = 'THAREN PETERSON' THEN 'MD-DEL'
		 WHEN EM_PSSR.MgrName = 'JOSHUA MARTIN' THEN 'EAST'
		 WHEN EM_PSSR.MgrName = 'BRADLEY SHEPPARD' OR REPSTACK.REP = 'GB CRITZER' THEN 'NOVA'
         WHEN EM_PSSR.MgrName = 'TIMOTHY MCCAULEY' AND REPSTACK.REP = 'SAM STALLARD' THEN 'SAM'
         WHEN EM_PSSR.MgrName = 'STEVEN ANDERSON' THEN 'CSR-ISR'
        ELSE 'Other'
        END AS region,
        CostCenter.[CSCC] [CostCenterCode],
        CostCenter.[COST CENTER] [CostCenter],
        case when WORKO.[RESPAR] = 'MR' Then 'Rebuild'
          Else 'Break-Fix'
        END AS [service type],
           -- Aggregate totals
           SUM(CASE WHEN wopsegs0.frvarn > '' THEN wopsegs0.wippas ELSE 
                    CASE WHEN wopsegs0.parate = 'F' THEN wopsegs0.paamt ELSE wopsegs0.wippas END
               END) AS parts,
           SUM(CASE WHEN wopsegs0.frvarn > '' THEN wopsegs0.framt - wopsegs0.wippas - wopsegs0.wipmcs ELSE
                    CASE WHEN wopsegs0.lbrate = 'F' THEN wopsegs0.lbamt ELSE wopsegs0.wiplbs END
               END) AS labor,
           SUM(CASE WHEN wopsegs0.frvarn > '' THEN wopsegs0.wipmcs ELSE
                    CASE WHEN wopsegs0.mcrate = 'F' THEN wopsegs0.mcamt ELSE wopsegs0.wipmcs END
               END) AS misc
          ,CASE  
            WHEN WOPSEGS0.[CSCC] ='51' THEN '51 - Shop Labor'
            WHEN WOPSEGS0.[CSCC] = '61' THEN '61 - Field Labor'
            WHEN WOPSEGS0.[CSCC] = '94' THEN '94 - PM'
            ELSE 'Other'
          END AS [cost center]
    
    FROM [DBS].[dbo].[WOPHDRS0_Open] WORKO with(NOLOCK)
    LEFT JOIN [DBS].[dbo].[WOPSEGS0_Open] WOPSEGS0 with(NOLOCK) ON WORKO.WONO = WOPSEGS0.WONO
    -- Join Cost Center Listing
    LEFT JOIN [GDM].dbo.[Service_CostCenter] CostCenter with(NOLOCK) ON WOPSEGS0.CSCC = CostCenter.CSCC AND CostCenter.REGION = 'South'
    LEFT JOIN GDM.dbo.RepAssignments REPSTACK WITH(NOLOCK) ON WORKO.CUNO=REPSTACK.CUNO AND REPSTACK.DIVI = 'C'
    LEFT OUTER JOIN HR_DataStore.dbo.EmployeeMaster EM_PSSR WITH(NOLOCK) 
            ON REPSTACK.REP = CASE WHEN EM_PSSR.Nickname IS NULL THEN CONCAT(EM_PSSR.FirstName,' ', EM_PSSR.LastName) 
                                WHEN EM_PSSR.Nickname IS NOT NULL AND EM_PSSR.Nickname = 'JACK' THEN CONCAT(EM_PSSR.FirstName,' ', EM_PSSR.LastName)
                                ELSE CONCAT(EM_PSSR.Nickname, ' ', EM_PSSR.LastName) END
            AND REPSTACK.DIVI = 'C' AND REPSTACK.SLMT = '3' 
    LEFT JOIN [GDM].dbo.[Store] Store ON WORKO.[STNO] = Store.STNO AND Store.REGION = 'SOUTH'
    LEFT JOIN [DBS].[dbo].[SCPDIVF0] SCPDIVF0 with(NOLOCK) ON SCPDIVF0.DIVI = WORKO.DIVI AND SCPDIVF0.CUNO = WORKO.CUNO
    LEFT JOIN [DBS].[dbo].[SCPSMFM0] SCPSMFM0 with(NOLOCK) ON SCPDIVF0.DIVI = SCPSMFM0.DIVI AND SCPDIVF0.SLMT02 = SCPSMFM0.SLMT AND SCPDIVF0.SLMN02 = SCPSMFM0.SLMN
    LEFT JOIN [BMTS].[dbo].[USPWOSS0_Open] USPWOSS0_Open with(NOLOCK) ON WORKO.WONO = USPWOSS0_Open.[WONO] -- Connects DBS info to BMTS info using work order number
    --LEFT JOIN [BMTS].[dbo].[[BMTS].[dbo].[USPWOSS0_Open]] USPSTXX0 ON USPSTWO0.[STWO_ST] = USPSTXX0.[TICKETID] -- ...connects DBS to BMTS to BMTS work order details using service ticket number
    
    WHERE WORKO.OPNDT8 > '20240101' AND USPWOSS0_Open.SS1NOTE IS NOT NULL AND LEFT(USPWOSS0_Open.SS1NOTE, 8) BETWEEN '20240101' AND '20251231'
      AND WORKO.DIVI IN ('C', 'H', 'U', 'R', 'B')
      AND CASE WHEN EM_PSSR.MgrName = 'MICHAEL ESTEP' THEN 'WEST RI'
		 WHEN EM_PSSR.MgrName = 'MATTHEW COCOWITCH' THEN 'WEST CI'
		 WHEN EM_PSSR.MgrName = 'THAREN PETERSON'  THEN 'MD-DEL' 
		 WHEN EM_PSSR.MgrName = 'JOSHUA MARTIN' THEN 'EAST'
		 WHEN EM_PSSR.MgrName = 'BRADLEY SHEPPARD' OR REPSTACK.REP = 'GB CRITZER' THEN 'NOVA'
         WHEN EM_PSSR.MgrName = 'TIMOTHY MCCAULEY' AND REPSTACK.REP = 'SAM STALLARD' THEN 'SAM'
         WHEN EM_PSSR.MgrName = 'STEVEN ANDERSON' THEN 'CSR-ISR'
        ELSE 'Other'
        END <> 'Other'  
      AND WOPSEGS0.WARCLI <> 'Y'
      AND CASE
        WHEN SCPDIVF0.IDCD01 IN ('510','511','520') THEN 'RI'
        WHEN SCPDIVF0.IDCD01 IN ('130',	'132',	'150',	'155',	'220',	'280',	'316',	'321',	'322',	'440',	'730',	'801',	'803',	'804',	'805',	'850',	'901',
            '330',	'392',	'791',	'792',	'281',	'282',	'283',	'284',	'286',	'241',	'251',	'319',	'317',	'205',	'356',	'415',	'331',
            '333',	'110',	'200',	'240',	'250',	'255',	'270',	'320',	'405',	'601',	'530',	'800',	'902',	'903',	'904') THEN 'CI'
        WHEN SCPDIVF0.IDCD01 IN ('310',	'351',	'353',	'370',	'374',	'811',	'820',	'001',	'002',	'790',	'332',	'381',	'382',	'383',	'384',	'385',	'386',	'387',	'610',
            '611',	'612',	'613',	'614',	'615',	'616',	'617',	'618',	'812',	'813',	'814',	'375',	'376',	'377',	'378',	'379',	'357',	'358',	'359',	'711',	'352',
            '712',	'361',	'334',	'340',	'350',	'355',	'360',	'710',	'740',	'380',	'388',	'389',	'391',	'393',	'394',	'395',	'396',	'397',	'399',	'441',	'442',
            '443',	'444',	'400') THEN 'E&T'
        ELSE 'UNKN'
        END <> 'E&T'
--   and case when WORKO.[RESPAR] = 'MR' Then 'Rebuild'
--           Else 'Break-Fix'
--         END = 'Rebuild'
   GROUP BY WORKO.WONO,
             WORKO.CUNM,
             WORKO.[STNO],
             WORKO.EQMFMD,
             WORKO.OPNDT8,
             USPWOSS0_Open.SS1NOTE,
             SCPDIVF0.CUNO,
             SCPSMFM0.SLMN,
             SCPSMFM0.SLMNM,
             WOPSEGS0.[CSCC],
             WORKO.[RESPAR],
             SCPDIVF0.IDCD01,
             WORKO.CUNO,
             REPSTACK.REP,
            EM_PSSR.MgrNum,
            EM_PSSR.MgrName,
            Store.STORE,
            CostCenter.[CSCC],
        CostCenter.[COST CENTER]

) AS Detail

-- WHERE Detail.wono = 'RI93527'; isolate to one work order for testing/validation

GROUP BY 
Detail.region,
Detail.vertical,
Detail.repno,
Detail.pssr,
Detail.wono,
Detail.customer,
Detail.equipment_model,
  Detail.open_date,
    Detail.[projected close (BMTS)],
  Detail.[service type],
Detail.parts,
Detail.labor,
Detail.misc,
Detail.[cost center],
Detail.[WonoLink],
Detail.CustomerNumber,
Detail.store,
Detail.[CostCenterCode],
Detail.[CostCenter]