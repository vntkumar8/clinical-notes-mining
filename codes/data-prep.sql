----  Save this ouput as view: tab1
SELECT p.subject_id
	, a.hadm_id
	, a.admittime
	, p.dob
	, p.dod
	, p.dod_hosp
	, p.dod_ssn
    , p.gender 
	, p.expire_flag
    , case
    	when a.admittime = MIN (a.admittime) OVER (PARTITION BY p.subject_id) then 1
    	when a.admittime != MIN (a.admittime) OVER (PARTITION BY p.subject_id) then 0
    	end AS first_admission
    , ROUND( (DATE_DIFF(cast(admittime as date),cast(dob as date),day)) / 365.242,2)

        AS first_admit_age
FROM  `physionet-data.mimiciii_clinical.admissions` a

INNER JOIN `physionet-data.mimiciii_clinical.patients`  p
ON p.subject_id = a.subject_id
ORDER BY p.subject_id, a.hadm_id

----  Save this ouput as view: tab2

select subject_id
	, hadm_id
	, icustay_id
	, dbsource
	, first_careunit
	, case
    	when intime = MIN (intime) OVER (PARTITION BY hadm_id) then 1
    	when intime != MIN (intime) OVER (PARTITION BY hadm_id) then 0
    	end AS first_icu
from `physionet-data.mimiciii_clinical.icustays`
order by subject_id, icustay_id




----  Save this ouput as table itself (as view cannot be saved due to circular reference) goto setting save as destination table as tab3


select tab1.*
	, tab2.icustay_id
	, tab2.dbsource
	, tab2.first_careunit
	, tab2.first_icu


from tab1 
inner join tab2 
on tab1.subject_id = tab2.subject_id and tab1.hadm_id = tab2.hadm_id
where tab1.first_admission = 1 and tab2.first_icu = 1 and tab1.first_admit_age >=15


------------ patient df
select tab3.*
	, case 
		when round((DATE_DIFF(cast(tab3.dod  as date),cast(tab3.admittime as date),day))) <= 30 then 1
    
		else 0
		end as thirty_day_mortality
from mimic.tab3


-------------- nursing notes
select * 
from `physionet-data.mimiciii_notes.noteevents` 
where hadm_id in (select hadm_id from mimic.tab3) and Description in ('Nursing Progress Note')
													-------category in ('Nursing/other', 'Nursing')
order by subject_id    

------------- SAPSII SCores
select * 
from `physionet-data.mimiciii_derived.sapsii` 
where icustay_id in (select icustay_id from mimic.tab4)
order by subject_id	
