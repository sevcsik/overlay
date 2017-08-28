EAPI=5
inherit git-r3 eutils
DESCRIPTION="Lightweight GUI client for the Lisk network"
SLOT=0
LICENSE="GPL-3"
KEYWORDS="~amd64"
EGIT_REPO_URI="https://github.com/LiskHQ/lisk-nano.git"
EGIT_COMMIT="v$PV"
EGIT_CLONE_TYPE="shallow"

DEPEND="media-libs/libicns \
        media-gfx/graphicsmagick[png] \
        >=net-libs/nodejs-6.11.0 \
       "
RDEPEND=">=net-libs/nodejs-6.11.0"

S=$WORKDIR/$P
EGIT_CHECKOUT_DIR=$S

src_prepare() {
	epatch $FILESDIR/$P-electron-target.patch
	npm install
}

src_compile() {
	npm run build
	npm run dist:linux
}

src_test() {
	npm test
}

src_install () {
	insinto /usr/lib/$PN
	doins -r $S/dist/linux-unpacked/*
	dosym /usr/lib/$PN/lisk-nano /usr/bin/$PN
	fperms a+x /usr/lib/$PN/lisk-nano

	insinto /usr/share/icons/hicolor/128x128/apps
	newins $FILESDIR/icon_128.png lisk-nano.png
	insinto /usr/share/icons/hicolor/48x48/apps
	newins $FILESDIR/icon_48.png lisk-nano.png
	insinto /usr/share/icons/hicolor/32x32/apps
	newins $FILESDIR/icon_32.png lisk-nano.png
	insinto /usr/share/icons/hicolor/16x16/apps
	newins $FILESDIR/icon_16.png lisk-nano.png
	insinto /usr/share/applications
	doins $FILESDIR/$PN.desktop
}
