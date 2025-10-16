/* Temp Table Builds */

select A.ivno1, B.stn1, B.cscc, case when msdolp>1 then 0 else msdolp end*qty5*UNSEL as CGAMT, CGCD, 'N' as used
into #LDALDCWO
from dbs.dbo.MSPSEGS0 A
inner join dbs.dbo.MSPDETL0 B on A.IVNO1=B.IVNO1 and A.wosgno=B.WOSGNO
where A.woopno='' and cgcd in('LDA','LDC')

select ivno1, stn1, cscc, cgcd, sum(cgamt) as amt, 'N' as used
into #ldaldcwo2
from #LDALDCWO
group by ivno1, stn1, cscc, cgcd



select A.doccode, A.docnum, el1, el2, el3, A.DESCR, VALUEDOC, 
--(Select top 1 cgcd from #temp1 X where rtrim(A.doccode)+ltrim(A.docnum)=X.ivno1 and valuedoc=cgamt*-1) as chargecode
case when rtrim(A.doccode)+ltrim(A.docnum) in(select ivno1 from #LDALDCWO where cgcd='LDA') then 'Y' else 'N' end LDAinv,
case when rtrim(A.doccode)+ltrim(A.docnum) in(select ivno1 from #LDALDCWO where cgcd='LDC') then 'Y' else 'N' end LDCinv
into #LDALDC00
from dbs.dbo.OAS_D00024 A
inner join dbs.dbo.OAS_D00022 B on A.DOCNUM=b.DOCNUM and a.DOCCODE=b.DOCCODE and a.CMPCODE=b.CMPCODE
where el1 in('43000','43010','43011','43122','43123','43124','43125', '43127') and period between 1 and 12 and 
    DATEFROMPARTS(yr, period, 1)>dateadd(month, -7, getdate()) and 
    DATEFROMPARTS(yr, period, 1)<DATEFROMPARTS(year(getdate()), month(getdate()), 1) and A.descr in('43013')
and B.cmpcode='CARTMACH' and B.status=78

select doccode, docnum, el1, el2, el3
into #ldadupes
from #LDALDC00
group by doccode, docnum, el1, el2, el3
having count(*)>1



select *, rtrim(doccode)+ltrim(docnum) as doc, case when LDAinv='Y' and LDCinv='N' then VALUEDOC else 0 end as LDAamt,
case when LDAinv='N' and LDCinv='Y' then VALUEDOC else 0 end as LDCAmt, 
case when LDAinv='N' and LDCinv='Y' then 1 when LDAinv='Y' and LDCinv='N' then 1 else 99 end as status
into #ldaldc01
from #LDALDC00


update A
Set A.LDAamt=VALUEDOC
from #ldaldc01 A
join #ldaldcwo2 B on A.doc=B.IVNO1 and right(A.el2,2)=B.STN1 and Right(EL3,2)=B.CSCC 
where [status]=99 and b.CGCD='LDA' and VALUEDOC between (AMT*-1)-.01 and (AMT*-1)+.01

update B
Set B.used='Y'
from #ldaldc01 A
join #ldaldcwo2 B on A.doc=B.IVNO1 and right(A.el2,2)=B.STN1 and Right(EL3,2)=B.CSCC 
where [status]=99 and b.CGCD='LDA' and VALUEDOC between (AMT*-1)-.01 and (AMT*-1)+.01

update A
Set A.LDCamt=VALUEDOC
from #ldaldc01 A
join #ldaldcwo2 B on A.doc=B.IVNO1 and right(A.el2,2)=B.STN1 and Right(EL3,2)=B.CSCC
where [status]=99 and b.CGCD='LDC' and VALUEDOC between (AMT*-1)-.01 and (AMT*-1)+.01


update B
Set B.used='Y'
from #ldaldc01 A
join #ldaldcwo2 B on A.doc=B.IVNO1 and right(A.el2,2)=B.STN1 and Right(EL3,2)=B.CSCC
where [status]=99 and b.CGCD='LDC' and VALUEDOC between (AMT*-1)-.01 and (AMT*-1)+.01

update #ldaldc01
set status=2
where [status]=99 and LDAamt+LDCAmt=VALUEDOC

delete from #ldaldcwo2 where used='Y'


update A
Set A.LDAamt=AMT*-1
from #ldaldc01 A
join #ldaldcwo2 B on A.doc=B.IVNO1 and right(A.el2,2)=B.STN1 and Right(EL3,2)=B.CSCC 
where [status]=99 and b.CGCD='LDA' 

update A
Set A.LDCamt=AMT*-1
from #ldaldc01 A
join #ldaldcwo2 B on A.doc=B.IVNO1 and right(A.el2,2)=B.STN1 and Right(EL3,2)=B.CSCC
where [status]=99 and b.CGCD='LDC' 


update B
Set B.used='Y'
from #ldaldc01 A
join #ldaldcwo2 B on A.doc=B.IVNO1 and right(A.el2,2)=B.STN1 and Right(EL3,2)=B.CSCC 
where [status]=99 and b.CGCD='LDA' 


update B
Set B.used='Y'
from #ldaldc01 A
join #ldaldcwo2 B on A.doc=B.IVNO1 and right(A.el2,2)=B.STN1 and Right(EL3,2)=B.CSCC
where [status]=99 and b.CGCD='LDC' 


delete from #ldaldcwo2 where used='Y'


update #ldaldc01
set status=3
where [status]=99 and LDAamt+LDCAmt=VALUEDOC


update #LDALDC01 set LDAinv='N', LDCinv='N'

update #LDALDC01
set LDAinv=case when #LDALDC01.doc in(select ivno1 from #ldaldcwo2 where cgcd='LDA') then 'Y' else 'N' end,
LDCinv=Case  when #LDALDC01.doc in(select ivno1 from #ldaldcwo2 where cgcd='LDC') then 'Y' else 'N' end, LDAamt=0, LDCAmt=0
where [status]=99


update #LDALDC01
set LDAAMT= case when LDAinv='Y' and LDCinv='N' then VALUEDOC else 0 end,
LDCAMT= case when LDAinv='N' and LDCinv='Y' then VALUEDOC else 0 end,
status=4
where status=99 and ((LDAinv='Y' and LDCinv='N') or (LDAinv='N' and ldcinv='Y'))


select A.doccode, A.docnum, el1, el2, el3, A.DESCR, VALUEDOC, C.RESPAR
into #tempgl
from dbs.dbo.OAS_D00024 A
inner join dbs.dbo.OAS_D00022 B on A.DOCNUM=b.DOCNUM and a.DOCCODE=b.DOCCODE and a.CMPCODE=b.CMPCODE
left join dbs.dbo.msphdrs0 C on rtrim(A.DOCCODE)+ltrim(a.DOCNUM)=C.IVNO1
where el1 in('43000','43010','43011','43122','43123','43124','43125', '43127') and period between 1 and 12 and 
    DATEFROMPARTS(B.yr, period, 1)>dateadd(month, -7, getdate()) and 
    DATEFROMPARTS(B.yr, period, 1)<DATEFROMPARTS(year(getdate()), month(getdate()), 1)
and B.cmpcode='CARTMACH' and B.status=78


select DOCCODE, DOCNUM, el2, el3, sum(LDCAmt) as LDCAMT, sum(LDAamt) as ldaamt
into #disc
from #ldaldc01
where status<>99
group by doccode, docnum, el2, el3

select doccode, docnum, el2, el3, respar, sum(VALUEDOC) as net
into #tempgl2
from #tempgl
where descr not in('43013','4312A','61709') and el1 not in('43125', '43127')
group by doccode, docnum, el2, el3, respar

select a.DOCCODE, a.DOCNUM, a.el2, a.EL3, a.respar, net, isnull(ldaamt,0) as ldaamt, 
isnull(LDCAMT,0) as ldcamt, net as Net_beforedisc
into #disc2
from #tempgl2 A
left join #disc B on A.DOCCODE=B.DOCCODE and a.DOCNUM=B.DOCNUM and  a.EL2=b.el2 and a.el3=b.el3


select right(el2,2) as store, right(el3,2) as cc, sum(-Net_beforedisc) as LDA_WO_BeforeDisc, sum(ldaamt) as LDA_AMT
into #LDADisc
from #disc2
where ldaamt<>0 or respar='MR'
group by right(el2,2), right(el3,2)

select right(el2,2) as store, right(el3,2) as cc, sum(ldcamt) as LDC_Amt
into #LDCDisc
from #disc2
where ldcamt<>0
group by right(el2,2), right(el3,2)

select right(el2,2) as store, right(el3,2) as cc, sum(valuedoc) as OTH_Amt
into #othdisc
from #ldaldc01
where ldcamt=0 and ldaamt=0
group by right(el2,2), right(el3,2)


/* Master Store / CC List */

select distinct right(el2,2) as store, right(el3,2) as CC
from dbs.dbo.oas_b00001 with(nolock)
where left(el3,1) in('S','P')

union

select distinct right('00'+case when stn1='' then stno else stn1 end,2), cscc
from dbs.dbo.wophdrs0 H with(nolock)
left join dbs.dbo.wopsegs0 S with(nolock) on H.wono=S.wono


/* Store/ Region X Ref */

select *
from wipreport_storeregion_xref with(nolock)




/* Main Query */

select case when left(S.lbcc,1)='3' then 'COST' else 'Revenue' END as type, respar, 'WO' as source, H.acti, H.wono, null as bowono, S.wosgno, projectionadded,
eqmfcd, eqmfmd, eqmfsn, opndt8,


 right('00'+case when S.stn1='' then H.stno else S.stn1 end,2) as store,
S.cscc, 
right('00'+stno,2) as HeaderStore,
case when respar in ('HE','CE','SE', 'HC') then '51' when respar in('HF', 'RF', 'BL', 'PF') then '61' else respar end as hrdcc,  

Projected.projclose as date, 

case 
when S.LBCUNO='I99999' then 0
when H.respar='BL' and 
    (select count(distinct right('00'+case when stn1='' then stno else stn1 end,2)+'.'+cscc)
     from dbs.dbo.wophdrs0_hourly_openclosedjoin Hx with(nolock)
     left join dbs.dbo.wopsegs0_hourly_openclosedjoin Sx with(nolock) on Hx.wono=Sx.wono
     where hx.wono=H.wono)=1 then case when row_number() over(partition by H.wono order by case when left(S.lbcc,1)='3' then 'COST' else 'Revenue' END desc, S.wosgno)=1 then totest
     else 0 end


when isnull(estlabor,0)<>0 then EstLabor
when
LBRATE='F' then S.LBAMT*QTY4 when WIPLBS<>0 then WIPLBS when LBRATE='E' then S.lbamt*qty4 else 0 end as dollars,



case

when H.respar='BL' and 
    (select count(distinct right('00'+case when stn1='' then stno else stn1 end,2)+'.'+cscc)
     from dbs.dbo.wophdrs0_hourly_openclosedjoin Hx with(nolock)
     left join dbs.dbo.wopsegs0_hourly_openclosedjoin Sx with(nolock) on Hx.wono=Sx.wono
     where hx.wono=H.wono)=1 then 'Block'


 when isnull(estlabor,0)<>0 then 'Estimate'
when
LBRATE='F' then 'F/R' when WIPLBS<>0 then 'T&M' when LBRATE='E' then 'Segment Estimate' else '' end as dolsrc,

case when isnull(EstParts,0)<>0 then EstParts
when
PARATE='F' then S.PAAMT*QTY4 when WIPPAS<>0 then WIPPAS when PARATE='E' then S.paamt*qty4 else 0 end as ptsdollars,
case when isnull(EstParts,0)<>0 then 'Estimate'
when
PARATE='F' then 'F/R' when WIPPAS<>0 then 'T&M' when PARATE='E' then 'Segment Estimate' else '' end as ptsdolsrc,

isnull(frt.Freight,0) as freight,

 null as period, null as yr,

case when framt<>0 then 0 when lbrate='F' then S.LBAMT*qty4 else wiplbs END as openwip, wiplbs,
case when framt<>0 then 0 when parate='F' then S.PAAMT*QTY4 else wippas end as ptswip, wippas,
 wss_abbr, ssdatetime, isnull(ZoneChargesSalesAmt,0) as OpenZoneChargesSalesAmt, 
isnull(GrossSales,0) as GrossSales,
isnull(NetSalesbeforedisc,0) NetSalesbeforedisc,
isnull(frrealizedpct,0) frrealizedpct ,
isnull(LDADisc,0) LDADisc,
isnull(zonecharges,0) zonecharges,
isnull(zonedisc,0) zonedisc,
isnull(zonefactor,0) zonefactor,
isnull(LDA_WO_BeforeDisc,0) BeforeLDA,
isnull(LDA_AMT,0) LDA_Amt,
isnull(LDC_AMT,0) LDC_AMT,
isnull(OTH_AMT,0) Oth_amt





from dbs.dbo.wophdrs0_hourly_openclosedjoin H with(nolock)
left join dbs.dbo.wopsegs0_hourly_openclosedjoin S with(nolock) on H.wono=S.wono
left join 

(
select keyfld1, ssdatetime as projectionadded, projclose
from 
(select *, row_number() over(partition by keyfld1 order by ssdatetime desc) as rn,
    case when pdate<>'' then try_convert(date,left(pdate,8),112) else null end as projclose
from(select 
        dateadd(second, cast(substring(crttime,7,2) as int),
        dateadd(minute,cast(substring(crttime,4,2) as int),
        dateadd(hour,cast(left(crttime,2) as int),
        cast(crtdate as datetime2)))) as ssdatetime,
        *, substring(notetext, CHARINDEX('<br>',notetext)+4,8  ) as pdate
        from BMTS.dbo.uxpnote0_hourly_open_closedjoin with(nolock)
        where notetext like 'Workorder Sub-Status%' and
          try_convert(date,substring(notetext, CHARINDEX('<br>',notetext)+4,8  ),112) is not null) A) SS
where rn=1) Projected on H.wono=Projected.keyfld1


left join
(SELECT  wophdrs0.wono ,  wopsegs0.wosgno,
sum((wopmisc0.UNSEL*wopmisc0.qty5)) AS "Freight"
FROM dbs.dbo.WOPHDRS0_Hourly_OpenClosedJoin  wophdrs0
inner join dbs.dbo.WOPSEGS0_Hourly_OpenClosedJoin  wopsegs0 on (wophdrs0.wono=wopsegs0 .wono) 
 inner join dbs.dbo.WOPMISC0_Open  wopmisc0 on  (wopsegs0.wosgno=wopmisc0.wosgno) AND (wopsegs0.wono=wopmisc0.wono ) 
inner join dbs.dbo.CIPNAME0  cipname0 on (cipname0.cuno=(case when wopsegs0.MSCUNO>' ' then wopsegs0.MSCUNO else wophdrs0.cuno end))
 where wophdrs0.acti in('O','C') AND wophdrs0.ivtypi<>'3' and wopmisc0.ADSTNO in ('6200A','6200T','62000') and wopmisc0.hdsgii=' '
group by wophdrs0.wono, wopsegs0.wosgno) FRT on H.wono=frt.wono and S.wosgno=frt.wosgno





left join 
(
select wono, ssdatetime,  ss1sts
from 
(select *, row_number() over(partition by wono order by ssdatetime desc) as rn,
    case when ss1note<>'' then try_convert(date,left(ss1note,8),112) else null end as projclose
from(select 
        dateadd(second, cast(substring(ss1time,7,2) as int),
        dateadd(minute,cast(substring(ss1time,4,2) as int),
        dateadd(hour,cast(left(ss1time,2) as int),
        cast(ss1date as datetime2)))) as ssdatetime,
        *
        from bmts.dbo.USPWOSS0_Hourly_Open_ClosedJoin with(nolock)
        ) A) SS
where rn=1) Substatus on H.wono=Substatus.WONO







left join 

(select A.QT_WONO, QT_WOSEG, sum(QT_LBAMTX) as EstLabor, sum(qt_paamtx) as EstParts
from(
    select *
    from(select qt_num, QT_STATUS, qt_wono,
            ROW_NUMBER() over (partition by left(qt_num,8) order by substring(qt_num,10,2) desc) rn
        from bmts.dbo.USPSWQC0_Hourly_Open_ClosedJoin with(nolock)
        where QT_STATUS='ACC') A
    where rn=1) A
left join BMTS.dbo.USPSWQS0_Hourly_Open_ClosedJoin S1 with(nolock) on A.QT_NUM=S1.QT_NUM
group by A.QT_WONO, QT_WOSEG) EST on S.wono=est.QT_WONO and S.wosgno=Est.QT_WOSEG
left join BMTS.dbo.USPWSSD0 Dsc with(nolock) on substatus.SS1STS=dsc.WSS_CODE




left join (

    select substring(el2,2,2) as store, substring(el3,2,2) as cc, 
    sum(case when el1 not in('43011','43124','43125','43127') and descr not in('43013','4312A','61709') then -VALUEDOC else 0 end) as Grosssales,
    sum(case when descr not in('43013','4312A','61709') and el1 not in('43125','43127') then -VALUEDOC end) as NetSalesBeforeDisc,
    case when sum(case when el1 not in('43011','43124','43125', '43127') then VALUEDOC else 0 end)=0 then 0 else
    sum(case when descr not in('43013','4312A','61709') and el1 not in('43125','43127') then -VALUEDOC end)/
    nullif(sum(case when el1 not in('43011','43124','43125','43127') and descr not in('43013','4312A','61709') then -VALUEDOC else 0 end),0) end as frrealizedpct,
    sum(case when descr='43013' then -valuedoc else 0 end) as LDADisc,
    sum(case when descr='61709' then -VALUEDOC else 0 end) as zonecharges,
    sum(case when descr='4312A' then -valuedoc else 0 end) as zonedisc,
    case when     sum(case when descr='61709' then -VALUEDOC else 0 end)<>0 then
    sum(case when descr='4312A' then -valuedoc else 0 end)/
    NULLIF(sum(case when descr='61709' then -VALUEDOC else 0 end),0) else 0 end as zonefactor
      
    from #tempgl with(nolock)
    where  el1 in('43000','43010','43011','43122','43123','43124','43125','43127') 
    group by substring(el2,2,2), substring(el3,2,2)



) Adjustments
on right('00'+case when S.stn1='' then H.stno else S.stn1 end,2)=Adjustments.store and S.cscc=Adjustments.cc


left join #LDADisc LDA on right('00'+case when S.stn1='' then H.stno else S.stn1 end,2)=LDA.store and S.CSCC=LDA.cc
left join #LDCDisc LDC on right('00'+case when S.stn1='' then H.stno else S.stn1 end,2)=LDC.store and S.CSCC=LDC.cc
left join #othdisc OTH on right('00'+case when S.stn1='' then H.stno else S.stn1 end,2)=oth.store and S.CSCC=oth.cc





left join
    (select  H.wono, S.WOSGNO, 
    sum(UNSEL*QTY5*.15) as ZoneChargesSalesAmt
    from dbs.dbo.WOPHDRS0_Hourly_OpenClosedJoin H
    left join dbs.dbo.WOPSEGS0_Hourly_OpenClosedJoin S on H.wono=S.wono
    inner join dbs.dbo.DBS_WOPMISC0_Open_Closed_View M on S.wono=M.wono and S.wosgno=M.WOSGNO
    where M.CGCD between 'SZ1' and 'SZ9' and HDSGII not in('T','Z')
    group by right('00'+case when S.stn1<>'' then S.stn1 else H.stno end,2),  H.wono, S.wosgno) OpenZOne
on S.WONO=OpenZOne.WONO and S.WOSGNO=OpenZOne.WOSGNO




where ivtypi<>'3'



union all

select '',respar, 'Ledger' as source, 'I' as acti, 

case when IVTYP='W' then M.WONO end as wono,
case when IVTYP='B' then M.wono end as bowono,


 '' as wosgno, '','', '', '', 0,
right(el2,2) as store,
right(el3,2) as costctr, M.STN1 as headerstore, 
case when respar in ('HE','CE','SE','HC') then '51' when respar in('HF', 'RF', 'BL', 'PF') then '61' else respar end as respar,

case when left(DOCDATE,10)<DATEFROMPARTS(H.yr,period,1) then DATEFROMPARTS(H.yr,period,1)
when left(DOCDATE,10)>dateadd(day,-1,dateadd(month,1,DATEFROMPARTS(H.yr,period,1)))
then dateadd(day,-1,dateadd(month,1,DATEFROMPARTS(H.yr,period,1)))
else left(DOCDATE,10) end as date1,
sum(case when left(el3,1)='S' and B.actind='4' then -VALUEDOC else 0 end) as 'Billed',
 '',
sum(case when left(el3,1)='P' and B.actind='4' then -VALUEDOC else 0 end) as 'BilledPts',
'', sum(case when el1 in('62000','62003') then -VALUEDOC else 0 end) as freight,
 period, H.yr, 0 as openwipfr, 0 as wiplbs,0,0, null as abbr, null as ssdatetime, 0 , 0, 0,0,0,0,0,0,0,0,0,0
from dbs.dbo.oas_d00024 A with(nolock)
inner join dbs.dbo.OAS_D00022 H with(nolock) on A.CMPCODE=H.CMPCODE and A.DOCCODE=H.DOCCODE and A.DOCNUM=H.DOCNUM
inner join dbs.dbo.UAPAINX1 B with(nolock) on A.EL1=B.ACCT
left join dbs.dbo.MSPHDRS0 M with(nolock) on rtrim(ltrim(A.DOCCODE))+rtrim(ltrim(A.docnum))=M.IVNO1
where A.CMPCODE='CARTMACH' and (left(el3,1) in('S') or (left(el3,1)='P' and 
el1 in('42030','42113','42111','42114','42121','42124','42142','42143','42153','42154','42155','43123', '62000','62003')))

 and (B.ACTIND='4' or el1 in('62000','62003')) and period between 1 and 12
and H.yr>2020
group by H.yr, period, right(el2,2), right(el3,2),respar, M.stn1, 
case when respar in ('HE','CE','SE', 'HC') then '51' when respar in('HF', 'RF', 'BL', 'PF') then '61' else respar end,
case when left(DOCDATE,10)<DATEFROMPARTS(H.yr,period,1) then DATEFROMPARTS(H.yr,period,1)
when left(DOCDATE,10)>dateadd(day,-1,dateadd(month,1,DATEFROMPARTS(H.yr,period,1)))
then dateadd(day,-1,dateadd(month,1,DATEFROMPARTS(H.yr,period,1)))
else left(DOCDATE,10) end,
case when IVTYP='W' then M.WONO end,
case when IVTYP='B' then M.wono end


/* Get Customer Names */

select wono, B.cuno, B.cunm
from dbs.dbo.wophdrs0 A with(Nolock)
left join dbs.dbo.cipname0 B with(Nolock) on A.cuno=B.cuno




/*  Data for Core Parts - probably don't need */
select A.wono, wosgno, TRXCD, TOIVQY, A.pano20, A.sos1, A.ds18 as trxdesc, C.ds18
from dbs.dbo.WOPPART0_Open A with(nolock)
inner join dbs.dbo.PCPCRPR0 B with(nolock) on A.pano20=B.PANO20 and A.SOS1=B.SOS1
left join dbs.dbo.PCPPIPT0 C with(nolock) on A.PANO20=C.PANO20 and A.SOS1=C.SOS1
where HDSGII not in('T','Z') and left(TRXCD,1) in('8','9')




/* Projection Changes */

select B.*, row_number() over (partition by B.keyfld1 order by ssdatetime desc) as row, rtcdatetime
from (
select ssdatetime, KEYFLD1, pdate, lag(pdate) over( partition by keyfld1 order by keyfld1, ssdatetime) as prevdate,
lag(pdate) over(partition by keyfld1 order by keyfld1, ssdatetime desc) as nextdate

from
(select 
        dateadd(second, cast(substring(crttime,7,2) as int),
        dateadd(minute,cast(substring(crttime,4,2) as int),
        dateadd(hour,cast(left(crttime,2) as int),
        cast(crtdate as datetime2)))) as ssdatetime,
        *, try_convert(date, substring(notetext, CHARINDEX('<br>',notetext)+4,8  )) as pdate
        from BMTS.dbo.uxpnote0_hourly_open_closedjoin with(nolock)
        where notetext like 'Workorder Sub-Status%' and
          try_convert(date,substring(notetext, CHARINDEX('<br>',notetext)+4,8  ),112) is not null) A
) B

left join 
 ( SELECT uxpnoteRTC.keyfld1, uxpnoteRTC.CRTDATE, uxpnoteRTC.CRTTIME, 
     dateadd(SECOND,cast(right(crttime,2) as integer),
     dateadd(minute,cast(substring(crttime,4,2) as integer),
     dateadd(hour,cast(left(CRTTIME,2) as int),crtdate))) as rtcdatetime
          FROM bmts.dbo.uxpnote0_open uxpnoteRTC with(nolock)
              INNER JOIN 
                    (SELECT uxpnoteRTC1.keyfld1, MAX(uxpnoteRTC1.NOTESEQ) NOTESEQ
                     FROM bmts.dbo.uxpnote0_open uxpnoteRTC1 with(nolock)
                     WHERE substring(uxpnoteRTC1.NOTETEXT,45,3)='RTC'
                     GROUP BY uxpnoteRTC1.keyfld1) uxpnoteRTC1 ON uxpnoteRTC1.keyfld1=uxpnoteRTC.keyfld1 and 			uxpnoteRTC1.NOTESEQ=uxpnoteRTC.NOTESEQ
            WHERE substring(uxpnoteRTC.NOTETEXT,45,3)='RTC'                 
            ) uxpnoteRTC ON B.keyfld1=uxpnoteRTC.keyfld1








where B.pdate<>b.prevdate or prevdate is null


/* Date/Store/CC Scaffold */
select *
from gdm.dbo.datescaffold with(nolock),
(select distinct right(el2,2) as store, right(el3,2) as CC--, left(el3,1) as CTR
from dbs.dbo.oas_b00001 with(nolock)
where left(el3,1) in('S','P')

union 

select distinct right('00'+case when stn1='' then stno else stn1 end,2), cscc
from dbs.dbo.wophdrs0_hourly_openclosedjoin H with(nolock)
left join dbs.dbo.wopsegs0_hourly_openclosedjoin S with(nolock) on H.wono=S.wono



)  B
where year(date)>2020



/* Daily Dashboard */

select date, store, cscc, dailybudget, 'labor' as budgettype,ctr
from gdm.dbo.DateScaffold AA with(nolock)
left join(
            Select yr, period, store, cscc, ctr, budget/monthdays as dailybudget
            from (
            select yr, period, right(el2,2) as store, right(el3,2) as cscc, 
            left(el3,1) as ctr, sum(-FULL_VALUE) as budget,
            day(dateadd(day,-1,dateadd(month,1,DATEFROMPARTS(yr, period,1)))) as monthdays
            from dbs.dbo.OAS_B00001 A with(nolock)
            inner join dbs.dbo.UAPAINX1 B with(nolock) on A.EL1=B.ACCT
            where balcode like 'BUDGET%' and ACTIND='4' and period between 1 and 12 and left(el3,1)='S'
            group by yr, period, right(el2,2), right(el3,2), left(el3,1) ) A ) BB
on year(aa.[DATE])=BB.yr and month(AA.[DATE])=bb.[PERIOD]
where year(date)>2020 and year(date)<=year(getdate())+3


union all

select date, store, cscc, dailybudget, 'parts' as budgettype, ctr
from gdm.dbo.DateScaffold AA with(nolock)
left join(
            Select yr, period, store, cscc, ctr, budget/monthdays as dailybudget
            from (
            select yr, period, right(el2,2) as store, right(el3,2) as cscc,
            left(el3,1) as ctr, sum(-FULL_VALUE) as budget,
            day(dateadd(day,-1,dateadd(month,1,DATEFROMPARTS(yr, period,1)))) as monthdays
            from dbs.dbo.OAS_B00001 A with(nolock)
            inner join dbs.dbo.UAPAINX1 B with(nolock) on A.EL1=B.ACCT
            where balcode like 'BUDGET%' and ACTIND='4' and period between 1 and 12 and left(el3,1)='P'
            and el1 in('42030','42113','42111','42114','42121','42124','42142','42143','42153','42154','42155','43123')
            group by yr, period, right(el2,2), right(el3,2), left(el3,1) ) A ) BB
on year(aa.[DATE])=BB.yr and month(AA.[DATE])=bb.[PERIOD]
where year(date)>2020 and year(date)<=year(getdate())+3


union all

select date, store, cscc, dailybudget, 'freight' as budgettype, ctr
from gdm.dbo.DateScaffold AA with(nolock)
left join(
            Select yr, period, store, cscc, ctr, budget/monthdays as dailybudget
            from (
            select yr, period, right(el2,2) as store, right(el3,2) as cscc,
            left(el3,1) as ctr, sum(-FULL_VALUE) as budget,
            day(dateadd(day,-1,dateadd(month,1,DATEFROMPARTS(yr, period,1)))) as monthdays
            from dbs.dbo.OAS_B00001 A with(nolock)
            inner join dbs.dbo.UAPAINX1 B with(nolock) on A.EL1=B.ACCT
            where balcode like 'BUDGET%' and period between 1 and 12 and left(el3,1)='P'
            and  el1 in('62000','62003')
            group by yr, period, right(el2,2), right(el3,2), left(el3,1) ) A ) BB
on year(aa.[DATE])=BB.yr and month(AA.[DATE])=bb.[PERIOD]
where year(date)>2020 and year(date)<=year(getdate())+3
