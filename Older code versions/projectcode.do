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


********************dependent variable****************************************
// euftf: European Union: European unification go further (10) or gone too far (0)


********************independent variables**************************************
// hincfel is recoded to make it more intuitive to work with (0=doing very badly; 3=doing well)
recode hincfel (4=0) (3=1) (2=2) (1=3), gen(subjective_inc)

// recode gndr into dummy variable with 0=female, 1=male
recode gndr (2=0) (1=1), gen(male)
label variable male "Gender: Male"
label define genderlbl 1 "male" 0 "female"
label value male genderlbl
numlabel genderlbl, add

//recode ctzcntrinto dummy variable with 0=not citizen of ESS country 1=citizen of ESS country
recode ctzcntr (2=0), gen(country_citizen)
label variable country_citizen "Citizenship: Citizen of Residence country"
label define citizenlbl 0 "No" 1 "Yes"
label value country_citizen citizenlbl
numlabel citizenlbl, add

// recode 
recode mnactic (1=0) (2/9=1), gen(unemployed)
label variable unemployed "Employment status: not in paid work"