OPENROAD_MODULES = yosys TritonRoute
SRC_PATH = OpenROAD/src
BUILD_PATH = OpenROAD/build/src

ifneq ($(shell which docker),)
  $(info Using docker as default build type)
  BUILD_DEP = docker_%
else
  $(info docker installation not found. Defaulting to local build)
  BUILD_DEP = cmake_%
endif

default: build_all

clone_all: clone_OpenROAD $(addprefix clone_,$(OPENROAD_MODULES))
	@

clone_OpenROAD:
	git submodule update --init --recursive
	
	# --recursive doesn't recurse all the way
	cd OpenROAD && \
	git submodule update --init --recursive
	
	cd $(SRC_PATH)/OpenDB && \
	git submodule update --init --recursive

clone_yosys:
	if ! [ -d $(SRC_PATH)/yosys ]; then \
		git clone --recursive git@github.com:The-OpenROAD-Project/yosys.git $(SRC_PATH)/yosys; \
	fi

clone_TritonRoute:
	if ! [ -d $(SRC_PATH)/TritonRoute ]; then \
		git clone --recursive git@github.com:The-OpenROAD-Project/TritonRoute.git $(SRC_PATH)/TritonRoute --branch alpha2; \
	fi

docker_%: clone_%
	docker build -t openroad/$(shell echo $* | tr A-Z a-z) -f $(SRC_PATH)/$*/Dockerfile $(SRC_PATH)/$*

cmake_OpenROAD: clone_OpenROAD
	mkdir -p OpenROAD/build
	cd OpenROAD/build && \
	cmake $(CMAKE_OPTS) .. && \
	make -j4

cmake_yosys:
	cd $(SRC_PATH)/yosys && \
	make -j4

cmake_TritonRoute:
	mkdir -p $(SRC_PATH)/TritonRoute/build
	cd $(SRC_PATH)/TritonRoute/build && \
	cmake $(CMAKE_OPTS) .. && \
	make -j4

build_all: $(addprefix $(BUILD_PATH)/,$(OPENROAD_MODULES))
	@

$(BUILD_PATH)/%: $(BUILD_DEP)
	mkdir -p $(BUILD_PATH)
	rm -rf ./$@
	container_id=$$(docker create openroad/$(shell echo $* | tr A-Z a-z)) && \
	docker cp $$container_id:/build $@ && \
	docker rm -v $$container_id
