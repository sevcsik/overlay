# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit user systemd eutils

DESCRIPTION="go-ipfs is the main implementation of IPFS."
HOMEPAGE="https://ipfs.io/"
SRC_URI="https://github.com/ipfs/go-ipfs/archive/v0.4.8.tar.gz -> ${P}.tar.gz"
# Also available arches:
#	arm? ( https://dist.ipfs.io/go-ipfs/v${PV}/go-ipfs_v${PV}_linux-arm.tar.gz )

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~x86 ~amd64"
IUSE="+fuse systemd"
LICENSE="MIT"

DEPEND=">=dev-lang/go-1.7.0 net-misc/curl app-misc/ca-certificates[insecure_certs]"
RDEPEND="fuse? ( sys-fs/fuse )"

_DEST=${WORKDIR}/src/github.com/ipfs/

pkg_setup() {
	enewuser ${PN} -1 -1 /var/lib/${PN}
	dodir /var/lib/${PN}

	elog "${PN} user has been created with the home directory /var/lib/${PN}."
}

src_prepare() {
	eapply_user
}

src_compile() {
	mkdir -p ${_DEST}
	ln -s ${WORKDIR}/go-ipfs-${PV} ${_DEST}/go-ipfs
	cd ${_DEST}/go-ipfs
	GOPATH=${WORKDIR} emake build
	eend ${?}
}

src_install() {
	dobin cmd/ipfs/ipfs
	if use systemd
	then
		systemd_dounit $FILESDIR/go-ipfs.service
		elog "Systemd unit go-ipfs.service has been installed"
	fi
	dodir /var/lib/${PN}
	insinto /etc/sudoers.d
	doins $FILESDIR/go-ipfs-sudoers
}

pkg_postinst() {
	chown ${PN}:${PN} /var/lib/${PN}
	elog "Before starting IPFS, you need to initialise the database with:"
	elog " sudo -u ${PN} ipfs init"
	elog "To use the ipfs client on the same database the server uses, the ipfs command has to be"
	elog "invoked with the go-ipfs user. Every user in the go-ipfs group has been granted to use"
	elog "\"sudo -u go-ipfs\" for the ipfs executable".
}
