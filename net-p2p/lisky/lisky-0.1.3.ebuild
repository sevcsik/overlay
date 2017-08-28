EAPI=5

inherit eutils git-r3

DESCRIPTION="Commandline utility for Lisk"
SLOT=0
LICENSE="GPL-3"
KEYWORDS="~amd64"
EGIT_REPO_URI="https://github.com/LiskHQ/lisky.git"
EGIT_COMMIT="v$PV"
EGIT_CLONE_TYPE="shallow"

DEPEND=">=net-libs/nodejs-6.11.0"
RDEPEND=">=net-libs/nodejs-6.11.0"

S=$WORKDIR/$P
EGIT_CHECKOUT_DIR=$S

src_prepare() {
	epatch $FILESDIR/$P-dist-path.patch
	npm install --only=production --no-package-lock
	mv node_modules node_modules_runtime
	git checkout package-lock.json
	npm install --only=development --no-package-lock
}

src_compile() {
	npm run build
}

src_test() {
	npm test
}

src_install() {
	insinto /usr/lib/$PN
	doins -r $S/dist
	doins package.json
	doins defaultConfig.json
	insinto /usr/lib/$PN/node_modules
	doins -r $S/node_modules_runtime/*
	dobin $S/bin/lisky
}

