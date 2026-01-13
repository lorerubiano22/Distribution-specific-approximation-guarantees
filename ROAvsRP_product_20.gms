option optCr = 0;
option limrow = 0; option limcol=0;
option seed= 2562;
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


set ec error components /ec1*ec2/;

parameter

** ROA

roa, Zroa, a, b, v, vv, eta, VAR, brk, diff, corr(i,ec)

revscheme  rev shap  1 or 2 or 3

*************  Grid  ***************
V_Sample(i,g,level) 
VV_Sample(g,level)    
W_Sample(i,g,level)  
Zroa_Sample(level) 
Z_Sample(level)   
diff_Sample(level)    
VAR_sample(level)
   
rep_Y(level,i)
rep_X(level,i,g)
rep_tX(level,g)
repy        'summary report'
    
handle(level)     'store the instance handle'

;

VAR_sample(level)=5*ord(level);

*************************************************************************************************************
********** Revenue shape **************  ref r(i)= card(i) / (1 + exp( -ord(i))); then max= 20 min = 14.6212
*************************************************************************************************************


revscheme=1;

********************************************


if(revscheme=1,
     r(i)=(1 + card(i) - ord(i))$(ord(i)<card(i));
);
if(revscheme=2,
r('i1')=20;
r('i2')=19.8356;
r('i3')=19.7534;
r('i4')=19.5676;
r('i5')=18;
r('i6')=10;
r('i7')=8;
r('i8')=7;
r('i9')=5.8;
r('i10')=4.5;
r('i11')=3.9;
r('i12')=2.7;
r('i13')=1.8;
r('i14')=1.5;
r('i15')=1;
r('i16')=0.8;
r('i17')=0.7;
r('i18')=0.5;
r('i19')=0.2;
r('i20')=0;
);
if(revscheme=3,
r('i1')=20;
r('i2')=19.8356;
r('i3')=19.7534;
r('i4')=19.5676;
r('i5')=18.7;
r('i6')=18;
r('i7')=17;
r('i8')=15.6;
r('i9')=14.1;
r('i10')=12.1;
r('i11')=10.6;
r('i12')=9.9;
r('i13')=8.8;
r('i14')=8.1;
r('i15')=7.4;
r('i16')=5.6;
r('i17')=4.6;
r('i18')=3.6;
r('i19')=2.6;
r('i20')=0;
);

***************************************
*************************************************************************************************************
*************************************************************************************************************

**************  GRID   **************


assort.solveLink = 6;  
assort.limCol    = 0;
assort.limRow    = 0;
assort.solPrint  = %solPrint.Quiet%;





loop(level,

VAR=VAR_sample(level);

v(i,g) = uniform(-sqrt(VAR*3),sqrt(VAR*3));
vv(g) = uniform(-sqrt(VAR*3),sqrt(VAR*3));

a(i,g) = exp(v(i,g));
b(g) = exp(vv(g));

w(i,g) = a(i,g)/b(g);

**** ROA ********

roa(o) = sum(i$(ord(i) <= ord(o)) , r(i) / card(G) * sum(g, a(i,g) / ( b(g) + sum(ii$(ord(ii) <= ord(o)), a(ii,g) ) ) ) );

Zroa = smax(o, roa(o));
*****************

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
   


execute_unload "ROA_RP_20_Products.gdx"

$exit

