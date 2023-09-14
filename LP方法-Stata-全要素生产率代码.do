
*= 需要安装外部命令levpet
net install st0060.pkg, from("http://www.stata-journal.com/software/sj4-2/")

*= 切换到数据所在路径
cd D:\全要素生产率LP\


export excel 源数据.xlsx, firstrow(var) replace

* 导入数据
import excel 源数据.xlsx, firstrow clear

* 剔除金融行业
drop if regexm(行业代码, "J")

* 剔除已退市的上市公司
drop if 退市日期!=.

* 剔除IPO当年及以前的数据
drop if year<=real(substr(上市日期, 1, 4))

* 选择2000-2020年数据
keep if year>=2000 & year<=2020

* 剔除了既发行A股又发行B股的上市公司
drop if AB股交叉码!=""

* 剔除了样本区间内ST、*ST和PT的公司
drop if 年末是否ST或PT==1


* 变量定义(单位转为万元)
gen 总产出=营业收入/10000
gen 资本投入=固定资产净额/10000
gen 劳动力投入=员工人数
replace 折旧摊销=0 if 折旧摊销==.
gen 中间投入=(营业成本+销售费用+管理费用+财务费用-折旧摊销-支付给职工以及为职工支付的现金)/10000


* 定义变量
gen lnY=ln(1+总产出)
gen lnL=ln(1+劳动力投入)
gen lnM=ln(1+中间投入)
gen lnK=ln(1+资本投入)

* 剔除缺失值
foreach i in lnY lnL lnM lnK {
    drop if `i'==.
}

* 缩尾处理
winsor2 lnY lnL lnM lnK, cut(1 99) replace by(year)

* LP方法计算
xtset stkcd year
levpet lnY, free(lnL) proxy(lnM) capital(lnK)
predict tfp, omega

* 取对数
gen lntfp=ln(tfp)

* 描述性统计
tabstat lntfp, c(s) s(N mean sd min p50 max) format(%10.3f)

 keep stkcd year 证券代码 lntfp

save 运行结果.dta, replace
export excel 结果导出.xlsx, firstrow(var) replace

* 走势图
collapse (mean) lntfp, by(year) 
line lntfp year, ytitle("lntfp")




