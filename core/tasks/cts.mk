# Copyright (C) 2008 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cts_dir := $(HOST_OUT)/cts
cts_tools_src_dir := cts/tools

cts_name := android-cts

DDMLIB_JAR := $(HOST_OUT_JAVA_LIBRARIES)/ddmlib-prebuilt.jar
junit_host_jar := $(HOST_OUT_JAVA_LIBRARIES)/junit.jar
HOSTTESTLIB_JAR := $(HOST_OUT_JAVA_LIBRARIES)/hosttestlib.jar
TF_JAR := $(HOST_OUT_JAVA_LIBRARIES)/tradefed-prebuilt.jar
CTS_TF_JAR := $(HOST_OUT_JAVA_LIBRARIES)/cts-tradefed.jar
CTS_TF_EXEC_PATH := $(HOST_OUT_EXECUTABLES)/cts-tradefed
CTS_TF_README_PATH := $(cts_tools_src_dir)/tradefed-host/README

CTS_CORE_CASE_LIST := \
	android.core.tests.libcore.package.dalvik \
	android.core.tests.libcore.package.com \
	android.core.tests.libcore.package.sun \
	android.core.tests.libcore.package.tests \
	android.core.tests.libcore.package.org \
	android.core.tests.libcore.package.libcore \
	android.core.tests.runner

-include cts/CtsTestCaseList.mk
CTS_CASE_LIST := $(CTS_CORE_CASE_LIST) $(CTS_TEST_CASE_LIST)

DEFAULT_TEST_PLAN := $(cts_dir)/$(cts_name)/resource/plans

$(cts_dir)/all_cts_files_stamp: PRIVATE_JUNIT_HOST_JAR := $(junit_host_jar)

