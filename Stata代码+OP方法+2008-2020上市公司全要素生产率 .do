* 切换到数据所在路径
cd D:\全要素生产计算\




* 导入数据
import excel 源数据.xlsx, firstrow clear

* 选择2008-2020年数据
keep if year>=2008 & year<=2020

* 剔除了既发行A股又发行B股的上市公司
drop if AB股交叉码!=""

* 剔除金融行业
drop if regexm(行业代码, "J")

* 变量定义(单位转为万元)
gen 总产出=营业收入/10000
gen 资本投入=固定资产净额/10000
gen 劳动力投入=员工人数
* I表示企业的投资
gen 投资=购建固定资产无形资产和其他长期资产支付的现金/10000

* 缩尾处理
winsor2 总产出  资本投入 劳动力投入 投资, cuts(1 99) replace by(year)

* 定义变量
gen lnY=ln(1+总产出)
gen lnL=ln(1+劳动力投入)
gen lnK=ln(1+资本投入)
gen lnI=ln(1+投资)
* 企业年龄
gen Age=year-year(上市日期)+1
* State表示企业是否为国有企业
gen State=( regexm(股权性质, "国有"))  if 股权性质!=""

* EX是表示企业是否参与出口活动的虚拟变量
gen EX=(海外业务收入>0)

* Exit 退出变量
bys stkcd: egen 是否ST或PT=max(年末是否ST或PT)
gen Exit=(摘牌日期!=. | 是否ST或PT==1 )


* 行业虚拟变量
gen Ind=substr(行业代码, 1, 1)
replace Ind=substr(行业代码, 1, 2) if Ind=="C"

* 省份虚拟变量
gen reg=省份


* 剔除缺失值
foreach i in lnY lnL lnK Age State EX Exit {
    drop if `i'==.
}

* OP方法计算
* 安装opreg， 输入命令findit opreg找到对应命令进行安装
xtset stkcd year
xi: opreg lnY, exit(Exit) state(Age lnK) proxy(lnI) free(lnL i.Ind i.year i.reg) cvars(State EX )   vce(bootstrap, seed(1357) rep(5)) 
est store OP

gen tfp_op=lnY - _b[lnL]*lnL-_b[lnK]*lnK


keep stkcd 证券代码 year tfp_op
save 运行结果.dta, replace
export excel 结果导出.xlsx, firstrow(var) replace



* 缩尾后描述性统计
winsor2 tfp_op, cuts(1 99) replace by(year)
tabstat tfp_op, c(s) s(N mean sd min p50 max ) format(%10.3f)
