/*************
 * This file calculates AES for all indices in the paper.
 ***************/
/* Set up Stata */
set more off

log using "AES.log", replace

/* Begin logging */
cd "C:\Dropbox\Paola_Nathan\Paola\QJE_revision_codes_data\ReplicationCodes"
use "crosscountry_dataset"

/**********
 * overall aes
 ***********/
/* First preserve between aes calculations */
*preserve

/* Set up macros */
local comp_type = "replace"

local rmean_type = "replace"
local irmean_type = "replace"


/* Create normalized effect estimates */
local counter = 1
gen flag = 1
foreach y in flfp2000 female_ownership women_politics{
  sum `y' if plow==0
  local nm`counter' = 1/r(sd)
  local comp_sd = r(sd)
  local comp_mean = r(mean)
  gen n_`y' = `y' / r(sd)
  replace flag = . if `y' == .
  sum `y' if plow>0 & plow~=. 
  local itt_sd = r(sd)
  gen aes`counter' = `y'
  local counter = `counter' + 1

  ivreg2 `y' (plow= plow_positive_crops plow_negative_crops) plow economic_complexity agricultural_suitability ln_income ln_income_squared large_animals  political_hierarchies tropical_climate, r first
   local comp_type = "append"
}

/* Handle rmean calclation here */
egen overall_women_rmean = rmean(n_flfp2000 n_female_ownership n_women_politics)
sum overall_women_rmean if plow==0
local comp_sd = r(sd)
local comp_mean = r(mean)
sum overall_women_rmean if plow>0 & plow~=. 
local itt_sd = r(sd)
ivreg2 overall_women_rmean (plow= plow_positive_crops plow_negative_crops) plow economic_complexity agricultural_suitability ln_income ln_income_squared large_animals  political_hierarchies tropical_climate, r first

/* Now handle the IRmean results */
foreach y in flfp2000 female_ownership women_politics {
  gen i`y' = `y' * flag
  sum `y' if plow==0
  local sd = r(sd)
  replace i`y' = i`y' / `sd'
}

egen overall_women_irmean = rmean(iflfp2000 ifemale_ownership iwomen_politics)
sum overall_women_irmean if plow==0
local comp_sd = r(sd)
local comp_mean = r(mean)
sum overall_women_irmean if plow>0 & plow~=.
local itt_sd = r(sd)
ivreg2 overall_women_irmean (plow= plow_positive_crops plow_negative_crops)  plow economic_complexity agricultural_suitability ln_income ln_income_squared large_animals political_hierarchies tropical_climate, r first


/* Next reshape long */
reshape long aes, i(isocode) j(out)
label variable aes "overall_women"

/* Prepare for the regressions by forming interactions */

xi i.out*plow i.out*plow_positive_crops i.out*plow_negative_crops
gen _Iout_1 = 0
replace _Iout_1 = 1 if out == 1

gen _IoutXplowpos =  _Iout_1*plow_positive_crops
gen _IoutXplowneg =  _Iout_1*plow_negative_crops
gen _IoutXplow	  =  _Iout_1*plow 



/* Construct the outcome _x_* interactions */
forvalues z = 1/3{
gen large_animals_`z' =  _Iout_`z'*large_animals
gen agricultural_suitability_`z' = _Iout_`z'*agricultural_suitability 
gen economic_complexity_`z' = _Iout_`z'*economic_complexity 
gen ln_income_`z' = _Iout_`z'*ln_income
gen ln_income_squared_`z' = _Iout_`z'*ln_income_squared   
gen political_hierarchies_`z' = _Iout_`z'*political_hierarchies 
gen tropical_climate_`z' = _Iout_`z'*tropical_climate
}







rename overall_women_irmean AES

****************
***TABLE III****
****************
xi: reg  AES  		plow agricultural_suitability tropical_climate large_animals political_hierarchies economic_complexity, r
su AES if e(sample)
fitstat
outreg using TableIII_aes.xls, replace coefastr 3aster se
xi: reg  AES   		plow agricultural_suitability tropical_climate large_animals political_hierarchies economic_complexity i.continent, r
fitstat
outreg using TableIII_aes.xls, append coefastr 3aster se

****************
***TABLE IV****
****************

xi: reg  AES 	 	plow agricultural_suitability tropical_climate large_animals political_hierarchies economic_complexity ln_income ln_income_squared, r
fitstat
su AES if e(sample)
outreg using TableIV_aes.xls, replace coefastr 3aster se
xi: reg  AES 	 	plow agricultural_suitability tropical_climate large_animals political_hierarchies economic_complexity ln_income ln_income_squared i.continent, r
fitstat
outreg using TableIV_aes.xls, append coefastr 3aster se

*****************
***TABLE VIII****
*****************

reg  plow plow_positive_crops plow_negative_crops agricultural_suitability tropical_climate large_animals political_hierarchies economic_complexity ln_income ln_income_squared if AES~=., r 
outreg using TableVIIIa_aes.xls, replace coefastr 3aster se
fitstat
su plow if e(sample)
test plow_negative_crops plow_positive_crops
test plow_negative_crops=plow_positive_crops
predict resid, resid
reg AES plow resid agricultural_suitability tropical_climate large_animals political_hierarchies economic_complexity ln_income ln_income_squared, r 
drop resid

xi: reg  plow plow_positive_crops plow_negative_crops agricultural_suitability tropical_climate large_animals political_hierarchies economic_complexity ln_income ln_income_squared i.continent if AES~=., r 
outreg using TableVIIIa_aes.xls, append coefastr 3aster se
fitstat
su plow if e(sample)
test plow_negative_crops plow_positive_crops
test plow_negative_crops=plow_positive_crops
predict resid, resid
xi: reg AES plow resid agricultural_suitability tropical_climate large_animals political_hierarchies economic_complexity ln_income ln_income_squared i.continent, r 
drop resid

xi: reg  AES 	plow_positive_crops  plow_negative_crops agricultural_suitability tropical_climate large_animals political_hierarchies economic_complexity ln_income ln_income_squared, r 
outreg using TableVIIIb_aes.xls, replace coefastr 3aster se
su AES if e(sample)
fitstat
test plow_negative_crops plow_positive_crops
test plow_negative_crops=plow_positive_crops
xi: reg  AES 	plow_positive_crops	plow_negative_crops agricultural_suitability tropical_climate large_animals political_hierarchies economic_complexity ln_income ln_income_squared i.continent, r 
outreg using TableVIIIb_aes.xls, append coefastr 3aster se
fitstat
test plow_negative_crops plow_positive_crops
test plow_negative_crops=plow_positive_crops

xi: ivreg2  AES 		(plow= plow_negative_crops plow_positive_crops) agricultural_suitability tropical_climate large_animals political_hierarchies economic_complexity ln_income ln_income_squared, r first
outreg using TableVIIIc_aes.xls, replace coefastr 3aster se
xi: ivreg2  AES 		(plow= plow_negative_crops plow_positive_crops) agricultural_suitability tropical_climate large_animals political_hierarchies economic_complexity ln_income ln_income_squared i.continent, r first
outreg using TableVIIIc_aes.xls, append coefastr 3aster se
xi: ivreg  AES 		(plow= plow_negative_crops plow_positive_crops) agricultural_suitability tropical_climate large_animals political_hierarchies economic_complexity ln_income ln_income_squared i.continent
overid

log close

