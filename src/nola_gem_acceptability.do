
		* -------------------------------------------------------------------------- *
		*																		     *
		*	Acceptability, feasibility, and usability of NOLA Gem 			   	     *
		*	Descriptives, viz. / exploratory modeling for disparities in uptake.     *
		*																		     *
		*		nola_gem_acceptability.do										     *
		*		Simone J. Skeen (01-28-2025)									     *
		*																		     *
		* -------------------------------------------------------------------------- *

clear all
set more off

* log

capture log close
log using nola_gem_acceptability_log.txt, replace

* set scheme, font

set scheme white_tableau
graph set window fontface "Arial"

		
		///////////////// *------------------------------------* /////////////////
		///////////////// *     1. Transform, clean, merge     * /////////////////
		///////////////// *------------------------------------* /////////////////


cd "~/Documents/02_tulane/01_research/nola_gem/dissem/skeen,etal_acceptability/data"
clear

* /////////// import post_assessment - raw

	import delim post_index
	*d

	* reduce

	keep ng_id post_date arm loc1-loc5 ///
		app1-app11 intervention1-intervention17 ///
		ueq1-ueq8 tues1-tues3 nps open1-open4

	* destring varlist w/ NAs

	foreach i in app6 app46 app8 app10 ///
		intervention11 intervention12 ///
		intervention13 intervention14 ///
		ueq2 ueq5 ueq6 ueq8 { 
		rename `i' `i'_str 
		destring `i'_str, gen(`i') ignore("NA") 
		} 

	* truncate intervention* varlist	
		
	rename intervention# int#	
		
	* destring `id'

	destring ng_id, gen(id) ignore("g G")
	drop ng_id	
		
	* housekeeping	
		
	rename arm arm_post		
	drop *_str

	* save post_assessment - pre-merge .dta

	save nola_gem_post_assessment, replace
	
* /////////// import baseline - raw

	clear
	import delim baseline_index 
	d

	* reduce

	keep ng_id arm baseline_date sex gender ///
		gender_other race race_other ethnicity ///
		housing housing_other education household_income ///
		sexual_orientation home_zip loc_* q1_audit ///
		asi_d10a asi_d8a asi_opiates asi_d13a hiv_stigma* ///
		hads1* perceived_stress* brief_cope* coping_selfefficacy* ///
		aces* ipv* lec* ptsd_* pcl_* ptgi_* trauma_cog* ///
		discrimination_* digital_self_conf* phonetype
	
	* destring varlist w/ NAs

	foreach i in aces1 aces2 aces3 aces4 aces5 ///
		aces6 aces7 aces8 aces9 aces10 {
		rename `i' `i'_str
		destring `i'_str, generate(`i') ignore("NA")
		}

	* destring `id'

	destring ng_id, gen(id) ignore("g G")
	drop ng_id	
		
	* housekeeping
		
	rename arm arm_bl	
	drop *_str		

	* save baseline - pre-merge .dta

	save nola_gem_baseline, replace	

	/* pre-merge inspect / sense check

	use nola_gem_post_assessment, clear
	list id arm, sep(0)

	use nola_gem_baseline, clear
	list id arm, sep(0) */

* /////////// merge 1:1 on `id'
	 
	merge 1:1 id using nola_gem_post_assessment	 

	list arm_bl arm_post, sep(0)
	drop arm_bl
	rename arm_post arm

	* drop dropouts

	tab _merge	 
	tab _merge, nol	 
	 
	drop if _merge == 1	 

	* save analytic sample (N = 30) 
	 
	save nola_gem_acceptability, replace		 

		///////////////// * ------------------------ * /////////////////
		///////////////// *     1. Acceptability     * /////////////////
		///////////////// * ------------------------ * /////////////////	

use nola_gem_acceptability, clear		
		
* strict de-identification

drop loc* home_zip

* digital confidence: reverse code

foreach i in digital_self_conf1 digital_self_conf2 ///
	digital_self_conf3 digital_self_conf4 {
	recode `i' (4 = 1) (3 = 2) (2 = 3) (1 = 4), gen(`i'_rev) 
	tab `i'
	tab `i'_rev
	}

	
		* --------------------------------------------------------------------------------------------- *

		dis "Table 1. Baseline socio-demographic attributes and digital confidence: NOLA Gem pilot"	

		* socio-demographics
			 
		foreach i in gender sexual_orientation race ethnicity ///
			housing household_income phonetype {
			tab `i'
			tab `i'	if arm == 1
			tab `i'	if arm == 0 
			}

		* digital confidence	
			
		foreach i in digital_self_conf1_rev digital_self_conf2_rev /// 
			digital_self_conf3_rev digital_self_conf4_rev {
		*	summ `i'
			summ `i' if arm == 1
			summ `i' if arm == 0
			}

		* --------------------------------------------------------------------------------------------- *

		
