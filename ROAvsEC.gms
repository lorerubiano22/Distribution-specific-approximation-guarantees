option optCr = 0;
option limrow = 0; option limcol=0;
option seed= 2755;
option SolPrint=off;
option mip=Gurobi;

Sets
I products /i1*i20/
O revenue ordered assortment /o1*o20/
G realizations /g1*g500/
level Variance levels /1*6/

;

alias (i,ii);
alias (g,gg);




Parameters
w(i,g) weight
r(i) revenue
;

Variable Z objective function value;

NonNegative Variables
X(i,g) choice prob of i for g
tX(g) choice prob opt-out for g
Binary Variable Y(i) 1 if i in assortment (0 otherwise)

Equation of;
of .. sum(i, r(i) * sum(g, X(i,g) )/card(G) ) =E= Z;

Equation sumOne;
sumOne(g) .. tX(g) + sum(i, X(i,g)) =E= 1;

Equation couple;
couple(i,g) .. X(i,g) =L= Y(i);

Equation iia1;
iia1(i,g) .. X(i,g) =L= w(i,g) * tX(g);
Equation iia2;

iia2(i,g) .. X(i,g) =G= w(i,g) * tX(g) + w(i,g) * (Y(i) - 1);

model assort /all/;



** DATA **


set ec error components /ec1*ec3/;

parameter

** ROA

roa, Zroa, a, b, v, sigma, vv, eta, brk, diff, corr(i,ec)
sigma_sample(level)
/
1 0.25
2 0.5
3 1
4 2
5 3
6 4
/
s  differents corr (substitution patterns?) 1 or 2 or 3

*************  Grid  ***************
V_Sample(i,g,level) 
VV_Sample(g,level)    
W_Sample(i,g,level)  
Zroa_Sample(level) 
Z_Sample(level)   
diff_Sample(level)    
rep_Y(level,i)
rep_X(level,i,g)
rep_tX(level,g)
repy        'summary report' 
handle(level)     'store the instance handle'

*****  for computing b opt-out attractivity
optoutRelation(ec)
sigmaTotal
aux sigma relation aux=1<= sigma1 =sigma2 = sigma3 SIGMA and aux=0<= sigma1+sigma2+sigma3=SIGMA
;

s=6;
aux=1;
* V = uniform(a,b) with b = sqrt(VAR * 3) and a = -b => variance is equal to VAR
eta(ec,g) = normal(0,1);

r(i) = (1 + card(i) - ord(i))$(ord(i)<card(i));
***************************************


**************  GRID   **************


assort.solveLink = 6;  
assort.limCol    = 0;
assort.limRow    = 0;
assort.solPrint  = %solPrint.Quiet%;




$include corrComp.gms

sigmaTotal= sum(ec$(sum(i,corr(i,ec))>1),1);
optoutRelation(ec)$(sum(i$(ord(i)=card(i)),corr(i,ec))>0)=1;

loop(level,

if(aux=1,
sigma=sigma_sample(level);
else
sigma=sigma_sample(level)/sigmaTotal;
);


v(i,g) = sigma * (eta("ec1",g)*corr(i,"ec1") + eta("ec2",g)*corr(i,"ec2")+ eta("ec3",g)*corr(i,"ec3")) ;
vv(g)= sum((ec),sigma *eta(ec,g)*optoutRelation(ec));


a(i,g) = exp(v(i,g));
b(g) = exp(vv(g));

w(i,g) = a(i,g)/b(g);

**** ROA ********

roa(o) = sum(i$(ord(i) <= ord(o)) , r(i) / card(G) * sum(g, a(i,g) / ( b(g) + sum(ii$(ord(ii) <= ord(o)), a(ii,g) ) ) ) );

Zroa = smax(o, roa(o));
*****************
$onecho > gurobi.opt
numericfocus 3
$offecho
assort.optfile=1;

solve assort max Z using mip;

V_Sample(i,g,level)=v(i,g);
VV_Sample(g,level)=vv(g);
W_Sample(i,g,level)=w(i,g); 
Zroa_Sample(level)=Zroa;
*****************

handle(level) =assort.handle;
);

repeat
   loop(level$handlecollect(handle(level)),
***************** Collecting output
        rep_Y(level,i)= Y.l(i);
        rep_X(level,i,g)=X.l(i,g);
        rep_tX(level,g)= tX.l(g);
        Z_Sample(level)=Z.l;
        
******  GAP ******************   
        diff_Sample(level)=100 * (Zroa_Sample(level) - Z_Sample(level))/Z_Sample(level);
        
******* General output *****
        repy(level,'modelstat') =  assort.modelStat ;
        repy(level,'solvestat') = assort.solveStat ;
        repy(level,'resusd'   ) = assort.resUsd;
        repy(level,'objval')    = assort.objVal;
      display$handledelete(handle(level)) 'trouble deleting handles';
*indicate that we have loaded the solution
      handle(level) = 0;    
   );
*// wait until all models are loaded
until card(handle) = 0;  
   


execute_unload "ROA_EC.gdx"

$exit

