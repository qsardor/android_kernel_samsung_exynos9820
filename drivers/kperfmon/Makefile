#
# Makefile for the Linux kernel device drivers.
# Cleaned up for standalone kernel build.
#

FLAG=0

ifeq ($(CONFIG_KPERFMON), y)
ifneq ($(wildcard $(srctree)/../../frameworks/base/proto/src/olog.proto),)
    $(shell cp -f $(srctree)/../../frameworks/base/proto/src/olog.proto  $(srctree)/drivers/kperfmon/)
    $(shell cp -f $(srctree)/../../vendor/samsung/system/libperflog/aprotoc  $(srctree)/drivers/kperfmon/)
    $(shell $(srctree)/drivers/kperfmon/aprotoc --perflog_out=./  $(srctree)/drivers/kperfmon/olog.proto)
    $(shell cp -f $(srctree)/drivers/kperfmon/olog.pb.h  $(srctree)/include/linux/)
    $(shell cp -f $(srctree)/../../system/core/liblog/include/log/perflog.h  $(srctree)/include/linux/)
    FLAG=1
endif
endif

ifeq ($(FLAG), 1)
	obj-y += kperfmon.o
else
	obj-y += ologk.o
endif