* /////////// add'l descriptives - narr results		
		
* digital confidence summ

gen digi_sum = (digital_self_conf1_rev + digital_self_conf2_rev ///
	+ digital_self_conf3_rev + digital_self_conf4_rev)		
summ digi_sum		
		
	
* app1-app3: reverse code

foreach i in app1 app2 app3 app4 {
	recode `i' (3 = 1) (1 = 3), gen(`i'_rev) 
	tab `i'
	tab `i'_rev
	}
	
*app6, app46, app8: reverse code 

foreach i in app6 app46 app8 {
	recode `i' (4 = 1) (3 = 2) (2 = 3) (1 = 4), gen(`i'_rev) 
	tab `i'
	tab `i'_rev
	}

	
		* --------------------------------------------------------------------------------------------- *	
	
		dis "Table 2. App usage and satisfaction: NOLA Gem+GEMA (treatment group, n = 22)"
	
		foreach i in app1_rev app2_rev app3_rev app4_rev app5 ///
			app6_rev app45 app46_rev app7 app8_rev app9 app10 {
		*	summ `i' if arm == 1
		*	tab `i' if arm == 1
			by arm, sort: summ `i'
			}

		* --------------------------------------------------------------------------------------------- *
	
	
* exploratory: cross-arm diff		
		
foreach i in app1_rev app2_rev app3_rev app4_rev {
	ttest `i', by(arm)
	}
	
* intervention1-intervention14: reverse code - for matplotlib	
		
foreach i in int1 int2 int3 ///
	int4 int5 int6 int7 ///
	int8 int9 int10 int11 ///
	int12 int13 int14 int15 ///
	int16 int17 {
	recode `i' (4 = 1) (3 = 2) (2 = 3) (1 = 4), gen(`i'_rev) 
	tab `i'
	tab `i'_rev
	}

* save 

save, replace	
	
*save nola_gem_acceptability_no_loc_tx - .csv to matplotlib

keep if arm == 1
export delim nola_gem_acceptability_no_loc_tx.csv, replace
	
use nola_gem_acceptability, clear		
		
* UEQ: User Experience Questionnaire	 
	
foreach i in ueq1 ueq2 ueq3 ueq4 ueq5 ueq6 ueq7 ueq8 {
	summ `i' if arm == 1
*	tab `i'
	}	
	
foreach i in ueq1 ueq2 ueq3 ueq4 ueq5 ueq6 ueq7 ueq8 {
	summ `i' if arm == 0
*	tab `i'
	}	

	
		* --------------------------------------------------------------------------------------------- *
	
		dis "Fig. 3. UEQ-S mean scores: GEMA (control) vs. NOLA Gem+GEMA (treatment)"	

		clear
			
		* UEQ spider plot: NOLA Gem v. GEMA	
			
		input cond ueq_item ueq_mean
			1 1 5.818182
			1 2 5.909091
			1 3 6.136364
			1 4 6
			1 5 4.714286
			1 6 5.380952
			1 7 4.909091
			1 8 4.761905
			2 1 5.75
			2 2 6
			2 3 6.25
			2 4 6.375
			2 5 5.125
			2 6 6
			2 7 4.625
			2 8 4.5
		end

		label define condl 1 "GEMA+NOLA Gem (treatment)" 2 "GEMA (control)"
		label define ueq_iteml 1 "Supportive/helpful" 2 "Easy" 3 "Efficient" ///
		4 "Clear" 5 "Exciting" 6 "Interesting" 7 "Inventive" 8 "Innovative"

		label values cond condl
		label values ueq_item ueq_iteml

		spider ueq_mean, by(ueq_item) over(cond) alpha(6) ra(0(1)7) msym(square) rot(22) ///
			smooth(0) palette(w3 default, select(1 4)) slabsize(1.8) displacelab(10) msize(0.6)
			
		*sc(black) 	
		*lw(0.4)
		*grid	
	
		* --------------------------------------------------------------------------------------------- *

		
* NPS: Net Promoter Score

gen nps_score = 0
replace nps_score = 2 if (nps > 8)
replace nps_score = 1 if (nps < 7)

summ nps
tab nps_score if arm == 1

* "promoters" = 60%
* "detractors" = 30%
di 63.64 - 22.73
	 
* save

save, replace	

