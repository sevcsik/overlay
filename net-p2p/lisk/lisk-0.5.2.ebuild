EAPI=5

inherit user

NETRWORK="main"

DESCRIPTION="Full node for the Lisk Blockhain Application Platform"
SLOT="0"
LICENSE="MIT"
KEYWORDS="~amd64"

DEPEND="net-misc/wget app-arch/gzip >=net-libs/nodejs-0.12.14 >=dev-db/postgresql-9.6.1"
RDEPEND=">=net-libs/nodejs-0.12.14 >=dev-db/postgresql-9.6.1"
SRC_URI="https://downloads.lisk.io/lisk/${NETWORK}/${PV}/${PV}.tar.gz"
S="${WORKDIR}/${PV}"

USERNAME="lisk"
DBNAME="lisk_${NETWORK}"

src_compile() {
	npm install --production || die "Failed to install npm dependencies"
}

src_install() {
	insinto "/usr/lib/lisk"
	doins -r "${S}"/*

	dodir "/etc/lisk"
	dosym ${ROOT}usr/lib/lisk/config.json ${ROOT}etc/lisk
	dosym ${ROOT}usr/lib/lisk/genesisBlock.json ${ROOT}etc/lisk
	dosym ${ROOT}usr/lib/lisk/logs ${ROOT}var/log/lisk

	elog "config.json and genesisBlock.json are symlinked to /etc/lisk."
	elog "To enable SSL or forging, edit config.json according to the docs at:"
	elog "https://lisk.io/documentation?i=lisk-docs/SourceInstall"
	elog ""
	elog "To initialise the database with the latest blockchain snapshot,"
	elog "run emerge --config =net-p2p/${P}"
}

pkg_postinst() {
	enewuser $USERNAME
	chown $USERNAME ${ROOT}usr/lib/lisk/config.json # TODO: why?
	chown $USERNAME ${ROOT}usr/lib/lisk/logs
	chown $USERNAME ${ROOT}usr/lib/lisk/pids
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
			wget https://downloads.lisk.io/lisk/${NETWORK}/blockchain.db.gz
			gunzip -fcq blockchain.db.gz | sudo -u lisk psql -qd $DBNAME
		else
			elog "The database '$DBNAME' already exists."
		fi
	else
		elog "PostgreSQL role '$USERNAME' already exists, database setup skipped."
	fi
}

