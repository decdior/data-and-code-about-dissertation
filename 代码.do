clear
cd "C:\Users\decdior\Desktop\毕业论文\数字化与全要素1800"

use 资产规模
merge 1:1 stkcd year using  ROA
keep if _merge==3
drop _merge
merge 1:1 stkcd year using 财务杠杆
keep if _merge==3
drop _merge
merge m:m stkcd  using 行业代码及年龄
keep if _merge==3
drop _merge
gen age=year-Estbdt
merge 1:1 stkcd year using top1
drop _merge
merge 1:1 stkcd year using 董事会结构特征
drop _merge
merge 1:1 stkcd year using 管理层持股比例
drop _merge

merge 1:1 stkcd year using 高管前三名薪酬总额
drop _merge
gen salary=ln(TOP3Salary+1)
label var salary "前三名薪酬的自然对数"
///////////////////////////////////制造业取两位其他行业取一位
gen ind=substr(Nindcd,1,3)

merge 1:1 stkcd year using 财务指标
drop _merge
merge 1:1 stkcd year using 综合财务指标
drop _merge

save 控制变量,replace 


////////////////////////////合并解释变量和被解释变量

clear
use 控制变量
merge 1:1 stkcd year using 07-20数字化程度
keep if _merge==3
drop _merge

merge 1:1 stkcd year using 00-20LP全要素生产率
drop _merge

merge 1:1 stkcd year using 08-20OP全要素生产率
drop _merge


save 数字化与全要素生产率,replace 


/////////////////////////////////////缩尾处理

clear
use 数字化与全要素生产率
gen cipin1=ln(AITechnology+BlockChainTechnology+CloudComputingTech+BigDataTechnology+DigitalTechApplication+1)

winsor cipin1, gen(cipin1_w) p(0.01)
winsor lntfp , gen(lntfp_w) p(0.01)
winsor tfp_op , gen(tfp_op_w) p(0.01)

winsor ROA, gen(ROA_w) p(0.01)
bys ind year:egen x=sum(OperatingEvenue)
gen com=OperatingEvenue/x
winsor com, gen(com_w) p(0.01)

winsor lev, gen(lev_w) p(0.01)
winsor BM, gen(BM_w) p(0.01)
winsor Growth, gen(Growth_w) p(0.01)

winsor age, gen(age_w) p(0.01)
winsor Size, gen(Size_w) p(0.01)
gen board = ln(Director+1)
winsor board, gen(board_w) p(0.01)
winsor Shrcr1, gen(Shrcr1_w) p(0.01)
replace Independent = Independent/Director
winsor Independent, gen(Independent_w) p(0.01)
winsor salary, gen(salary_w) p(0.01)


merge 1:1 stkcd year using 2003-2020剔除st金融
keep if _merge==3
drop _merge
merge 1:1 stkcd year using 产权性质
drop _merge
keep if substr(Nindcd,1,1)=="C"
keep if year>2010
drop if year==2020
save 数字化与全要素生产率1,replace
clear 
use 数字化与全要素生产率1


keep if lntfp_w!=.& cipin1_w!=.& Size_w!=.& ROA_w!=.& lev_w!=.& age_w!=.& board_w!=.& Shrcr1_w!=.& Growth_w!=.& tfp_op_w!=.

save 数字化与全要素生产率2,replace

///////////////////////////描述性统计

clear
use 数字化与全要素生产率2

tabstat lntfp_w tfp_op_w cipin1_w   Size_w lev_w ROA_w age_w  Growth_w   board_w    Shrcr1_w  ,s(n mean median sd min max ) c(s) f(%10.3f)


///////////////////相关系数检验
clear
use 数字化与全要素生产率2

logout,save (test) word replace: pwcorr_a  lntfp_w tfp_op_w cipin1_w  Size_w lev_w ROA_w age_w  Growth_w  board_w    Shrcr1_w  , star1(0.01) star5(0.05) star10(0.1)


///////////////////////
clear
use 数字化与全要素生产率2
xtset stkcd year 
xi:reg lntfp_w  cipin1_w  i.year i.ind
est store FE01
xi:reg lntfp_w  cipin1_w Size_w lev_w ROA_w age_w  Growth_w  board_w   Shrcr1_w i.year i.ind
est store FE02
logout, save(xtscc_sse_hhi2_ols1) word replace fix(3): /// //注意冒号
esttab  FE01 FE02, mtitle(1 2 ) ///
drop( *year* *ind*) b(%6.3f) t(%6.2f) /// //系数、标准误
star(* 0.1 ** 0.05 *** 0.01) /// //显著水平的标注
scalar(r2 r2_a N F) compress nogap 


