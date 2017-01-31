EAPI=5
NETWORK=main

inherit user

DESCRIPTION="Full node for the Lisk Blockhain Application Platform"
SLOT="0"
LICENSE="MIT"
KEYWORDS="~amd64"

DEPEND="net-misc/wget app-arch/gzip >=net-libs/nodejs-0.12.14 >=dev-db/postgresql-9.6.1"
RDEPEND=">=net-libs/nodejs-0.12.14 >=dev-db/postgresql-9.6.1"
SRC_URI="https://downloads.lisk.io/lisk/$NETWORK/$PV/$PV.tar.gz"
S="${WORKDIR}/${PV}"

USERNAME="$PN"
DBNAME="$PN"

update_config() {
	sed -ie "s/\"database\": \"lisk_main\"/\"database\": \"$PN\"/" config.json
	sed -ie "s/\"password\": \"password\"/\"password\": \"\"/" config.json
	sed -ie "s/\"logFileName\": \"logs\/lisk.log\"/\"logFileName\": \"\/var\/log\/lisk\/lisk.log\"/" config.json
}

src_compile() {
	npm install --production || die "Failed to install npm dependencies"
}

src_install() {
	insinto /usr/lib/lisk
	doins -r $S/*

	update_config

	insinto /etc/lisk
	doins $S/config.json
	doins $S/genesisBlock.json

	dosym /etc/lisk/config.json /usr/lib/lisk/
	dosym /etc/lisk/genesisBlock.json /usr/lib/lisk/

	dodir /var/lisk
	dosym /var/lisk /usr/lib/lisk/dapps

	dodir /var/log/lisk

	elog "config.json and genesisBlock.json are symlinked fro /etc/lisk."
	elog "To enable SSL or forging, edit config.json according to the docs at:"
	elog "https://lisk.io/documentation?i=lisk-docs/SourceInstall"
	elog ""
	elog "To initialise the database with the latest blockchain snapshot,"
	elog "run emerge --config =net-p2p/$P"
}

pkg_postinst() {
	enewuser $USERNAME
	chown $USERNAME $ROOT/etc/lisk/config.json # TODO: why?
	chown $USERNAME $ROOT/var/log/lisk
	chown $USERNAME $ROOT/usr/lib/lisk/pids
}

pkg_config() {
	# Query databases
	DBS=`sudo -u postgres psql -l`

	# Check for connection error
	if [ "$?" -gt 0 ]
	then
		die "Could not connect to PostgreSQL to set up database."
	fi

	# Check if user 'lisk' exists
	if [ `sudo -u postgres psql -tAc "select count(*) from pg_roles where rolname='$USERNAME'"` -eq 0 ]
	then
		# Create lisk user in postgresql
		sudo -u postgres createuser lisk
		elog "PostgreSQL role '$USERNAME' has been created in WITHOUT password."

		# check if database "lisk" already exists
		echo $DBS | grep lisk

		if [ "$?" -gt 0 ] # database doesn't exist
		then
			sudo -u postgres createdb -O lisk $DBNAME
			elog "The database '$DBNAME' has been created in PostgreSQL."

			elog "Importing blockchain snapshot. This may take some time."
			wget https://downloads.lisk.io/lisk/$NETWORK/blockchain.db.gz
			gunzip -fcq blockchain.db.gz | sudo -u lisk psql -qd $DBNAME
		else
			elog "The database '$DBNAME' already exists."
		fi
	else
		elog "PostgreSQL role '$USERNAME' already exists, database setup skipped."
	fi
}