-include cts/CtsHostLibraryList.mk
$(cts_dir)/all_cts_files_stamp: $(CTS_CASE_LIST) $(CTS_TEST_CASES) $(junit_host_jar) $(HOSTTESTLIB_JAR) $(CTS_HOST_LIBRARY_JARS) $(TF_JAR) $(CTS_TF_JAR) $(CTS_TF_EXEC_PATH) $(CTS_TF_README_PATH) $(ACP)
# Make necessary directory for CTS
	$(hide) rm -rf $(PRIVATE_CTS_DIR)
	$(hide) mkdir -p $(TMP_DIR)
	$(hide) mkdir -p $(PRIVATE_DIR)/docs
	$(hide) mkdir -p $(PRIVATE_DIR)/tools
	$(hide) mkdir -p $(PRIVATE_DIR)/repository/testcases
	$(hide) mkdir -p $(PRIVATE_DIR)/repository/plans
	$(hide) cp -r  cts/unit/* out/host/linux-x86/cts/android-cts/repository/testcases/
	$(hide) rm out/host/linux-x86/cts/android-cts/repository/testcases/ExdroidUnit.xml
	$(hide) rm out/host/linux-x86/cts/android-cts/repository/testcases/CTS-Tradefed-windows.bat
	$(hide) cp cts/unit/ExdroidUnit.xml out/host/linux-x86/cts/android-cts/repository/plans/
	$(hide) cp cts/unit/CTS-Tradefed-windows.bat out/host/linux-x86/cts/android-cts/tools/
	
# Copy executable and JARs to CTS directory
	$(hide) $(ACP) -fp $(DDMLIB_JAR) $(PRIVATE_JUNIT_HOST_JAR) $(HOSTTESTLIB_JAR) $(CTS_HOST_LIBRARY_JARS) $(TF_JAR) $(CTS_TF_JAR) $(CTS_TF_EXEC_PATH) $(CTS_TF_README_PATH) $(PRIVATE_DIR)/tools
# Change mode of the executables
	$(foreach apk,$(CTS_CASE_LIST),$(call copy-testcase-apk,$(apk)))
	$(foreach testcase,$(CTS_TEST_CASES),$(call copy-testcase,$(testcase)))
	$(hide) touch $@

# Generate the test descriptions for the core-tests
# Parameters:
# $1 : The output file where the description should be written (without the '.xml' extension)
# $2 : The AndroidManifest.xml corresponding to the test package
# $3 : The jar file name on PRIVATE_CLASSPATH containing junit tests to search for
# $4 : The package prefix of classes to include, possible empty
# $5 : The directory containing vogar expectations files
# $6 : The Android.mk corresponding to the test package (required for host-side tests only)
define generate-core-test-description
@echo "Generate core-test description ("$(notdir $(1))")"
$(hide) java -Xmx256M \
	-classpath $(PRIVATE_CLASSPATH):$(HOST_OUT_JAVA_LIBRARIES)/descGen.jar:$(HOST_JDK_TOOLS_JAR) \
	$(PRIVATE_PARAMS) CollectAllTests $(1) $(2) $(3) "$(4)" $(5) $(6)
endef

CORE_INTERMEDIATES :=$(call intermediates-dir-for,JAVA_LIBRARIES,core,,COMMON)
BOUNCYCASTLE_INTERMEDIATES :=$(call intermediates-dir-for,JAVA_LIBRARIES,bouncycastle,,COMMON)
APACHEXML_INTERMEDIATES :=$(call intermediates-dir-for,JAVA_LIBRARIES,apache-xml,,COMMON)
SQLITEJDBC_INTERMEDIATES :=$(call intermediates-dir-for,JAVA_LIBRARIES,sqlite-jdbc,,COMMON)
JUNIT_INTERMEDIATES :=$(call intermediates-dir-for,JAVA_LIBRARIES,core-junit,,COMMON)
CORETESTS_INTERMEDIATES :=$(call intermediates-dir-for,JAVA_LIBRARIES,core-tests,,COMMON)

GEN_CLASSPATH := $(CORE_INTERMEDIATES)/classes.jar:$(BOUNCYCASTLE_INTERMEDIATES)/classes.jar:$(APACHEXML_INTERMEDIATES)/classes.jar:$(JUNIT_INTERMEDIATES)/classes.jar:$(SQLITEJDBC_INTERMEDIATES)/javalib.jar:$(CORETESTS_INTERMEDIATES)/javalib.jar

$(cts_dir)/all_cts_core_files_stamp: PRIVATE_CLASSPATH:=$(GEN_CLASSPATH)
# Why does this depend on javalib.jar instead of classes.jar?  Because
# even though the tool will operate on the classes.jar files, the
# build system requires that dependencies use javalib.jar.  If
# javalib.jar is up-to-date, then classes.jar is as well.  Depending
# on classes.jar will build the files incorrectly.
$(cts_dir)/all_cts_core_files_stamp: $(CTS_CORE_CASE_LIST) $(HOST_OUT_JAVA_LIBRARIES)/descGen.jar $(CORE_INTERMEDIATES)/javalib.jar $(BOUNCYCASTLE_INTERMEDIATES)/javalib.jar $(APACHEXML_INTERMEDIATES)/javalib.jar $(SQLITEJDBC_INTERMEDIATES)/javalib.jar $(JUNIT_INTERMEDIATES)/javalib.jar $(CORETESTS_INTERMEDIATES)/javalib.jar $(cts_dir)/all_cts_files_stamp | $(ACP)
	$(call generate-core-test-description,$(cts_dir)/$(cts_name)/repository/testcases/android.core.tests.libcore.package.dalvik,\
		cts/tests/core/libcore/dalvik/AndroidManifest.xml,\
		$(CORETESTS_INTERMEDIATES)/javalib.jar,dalvik,\
		libcore/expectations)
	$(call generate-core-test-description,$(cts_dir)/$(cts_name)/repository/testcases/android.core.tests.libcore.package.com,\
		cts/tests/core/libcore/com/AndroidManifest.xml,\
		$(CORETESTS_INTERMEDIATES)/javalib.jar,com,\
		libcore/expectations)
	$(call generate-core-test-description,$(cts_dir)/$(cts_name)/repository/testcases/android.core.tests.libcore.package.sun,\
		cts/tests/core/libcore/sun/AndroidManifest.xml,\
		$(CORETESTS_INTERMEDIATES)/javalib.jar,sun,\
		libcore/expectations)
	$(call generate-core-test-description,$(cts_dir)/$(cts_name)/repository/testcases/android.core.tests.libcore.package.tests,\
		cts/tests/core/libcore/tests/AndroidManifest.xml,\
		$(CORETESTS_INTERMEDIATES)/javalib.jar,tests,\
		libcore/expectations)
	$(call generate-core-test-description,$(cts_dir)/$(cts_name)/repository/testcases/android.core.tests.libcore.package.org,\
		cts/tests/core/libcore/org/AndroidManifest.xml,\
		$(CORETESTS_INTERMEDIATES)/javalib.jar,org,\
		libcore/expectations)
	$(call generate-core-test-description,$(cts_dir)/$(cts_name)/repository/testcases/android.core.tests.libcore.package.libcore,\
		cts/tests/core/libcore/libcore/AndroidManifest.xml,\
		$(CORETESTS_INTERMEDIATES)/javalib.jar,libcore,\
		libcore/expectations)
	$(hide) touch $@


# ----- Generate the test descriptions for the vm-tests -----
#  TODO: remove this section once cts-tf replaces cts.
#
CORE_VM_TEST_DESC := $(cts_dir)/$(cts_name)/repository/testcases/android.core.vm-tests

VMTESTS_INTERMEDIATES :=$(call intermediates-dir-for,EXECUTABLES,vm-tests,1,)
# core tests only needed to get hold of junit-framework-classes
CORE_INTERMEDIATES :=$(call intermediates-dir-for,JAVA_LIBRARIES,core,,COMMON)
JUNIT_INTERMEDIATES :=$(call intermediates-dir-for,JAVA_LIBRARIES,core-junit,,COMMON)

GEN_CLASSPATH := $(CORE_INTERMEDIATES)/classes.jar:$(JUNIT_INTERMEDIATES)/classes.jar:$(VMTESTS_INTERMEDIATES)/android.core.vm-tests.jar:$(HOSTTESTLIB_JAR):$(DDMLIB_JAR)

$(CORE_VM_TEST_DESC): PRIVATE_CLASSPATH:=$(GEN_CLASSPATH)
# Please see big comment above on why this line depends on javalib.jar instead of classes.jar
$(CORE_VM_TEST_DESC): vm-tests $(HOST_OUT_JAVA_LIBRARIES)/descGen.jar $(CORE_INTERMEDIATES)/javalib.jar $(JUNIT_INTERMEDIATES)/javalib.jar $(VMTESTS_INTERMEDIATES)/android.core.vm-tests.jar $(HOSTTESTLIB_JAR) $(DDMLIB_JAR) $(cts_dir)/all_cts_files_stamp | $(ACP)
	$(call generate-core-test-description,$(CORE_VM_TEST_DESC),\
		cts/tests/vm-tests/AndroidManifest.xml,\
		$(VMTESTS_INTERMEDIATES)/android.core.vm-tests.jar,"",\
		libcore/expectations,\
		cts/tools/vm-tests/Android.mk)
	$(ACP) -fv $(VMTESTS_INTERMEDIATES)/android.core.vm-tests.jar $(PRIVATE_DIR)/repository/testcases/android.core.vm-tests.jar

# ----- Generate the test descriptions for the vm-tests-tf -----
#
CORE_VM_TEST_TF_DESC := $(cts_dir)/$(cts_name)/repository/testcases/android.core.vm-tests-tf

VMTESTSTF_INTERMEDIATES :=$(call intermediates-dir-for,EXECUTABLES,vm-tests-tf,1,)
# core tests only needed to get hold of junit-framework-classes
CORE_INTERMEDIATES :=$(call intermediates-dir-for,JAVA_LIBRARIES,core,,COMMON)
JUNIT_INTERMEDIATES :=$(call intermediates-dir-for,JAVA_LIBRARIES,core-junit,,COMMON)

GEN_CLASSPATH := $(CORE_INTERMEDIATES)/classes.jar:$(JUNIT_INTERMEDIATES)/classes.jar:$(VMTESTSTF_INTERMEDIATES)/android.core.vm-tests-tf.jar:$(DDMLIB_JAR):$(TF_JAR)

$(CORE_VM_TEST_TF_DESC): PRIVATE_CLASSPATH:=$(GEN_CLASSPATH)
# Please see big comment above on why this line depends on javalib.jar instead of classes.jar
$(CORE_VM_TEST_TF_DESC): $(HOST_OUT_JAVA_LIBRARIES)/descGen.jar $(CORE_INTERMEDIATES)/javalib.jar $(JUNIT_INTERMEDIATES)/javalib.jar $(VMTESTSTF_INTERMEDIATES)/android.core.vm-tests-tf.jar $(DDMLIB_JAR) $(cts_dir)/all_cts_files_stamp | $(ACP)
	$(call generate-core-test-description,$(CORE_VM_TEST_TF_DESC),\
		cts/tests/vm-tests-tf/AndroidManifest.xml,\
		$(VMTESTSTF_INTERMEDIATES)/android.core.vm-tests-tf.jar,"",\
		libcore/expectations,\
		cts/tools/vm-tests-tf/Android.mk)
	$(ACP) -fv $(VMTESTSTF_INTERMEDIATES)/android.core.vm-tests-tf.jar $(PRIVATE_DIR)/repository/testcases/android.core.vm-tests-tf.jar


# Move app security host-side tests to the repository
APP_SECURITY_LIB := $(cts_dir)/$(cts_name)/repository/testcases/CtsAppSecurityTests.jar

$(APP_SECURITY_LIB): $(HOST_OUT_JAVA_LIBRARIES)/CtsAppSecurityTests.jar $(cts_dir)/all_cts_files_stamp $(ACP)
	$(ACP) -fv $(HOST_OUT_JAVA_LIBRARIES)/CtsAppSecurityTests.jar $(APP_SECURITY_LIB)


# Generate the default test plan for User.
# Usage: buildCts.py <testRoot> <ctsOutputDir> <tempDir> <androidRootDir> <docletPath>

$(DEFAULT_TEST_PLAN): $(cts_dir)/all_cts_files_stamp $(cts_dir)/all_cts_core_files_stamp $(cts_tools_src_dir)/utils/buildCts.py $(CORE_VM_TEST_TF_DESC) $(CORE_VM_TEST_DESC) $(APP_SECURITY_LIB) $(HOST_OUT_JAVA_LIBRARIES)/descGen.jar $(CTS_TEST_XMLS) | $(ACP)
	$(hide) $(ACP) -fp $(CTS_TEST_XMLS) $(PRIVATE_DIR)/repository/testcases
	$(hide) $(cts_tools_src_dir)/utils/buildCts.py cts/tests/tests/ $(PRIVATE_DIR) $(TMP_DIR) \
		$(TOP) $(HOST_OUT_JAVA_LIBRARIES)/descGen.jar

# Package CTS and clean up.
#
# TODO:
#   Pack cts.bat into the same zip file as well. See http://buganizer/issue?id=1656821 for more details
INTERNAL_CTS_TARGET := $(cts_dir)/$(cts_name).zip
$(INTERNAL_CTS_TARGET): PRIVATE_NAME := $(cts_name)
$(INTERNAL_CTS_TARGET): PRIVATE_CTS_DIR := $(cts_dir)
$(INTERNAL_CTS_TARGET): PRIVATE_DIR := $(cts_dir)/$(cts_name)
$(INTERNAL_CTS_TARGET): TMP_DIR := $(cts_dir)/temp
$(INTERNAL_CTS_TARGET): $(cts_dir)/all_cts_files_stamp $(DEFAULT_TEST_PLAN) $(CORE_VM_TEST_DESC)
	$(hide) echo "Package CTS: $@"
	$(hide) cd $(dir $@) && zip -rq $(notdir $@) $(PRIVATE_NAME)

.PHONY: cts
cts: $(INTERNAL_CTS_TARGET) adb
$(call dist-for-goals,cts,$(INTERNAL_CTS_TARGET))

define copy-testcase-apk

$(hide) $(ACP) -fp $(call intermediates-dir-for,APPS,$(1))/package.apk \
	$(PRIVATE_DIR)/repository/testcases/$(1).apk

endef

define copy-testcase

$(hide) $(ACP) -fp $(1) $(PRIVATE_DIR)/repository/testcases/$(notdir $1)

endef
