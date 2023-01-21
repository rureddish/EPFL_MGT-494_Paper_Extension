/************************************************************************/
/* scale.ado										*/
/*	A multi-dimensional scaling of the distance matrix			*/
/*	for STATA 6.0									*/
/*			by	Jean-Pierre Dube						*/
/*				Northwestern University					*/
/*				November 8, 1997						*/
/*												*/
/*			reference:								*/
/*												*/
/*	Mardia, K.V., J.T. Kent, J.M. Bibby.  "Multidimensional 		*/
/*	Scaling." in MULTIVARIATE ANALYSIS.  (Academic Press: New York,	*/
/*	1979), 394-423.									*/
/*												*/
/************************************************************************/
/************************************************************************/
/*  To invoke this command type:							*/
/*	>>scale D1 D2 dist, dim()							*/
/*												*/
/*  NOTE:											*/
/*	(1) This procedure is LIMITED to 800 points, due to STATA's		*/
/*	limitations on the use of external matrices.				*/
/*												*/
/*	(2) D1 and D2 are the row and column positions in Distance		*/
/*	matrix, and dist is the value.						*/
/*	   											*/
/*	(3) dim() denotes the number of coordinates.				*/
/*	   											*/
/*	   											*/
/*  OUTPUT:   										*/
/*	   	lambda=vector of Eigenvalues						*/
/*	   	V=vector of eigenvectors						*/
/*	   	C1-C`dim'=coordinates associated with `dim' largest		*/
/*			eigenvalues of centred distance matrix			*/
/*	   	Goodness-of-fit measures (as defined in reference):		*/
/*		a1`dim' = % of sum abs(eigenvalues) explained by `dim' 	*/
/*		largest values								*/
/*		a2`dim' = % of sum squared(eigenvalues) explained by		*/
/*		`dim' largest values squared						*/
/************************************************************************/

program define scale
 version 6.0
set matsize 800

#delimit ;

/*FIRST I TAKE INFO. FROM COMMAND LINE AND ORGANIZE IT*/
local varlist	"req ex min(1)";
local options	"dim(int -99)";

parse "`*'";

if `dim'<1{;
	if `dim'==-99{;
		di in red "option dim() required!!!";
		exit 198};
	di in red "dim(`dim') is invalid";
	exit 198};	

parse "`varlist'", parse(" ");

/*NOW CREATE THE SQUARED DISTANCE MATRIX divided by two*/
quietly{;
local T=sqrt(_N);	/*should give number of points in the space*/
tempname A;
mat `A'=J(`T',`T',0);
local i=1;
while `i'<=_N{;
	local row=`1'[`i'];
	local col=`2'[`i'];
	local distan=`3'[`i'];
	mat `A'[`row',`col']=(-.5)*(`distan')^(2);
local i=`i'+1};
};	/*end quietly*/

/*NOW SCALE THE DISTANCE MATRIX*/
tempname eye H iota ii ii1 invT BB B;
scalar `invT'=1/`T';
mat `iota'=J(`T',1,1);
mat `ii'=`iota'*`iota'';
mat `ii1'=`ii'*`invT';
mat `eye'=I(`T');
mat `H'=`eye'-`ii1';
mat `BB'=`H'*`A';
mat `B'=`BB'*`H';

quietly{;
mat symeigen V lambda=`B';
tempvar C_tot C_t2;
local k=1;
gen `C_tot'=0;
gen `C_t2'=0;
while `k'<=`dim'{;				/*get `dim' largest eigenvals*/
	tempname CC`k';
	tempvar CC`k' CC`k'_2;
	gen `CC`k''=lambda[1,`k'];
	gen `CC`k'_2'=`CC`k''^2;		/*get the square of lambda*/
	scalar `CC`k''=lambda[1,`k'];
	scalar `CC`k''=`CC`k''^(.5);
	mat C`k'=V[1...,`k'];
	mat C`k'=C`k'*`CC`k'';
	replace `C_tot'=`C_tot'+`CC`k'';	/*sum of eigenvalues*/
	replace `C_t2'=`C_t2'+`CC`k'_2';	/*sum of squared eigenvalues*/
local k=`k'+1};

/*Goodness-of-fit Statistic*/
tempvar lam_tot lam_t2;
local l=1;
gen `lam_tot'=0;
gen `lam_t2'=0;
while `l'<=`T'{;
	tempvar lam`l' la`l'_2;
	gen `lam`l''=lambda[1,`l'];
	replace `lam`l''=abs(`lam`l'');
	gen `la`l'_2'=`lam`l''^2;
	replace `lam_tot'=`lam_tot'+`lam`l'';
	replace `lam_t2'=`lam_t2'+`la`l'_2';
local l=`l'+1};
};	/*end quietly*/

gen a1`dim'=100*`C_tot'/`lam_tot';
gen a2`dim'=100*`C_t2'/`lam_t2';

/*THIS PART CREATES AND PRINTS THE OUTPUT TABLE IN STATA*/
local aa1=a1`dim';
local aa2=a2`dim';
di _newline(2)
" -----------------------------------------------------------------------------";
di 
"*****  Results for Multidimensional Scaling Procedure of Distance Matrix  *****";
di _newline	" number of points =  "  `T';
di		" dimension of coordinates =  "  `dim';
di _newline	"Goodness-of-fit: ";
di 		"---------------";
di		"Alpha1" `dim' " = " `aa1';
di 		"Alpha2" `dim' " = " `aa2';
di _newline	"Relevant Eigenvalues: ";
di		"--------------------";
local m=1;
while `m'<=`dim'{;
	local mm`m'=lambda[1,`m'];
	di	"lambda" `m' " = " `mm`m'';
local m=`m'+1};
di _newline
" -----------------------------------------------------------------------------";
end;

exit;



