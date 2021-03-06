KBRANCH ?= "standard/base"

require recipes-kernel/linux/linux-yocto.inc

# board specific branches
KBRANCH_qemuarm  ?= "standard/arm-versatile-926ejs"
KBRANCH_qemuarm64 ?= "standard/qemuarm64"
KBRANCH_qemumips ?= "standard/mti-malta32"
KBRANCH_qemuppc  ?= "standard/qemuppc"
KBRANCH_qemux86  ?= "standard/common-pc"
KBRANCH_qemux86-64 ?= "standard/common-pc-64/base"
KBRANCH_qemumips64 ?= "standard/mti-malta64"

SRCREV_machine_qemuarm ?= "963b4df663dba2584ac864e0c016825de0046558"
SRCREV_machine_qemuarm64 ?= "e152349de59b43b2a75f2c332b44171df461d5a0"
SRCREV_machine_qemumips ?= "cedbbc7b5e72df2e820bb9e7885f12132c5e2fff"
SRCREV_machine_qemuppc ?= "23a83386e10986a63e6cef712a045445499d002b"
SRCREV_machine_qemux86 ?= "e152349de59b43b2a75f2c332b44171df461d5a0"
SRCREV_machine_qemux86-64 ?= "e152349de59b43b2a75f2c332b44171df461d5a0"
SRCREV_machine_qemumips64 ?= "3eb70cea3532e22ab1b6da9864446621229e6616"
SRCREV_machine ?= "e152349de59b43b2a75f2c332b44171df461d5a0"
SRCREV_meta ?= "a70b2eb273ef6349d344920474a494697474b98e"

SRC_URI = "git://git.yoctoproject.org/linux-yocto-3.19.git;bareclone=1;branch=${KBRANCH},${KMETA};name=machine,meta"

LINUX_VERSION ?= "3.19.5"

PV = "${LINUX_VERSION}+git${SRCPV}"

KMETA = "meta"
KCONF_BSP_AUDIT_LEVEL = "2"

COMPATIBLE_MACHINE = "qemuarm|qemuarm64|qemux86|qemuppc|qemumips|qemumips64|qemux86-64"

# Functionality flags
KERNEL_EXTRA_FEATURES ?= "features/netfilter/netfilter.scc"
KERNEL_FEATURES_append = " ${KERNEL_EXTRA_FEATURES}"
KERNEL_FEATURES_append_qemux86=" cfg/sound.scc cfg/paravirt_kvm.scc"
KERNEL_FEATURES_append_qemux86-64=" cfg/sound.scc cfg/paravirt_kvm.scc"
KERNEL_FEATURES_append = " ${@bb.utils.contains("TUNE_FEATURES", "mx32", " cfg/x32.scc", "" ,d)}"
