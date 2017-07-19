EAPI=6
inherit eutils rpm

DESCRIPTION="Card reader application for Hungarian electonic ID cards"
LICENSE=eSzemelyi_Kliens_vegfelhasznaloi_nyilatkozat_v5.pdf
RESTRICT="mirror bindist strip"

SRC_URI=https://eszemelyi.hu/app/eSzemelyi_Kliens_x64_1_2_8.rpm
SLOT=0
KEYWORDS="~amd64"
HOMEPAGE=https://eszemelyi.hu/kartyaolvaso/kartyaolvaso_alkalmazas

W=$WORKDIR/$P

RDEPEND=">=sys-apps/pcsc-lite-1.8 \
         >=dev-qt/qtgui-5.5.1 \
         >=dev-qt/qtwidgets-5.5.1 \
         >=dev-qt/qtnetwork-5.5.1 \
         >=dev-qt/qtcore-5.5.1 \
         >=dev-qt/qtdbus-5.5.1"

src_unpack() {
	rpm_unpack $A
	mv usr $P
	rm -r $W/lib/KEKKH/platforms $W/lib/KEKKH/Qt5
}

src_install () {
	insinto /usr/lib
	doins -r $W/lib/KEKKH
	insinto /usr/share/applications
	doins $W/share/applications/eszig-cmu.desktop
	fperms a+x /usr/lib/KEKKH/eszig-eid /usr/lib/KEKKH/eszig-cmu
	dosym /usr/lib/KEKKH/eszig-eid /usr/bin/eszig-eid
	dosym /usr/lib/KEKKH/eszig-cmu /usr/bin/eszig-cmu
}
