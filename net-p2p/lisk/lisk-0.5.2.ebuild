EAPI=5

DESCRIPTION="Full node for the Lisk Blockhain Application Platform"
SLOT="0"
LICENSE="MIT"
KEYWORDS="~amd64"

RDEPEND=">=net-libs/nodejs-0.12.14 >=dev-db/postgresql-9.6.1"
SRC_URI="https://downloads.lisk.io/lisk/main/${PV}/${PV}.tar.gz"
S="${WORKDIR}/${PV}"

src_compile() {
#	npm install --production || die "Failed to install npm dependencies"
	return
}

src_install() {
	insinto "/usr/lib/lisk"
	doins -r "${S}"/*

	dodir "/etc/lisk"
	dosym /usr/lib/lisk/config.json /etc/lisk
	dosym /usr/lib/lisk/genesisBlock.json /etc/lisk
}