/////////////////////////////////更换解释变量
clear
use 数字化与全要素生产率2
xtset stkcd year 
xi:reg tfp_op_w  cipin1_w i.year i.ind 
est store FE01
xi:reg tfp_op_w  cipin1_w Size_w lev_w ROA_w age_w  Growth_w  board_w   Shrcr1_w i.year i.ind
est store FE02
logout, save(xtscc_sse_hhi2_ols1) word replace fix(3): /// //注意冒号
esttab  FE01 FE02, mtitle(1 2 ) ///
drop( *year* *ind*) b(%6.3f) t(%6.2f) /// //系数、标准误
star(* 0.1 ** 0.05 *** 0.01) /// //显著水平的标注
scalar(r2 r2_a N F) compress nogap 

///////////////////////////////////个体固定效应模型

clear
use 数字化与全要素生产率2
xtset stkcd year 
xi:xtreg lntfp_w  cipin1_w  i.year ,fe
est store FE01
xi:xtreg lntfp_w  cipin1_w Size_w lev_w ROA_w age_w  Growth_w   board_w    Shrcr1_w   i.year i.ind ,fe
est store FE02
logout, save(xtscc_sse_hhi2_ols1) word replace fix(3): /// //注意冒号
esttab  FE01 FE02 , mtitle(1 2 ) ///
drop( *year* *ind*) b(%6.3f) t(%6.2f) /// //系数、标准误
star(* 0.1 ** 0.05 *** 0.01) /// //显著水平的标注
scalar(r2 r2_a N F) compress nogap 


////////////////////////中介效应
clear
use 数字化与全要素生产率2
merge 1:1 stkcd year using 上市公司本身专利申请情况1990-2020
winsor Invia, gen(Invia_w) p(0.01)
drop if cipin1_w==.
xi:reg lntfp_w  cipin1_w Size_w lev_w ROA_w age_w  Growth_w   board_w    Shrcr1_w   i.year i.ind
est store FE01
xi:reg Invia_w  cipin1_w Size_w lev_w ROA_w age_w  Growth_w   board_w    Shrcr1_w   i.year i.ind
est store FE02
xi:reg lntfp_w  cipin1_w Invia_w Size_w lev_w ROA_w age_w  Growth_w   board_w    Shrcr1_w   i.year i.ind
est store FE03
logout, save(xtscc_sse_hhi2_ols1) word replace fix(3): /// //注意冒号
esttab  FE01 FE02 FE03, mtitle(1 2 ) ///
drop( *year* *ind*) b(%6.3f) t(%6.2f) /// //系数、标准误
star(* 0.1 ** 0.05 *** 0.01) /// //显著水平的标注
scalar(r2 r2_a N F) compress nogap 

//////////////////////提升营运能力

clear
use 数字化与全要素生产率2
merge 1:1 stkcd year using 00-20营运资金
drop _merge
xtset stkcd year 
gen zhouzhuan=2*OperatingEvenue/(F010601A+L.F010601A)
winsor zhouzhuan, gen(zhouzhuan_w) p(0.01)
drop if cipin1_w==.
xi:reg lntfp_w  cipin1_w Size_w lev_w ROA_w age_w  Growth_w   board_w    Shrcr1_w   i.year i.ind
est store FE01
xi:reg zhouzhuan_w  cipin1_w Size_w lev_w ROA_w age_w  Growth_w   board_w    Shrcr1_w   i.year i.ind
est store FE02
xi:reg lntfp_w  cipin1_w zhouzhuan_w Size_w lev_w ROA_w age_w  Growth_w   board_w    Shrcr1_w   i.year i.ind
est store FE03
logout, save(xtscc_sse_hhi2_ols1) word replace fix(3): /// //注意冒号
esttab  FE01 FE02 FE03, mtitle(1 2 ) ///
drop( *year* *ind*) b(%6.3f) t(%6.2f) /// //系数、标准误
star(* 0.1 ** 0.05 *** 0.01) /// //显著水平的标注
scalar(r2 r2_a N F) compress nogap 


