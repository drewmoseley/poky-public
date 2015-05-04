SUMMARY = "Lightweight headless squeezebox emulator"
HOMEPAGE = "https://code.google.com/p/squeezelite/"
SECTION = "console/utils"
LICENSE = "GPLv3"
SRC_URI = "git://code.google.com/p/${PN};protocol=https"
SRCREV = "${AUTOREV}"
S = "${WORKDIR}/git"
DEPENDS = "alsa-lib flac libvorbis libmad mpg123 faad2"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=aa549181ec5f37f91860b8f7a1e00c6b"
LDFLAGS += "-lasound -lpthread -lm -lrt -ldl"

FILES_${PN} = "${bindir}/squeezelite"

do_install() {
        install -d ${D}${bindir}
        install -m 0755 ${B}/${PN} ${D}${bindir}/
}
