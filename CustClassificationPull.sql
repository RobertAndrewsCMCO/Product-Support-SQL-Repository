SELECT c.CUNO [CustomerNumber],c.CUNM [Customer]
, CASE WHEN class.[CUSTOMER NUMBER] IS NULL THEN olga.[Customer Segment Level 1] else class.[CUSTOMER SEGMENT LEVEL 1] end as "Cust Seg Level1"
, CASE WHEN class.[CUSTOMER NUMBER] IS NULL THEN olga.[Customer Segment Level 2] else class.[CUSTOMER SEGMENT LEVEL 2] end as "Cust Seg Level2"
, CASE WHEN class.[CUSTOMER NUMBER] IS NULL THEN 'OLGA Equip' else 'Insight STU' end as "SOURCE"
FROM DBS.DBO.CIPNAME0 c with(nolock)
LEFT JOIN (
			SELECT
				   class.[CUSTOMER NUMBER]
				  ,class.[CUSTOMER NAME]
				  ,class.[CUSTOMER SEGMENT LEVEL 1]
				  ,class.[CUSTOMER SEGMENT LEVEL 2]
				 ,'Insight STU' AS "Source"
			FROM CMCO_DATASTORE01.DBO.CustomerCLassificationFromCAT class with(nolock)
			JOIN (SELECT MAX(class.[DATE AS OF]) as DateAsOf,class.[CUSTOMER NUMBER]
				  FROM CMCO_DATASTORE01.DBO.CustomerCLassificationFromCAT class with(nolock)
				  GROUP BY  class.[CUSTOMER NUMBER]) C
			ON class.[CUSTOMER NUMBER] = c.[CUSTOMER NUMBER] and class.[DATE AS OF]=c.DateAsOf
			GROUP BY
				   class.[CUSTOMER NUMBER]
				  ,class.[CUSTOMER NAME]
				  ,class.[CUSTOMER SEGMENT LEVEL 1]
				  ,class.[CUSTOMER SEGMENT LEVEL 2]) class
		ON c.CUNO = class.[CUSTOMER NUMBER]
LEFT JOIN [CMCO_DATASTORE01].[dbo].[ OLGAEquipmentReportFromCAT] olga with(nolock) ON  c.CUNO = olga.[Customer Number]
                    and olga.Division = c.DIVI
                    AND olga.[Current Equipment]='YES'
WHERE CASE WHEN class.[CUSTOMER NUMBER] IS NULL THEN olga.[Customer Segment Level 1] else class.[CUSTOMER SEGMENT LEVEL 1] end IS NOT NULL
AND CASE WHEN class.[CUSTOMER NUMBER] IS NULL THEN olga.[Custmer Segment Level 2] else class.[CUSTOMER SEGMENT LEVEL 2] end IS NOT NULL
GROUP BY c.CUNO,c.CUNM
, CASE WHEN class.[CUSTOMER NUMBER] IS NULL THEN olga.[Customer Segment Level 1] else class.[CUSTOMER SEGMENT LEVEL 1] end 
, CASE WHEN class.[CUSTOMER NUMBER] IS NULL THEN olga.[Customer Segment Level 2] else class.[CUSTOMER SEGMENT LEVEL 2] end
, CASE WHEN class.[CUSTOMER NUMBER] IS NULL THEN 'OLGA Equip' else 'Insight STU' end 
ORDER BY c.CUNO -- need to remove if using this as a table to join 