*  /////////// disparities + drivers // exploratory bivar	
	
	* race - recode: 1 = Black		
		
	gen race_bin = 0
	replace race_bin = 1 if (race == 2)
	list race race_bin, sep(0)

	* gender - recode: 1 = male

	gen gend_bin = 0
	replace gend_bin = 1 if (gender == 1)
	list gender gend_bin, sep(0)

	* sexual_minority: 1 = gay, bisexual, self-describe

	gen sexual_minority = 0
	replace sexual_minority = 1 if (sexual_orientation > 1)
	list sexual_orientation sexual_minority, sep(0)

	* education - recode: 1 = attainment past high school

	gen educ_bin = 0
	replace educ_bin = 1 if (education > 2)
	list education educ_bin, sep(0)

	* income - recode: 1 = >$19,999

	gen incm_bin = 0
	replace incm_bin = 1 if (household_income > 2)
	list household_income incm_bin, sep(0)

	* q1_audit asi_d10a asi_d8a asi_opiates asi_d13a - recode: 1 = any <substance> use

	foreach i in q1_audit asi_d10a asi_d8a asi_opiates asi_d13a {
		gen `i'_bin = 0
		replace `i'_bin = 1 if (`i' > 0)
		list `i' `i'_bin, sep(0)
		} 

	* perceived stress - recode: casewise mean

	gen perceived_stress_mean = ///
		(perceived_stress1 + perceived_stress2 + ///
		perceived_stress3 + perceived_stress4) / 4
	
	* ptsd_crit* - use ptsd_clinical_cutoff
	
	* pcl - dichot at >33 cutoff

	egen pcl_sum = rowtotal(pcl_5_1-pcl_5_20)
	tab pcl_sum
	summ pcl_sum	
	
	gen pcl_bin = 0
	replace pcl_bin = 1 if (pcl_sum > 33)
	list pcl_sum pcl_bin, sep(0)	

	* ptgi - median split

	* egen ptgi_sum = rowtotal(ptgi_1-ptgi_7)

	tab ptgi_sum
	xtile ptgi_mdn = ptgi_sum, nq(2)
	list ptgi_sum ptgi_mdn, sep(0)
	recode ptgi_mdn (1 = 0) (2 = 1)
	*tab ptgi_mdn
	
	* trauma_cog - median split

	xtile trauma_cog_mdn = trauma_cog_sum, nq(2)
	list trauma_cog_sum trauma_cog_mdn, sep(0)
	recode trauma_cog_mdn (1 = 0) (2 = 1)	
	tab trauma_cog_mdn	

	* digital self-confidence - median split

	xtile digi_mdn = digi_sum, nq(2)
	list digi_sum digi_mdn, sep(0)
	digi_mdn (1 = 0) (2 = 1)	
	*tab digi_mdn	
	
	* aces - median split
	
	summ aces_sum, detail	
	xtile aces_mdn = aces_sum, nq(2)
	list aces_sum aces_mdn, sep(0)
	recode aces_mdn (1 = 0) (2 = 1)	
	tab aces_mdn	

	* HIV stigma - median split	

	summ hiv_stigma_sum, detail	
	xtile hiv_stigma_mdn = hiv_stigma_sum, nq(2)
	list hiv_stigma_sum hiv_stigma_mdn, sep(0)
	recode hiv_stigma_mdn (1 = 0) (2 = 1)	
	tab hiv_stigma_mdn

	* privacy concerns - recode: 1 = "somewhat" or "very concerned"

	gen priv_bin = 0
	replace priv_bin = 1 if (app4 > 1) 
	*list app4 priv_bin, sep(0)
	
	* save

	save, replace		

	* ///////////// Model 0a (logit): y_i = privacy concerns - exploratory (condition-agnostic; N = 30) /////////////
	
	
	foreach i in gend_bin sexual_minority hiv_stigma_mdn aces_mdn {
		logit priv_bin `i', or nolog
		} 

	* transform outcomes // values already converted to "." at recode

	gen app3_bin = 0
	replace app3_bin = 1 if (app3_rev > 1)		
		
	foreach i in intervention1_rev intervention4_rev intervention6_rev /// 
		intervention7_rev intervention8_rev intervention9_rev intervention10_rev {	
		gen `i'_bin = 0
		`i'_bin = 1 if (`i' > 2)		
		*list `i' `i'_bin, sep(0)		
}				
	foreach i in intervention11_rev intervention12_rev /// 
		intervention14_rev intervention15_rev intervention16_rev {	
		gen `i'_bin = 0
		replace `i'_bin = 1 if (`i' > 1)
		*list `i' `i'_bin, sep(0)		
}			

	* ////////////////// Model 0b (logit): y_i = acceptability - exploratory (tx arm only; n = 22) //////////////////	
	
	foreach i in gend_bin race_bin ethnicity educ_bin ///
		q1_audit_bin asi_d10a_bin asi_d8a_bin asi_opiates_bin asi_d13a_bin ///
		ptsd_clinical_cutoff pcl_bin trauma_cog_mdn ptgi_mdn digi_mdn {
		logit intervention7_rev_bin `i' if arm == 1, or nolog 
		} 	
				
		* -------------------------------------- *
		*    End of nola_gem_acceptability.do    *			
		* -------------------------------------- *	 
	 

