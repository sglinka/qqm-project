version 18.5  
clear all         
capture log close 
* --------------------------------------------------
* Set macro
global path "C:\Users\sophi\OneDrive\Desktop\stata\project"
*--> this global path has to be adapted to your specific path!
log using "$path\project_tryout.log", replace // if you want to create a log file that records all output
use "$path\ESS11.dta", clear

encode cntry, gen(country)
// encode string variable to numerical 
numlabel country, add
tab country
//proceed to delete non-EU countries in the dataset: 4 Switzerland, 10 UK, 15 Israel, 16 Iceland, 20 Montenegro, 22 Norway, 25 Serbia
drop if inlist(country, 4,10,15,16,20,22,25)
distinct country //21 distinct countries remaining 


*merge country level variables
*Country-level data set; relevant command: merge 
*key variable is: country
frame create countrylevel // create new frame
frame change countrylevel // change to new frame in order to create country level data set
import excel "$path\macrodata.xlsx", firstrow // firstrow takes first row of excel sheet as variable names
label variable netcontrib "Net Contributor Status"

sort country // data have to be sorted in both data sets
save "$path\countrylevelvar.dta", replace

frame change default // switch back to ESS data 

sort country
merge m:1 country using "$path\countrylevelvar.dta"
*m:1  indicates that many individuals are to be connected with 1 country each
erase "$path\countrylevelvar.dta" // we don't really need this dataset anymore and can delete it straight away


********************dependent variable****************************************
// euftf: European Union: European unification go further (10) or gone too far (0)


********************independent variables**************************************
// hincfel is recoded to make it more intuitive to work with (1=doing very badly; 4=doing well)
recode hincfel (4=1) (3=2) (2=3) (1=4), gen(subjective_inc)
label variable subjective_inc "Subjective financial security"
label define subinclbl 1 "very bad" 2 "bad" 3 "good" 4 "very good"
label value subjective_inc subinclbl
numlabel subinclbl, add

// recode gndr into dummy variable with 0=female, 1=male
recode gndr (2=0) (1=1), gen(male)
label variable male "Gender: Male"
label define genderlbl 1 "male" 0 "female"
label value male genderlbl
numlabel genderlbl, add

//recode ctzcntr into dummy variable with 0=not citizen of ESS country 1=citizen of ESS country
recode ctzcntr (2=0), gen(country_citizen)
label variable country_citizen "Citizenship: Citizen of Residence country"
label define citizenlbl 0 "Foreigner" 1 "Citizen"
label value country_citizen citizenlbl
numlabel citizenlbl, add

// recode employment status
recode mnactic (1=0) (2/9=1), gen(unemployed)
label variable unemployed "Employment status: not in paid work"

//recode education 
recode eisced (1/2=0) (3/5=1) (6/7=2) (55=.), gen(education)
label variable education "Education level"
label define educationlbl 0 "low" 1 "middle" 2 "high"
label value education educationlbl
numlabel educationlbl, add

//recode hinctnta to include an explicit category for refusals
recode hinctnta (.a/.b=11), gen(objective_inc)
label variable objective_inc "Income decile, all sources of income"
label define objective_inclbl 1 "1st decile" 2 "2nd decile" 3 "3rd decile" 4 "4th decile" 5 "5th decile" 6 "6th decile" 7 "7th decile" 8 "8th decile" 9 "9th decile" 10 "10th decile" 11 "refusal/don't know"
label value objective_inc objective_inclbl
numlabel objective_inclbl, add

******* regression models **********************
//empty model - find out ICC 

mixed euftf || country:
estat icc

//preferred spec: model with first-level predictors, no greece, robust standard errors
mixed euftf i.subinc_threecat agea i.male i.country_citizen lrscale i.education i.unemployed hinctnta || country: if country!=11, vce(robust) 


//base model: 
mixed euftf subjective_inc agea i.male i.country_citizen lrscale i.education i.unemployed hinctnta || country: 
****robustness test: alternative subjective_inc specification**************
mixed euftf subjective_inc agea i.male i.country_citizen lrscale i.education i.unemployed hinctnta|| country:, vce(robust)

mixed euftf i.subjective_inc agea i.male i.country_citizen lrscale i.education i.unemployed hinctnta|| country:, vce(robust)

drop subinc_threecat
recode subjective_inc (1/2=1 "difficult/very difficult to get by on present income") (3=2 "coping") (4=3 "very easy"), gen(subinc_threecat)
mixed euftf i.subinc_threecat agea i.male i.country_citizen lrscale i.education i.unemployed hinctnta|| country:, vce(robust) // three-category measure

****robustness test: how to include objective income?******

//concerning hinctnta
mixed euftf i.subinc_threecat agea i.male i.country_citizen lrscale i.education i.unemployed hinctnta || country:, vce(robust) // include greece continuous
mixed euftf i.subinc_threecat agea i.male i.country_citizen lrscale i.education i.unemployed hinctnta || country: if country!=11, vce(robust) // exclude greece continuous
mixed euftf i.subinc_threecat agea i.male i.country_citizen lrscale i.education i.unemployed i.hinctnta || country:, vce(robust) //include greece exclude missings (categorical hinctnta)
mixed euftf i.subinc_threecat agea i.male i.country_citizen lrscale i.education i.unemployed i.objective_inc || country:, vce(robust) //include greece include missings (categorical hinctnta)
mixed euftf i.subinc_threecat agea i.male i.country_citizen lrscale i.education i.unemployed|| country:, vce(robust) //exclude hinctnta alltogether
mixed euftf i.subinc_threecat agea i.male i.country_citizen lrscale i.education i.unemployed|| country: if country!=11, vce(robust) //exclude hinctnta and greece alltogether

//concerning unemployment
mixed euftf i.subinc_threecat agea i.male i.country_citizen lrscale i.education hinctnta || country: if country!=11, vce(robust) //excluding employment status

//concerning education
mixed euftf i.subinc_threecat agea i.male i.country_citizen lrscale education i.unemployed hinctnta || country: if country!=11, vce(robust) 
 //education as continuous
mixed euftf i.subinc_threecat agea i.male i.country_citizen lrscale i.unemployed hinctnta || country: if country!=11, vce(robust) 
 //exclude education


*** robustness test: further variables**************************************

//concerning political affiliation
mixed euftf subjective_inc agea i.male i.country_citizen i.education i.unemployed i.objective_inc|| country:, vce(robust) //exclude
mixed euftf subjective_inc agea i.male i.country_citizen i.lrscale i.education i.unemployed i.objective_inc|| country:, vce(robust) //as categorical

//mixed euftf subjective_inc agea i.male i.country_citizen trstplt i.education i.unemployed i.objective_inc|| country:, vce(robust) //trust politicians instead? But hard to argue that distrust --> feeling about income nowadays :/ so probably not


************regression diagnostics***********************************
//proxy ols to perform hettest and vif
regress euftf i.subinc_threecat agea i.male i.country_citizen lrscale i.education i.unemployed hinctnta i.country
estat hettest

regress euftf i.subinc_threecat agea i.male i.country_citizen lrscale i.education i.unemployed hinctnta, vce(cluster country)
estat vif


************Multilevel Moderation Hypothesis testing*****************************
mixed euftf c.netcontrib##i.subinc_threecat agea i.male i.country_citizen lrscale i.education i.unemployed hinctnta || country: if country!=11, vce(robust)

margins, at (netcontrib = (0 1) subinc_threecat=(1 2 3))
marginsplot


