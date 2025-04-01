.PHONY: unit_test joint_test gen

PWD=$(shell pwd)
PROTO_DIR=${PWD}/proto
GENERATE_OUT_DIR=${PWD}/gen
export ROOT_DIR=${PWD}/temp
export PROJECT_DIR=${PWD}
export LD_LIBRARY_PATH=${ROOT_DIR}/lib:${ROOT_DIR}/lib64:${ROOT_DIR}/usr/lib:${ROOT_DIR}/usr/lib64
export CONFIG_FILE=${ROOT_DIR}/opt/bmc/libmc/lualib/test_common/test_config.cfg
export PROJECT_NAME=account   # 配置组件的名称

LUA=${ROOT_DIR}/opt/bmc/skynet/lua
SKYNET=${ROOT_DIR}/opt/bmc/skynet/skynet

empty :=
space := $(empty) $(empty)
unit_test:
	@chmod +x ${LUA} && ulimit -n 1024 && ${LUA} test/unit/test.lua -v

test_account.conf:
	@chmod +x ${SKYNET} && ulimit -n 1024 && ${SKYNET} test/integration/test_account.conf

joint_test: test_account.conf

gen:
	@cd ${TPL_DIR} && make \
        PROTO_DIR=${PROTO_DIR} \
        BUILD_DIR=${TPL_DIR}/temp \
        GENERATE_OUT_DIR=${GENERATE_OUT_DIR} \
        PROTO_OUT_DIR=${TPL_DIR}/temp/${PROJECT_NAME} \
        PROJECT_NAME=${PROJECT_NAME} \
        gen
