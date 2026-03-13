#-------------------------------------------------------------------------------------------------------
# 定义变量方便维护
UVM_HOME = /path/to/your/uvm-1.2# 如果你的 vcs 自带了 uvm，通常可以省略或用 -ntb_opts uvm
TEST     = my_test_name# 默认跑的用例名 不指定也没事，可以在tb里改 更专业的方法是tb中run_test();然后在sim命令行里加 +UVM_TESTNAME=$(TEST）来指定运行不同的test
SEARCH_PATH := ./env

all  : clean csch sch vcs sim verdi
com  : vcs sim
clc  : clean csch
#-------------------------------------------------------------------------------------------------------
sch : 
	# 注意：UVM 通常包含 .sv 文件，所以建议加上 *.sv
	echo "+incdir+$(SEARCH_PATH)" > ./filelist.f
	find ./rtl -name "*.sv" >> ./filelist.f
	find ./rtl -name "*.sv" >> ./filelist.f
	find ./tb  -name "*.sv" >> ./filelist.f 
	@echo "Verilog/SystemVerilog File paths have been appended to filelist.f"
csch :
	rm -f ./filelist.f
	@echo "filelist.f has been removed."
#-------------------------------------------------------------------------------------------------------
vcs   :
	vcs     \
		-full64 -sverilog \
		-l compile.log \
		-timescale=1ns/1ns \
		-f filelist.f  \
		-debug_access+all -kdb -lca \
		+vcs+fsdbon \
		+define+MP_FSDB \

#-------------------------------------------------------------------------------------------------------
sim   :
		./simv -l sim.log \
			+fsdbfile+tb.fsdb &
#-------------------------------------------------------------------------------------------------------
verdi  :
	verdi -sv -f filelist.f -ssf tb.fsdb &
#-------------------------------------------------------------------------------------------------------
clean  :
	 rm  -rf  *~  core  csrc  simv* vc_hdrs.h  ucli.key  urg* *.log  novas.* *.fsdb* verdiLog  64* DVEfiles *.vpd