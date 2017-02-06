EAPI=5
NETWORK=test

inherit user eutils systemd

DESCRIPTION="Full node for the Lisk Blockhain Application Platform"
SLOT="0"
LICENSE="MIT"
KEYWORDS="~amd64"
IUSE="systemd"
DEPEND="net-misc/wget app-arch/gzip >=net-libs/nodejs-0.12.14 >=dev-db/postgresql-9.6.1"
RDEPEND=">=net-libs/nodejs-0.12.14 >=dev-db/postgresql-9.6.1"
SRC_URI="https://downloads.lisk.io/lisk/$NETWORK/$PV/$PV.tar.gz -> $P.tar.gz"
S="${WORKDIR}/${PV}"

USERNAME="$PN"
DBNAME="$PN"

src_prepare() {
	epatch $FILESDIR/${P}-config.patch
	if use systemd
	then
		epatch $FILESDIR/${P}-systemd.patch
	fi
}

src_compile() {
	npm install --production || die "Failed to install npm dependencies"
}

src_install() {
	insinto /usr/lib/$PN
	doins -r $S/*

	insinto /etc/$PN
	doins $S/config.json
	doins $S/genesisBlock.json

	dosym /etc/$PN/config.json /usr/lib/$PN/
	dosym /etc/$PN/genesisBlock.json /usr/lib/$PN/

	dodir /var/$PN
	dosym /var/$PN /usr/lib/$PN/dapps
	sed -ie "s/\"database\": \"lisk_main\"/\"database\": \"$PN\"/" config.json

	dodir /var/log/$PN

	if use systemd
	then
		systemd_dounit $PN.service
		elog "Systemd unit $PN.service has been installed."
		elog ""
	fi

	elog "config.json and genesisBlock.json are symlinked fro /etc/$PN."
	elog "To enable SSL or forging, edit config.json according to the docs at:"
	elog "https://lisk.io/documentation?i=lisk-docs/SourceInstall"
	elog ""
	elog "To initialise the database with the latest blockchain snapshot,"
	elog "run emerge --config =net-p2p/$P"
}

pkg_postinst() {
	enewuser $USERNAME
	chown $USERNAME $ROOT/etc/$PN/config.json # TODO: why?
	chown $USERNAME $ROOT/var/log/$PN
	chown $USERNAME $ROOT/usr/lib/$PN/pids
}

pkg_config() {
	# Query databases
	DBS=`sudo -u postgres psql -l`

	# Check for connection error
	if [ "$?" -gt 0 ]
	then
		die "Could not connect to PostgreSQL to set up database."
	fi

	# Check if user $USERNAME exists
	if [ `sudo -u postgres psql -tAc "select count(*) from pg_roles where rolname='$USERNAME'"` -eq 0 ]
	then
		# Create $USERNAME user in postgresql
		sudo -u postgres createuser $USERNAME
		elog "PostgreSQL role '$USERNAME' has been created WITHOUT password."

		# check if database "$PN" already exists
		echo $DBS | grep $DBNAME

		if [ "$?" -gt 0 ] # database doesn't exist
		then
			sudo -u postgres createdb -O $USERNAME $DBNAME
			elog "The database '$DBNAME' has been created in PostgreSQL."

			elog "Importing blockchain snapshot. This may take some time."
			wget https://downloads.lisk.io/lisk/$NETWORK/blockchain.db.gz
			gunzip -fcq blockchain.db.gz | sudo -u $USERNAME psql -qd $DBNAME
		else
			elog "The database '$DBNAME' already exists."
		fi
	else
		elog "PostgreSQL role '$USERNAME' already exists, database setup skipped."
	fi
}

