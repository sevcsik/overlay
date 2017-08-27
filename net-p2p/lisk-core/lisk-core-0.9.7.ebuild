EAPI=5
NETWORK=main

inherit user eutils systemd git-r3

DESCRIPTION="Full node for the Lisk network (${NETWORK}net)"
SLOT="0"
LICENSE="GPL-3"
KEYWORDS="~amd64"
IUSE="systemd lisk-node"
EGIT_REPO_URI="https://github.com/LiskHQ/lisk.git"
EGIT_SUBMODULES=( '*' )
EGIT_COMMIT="$PV"
EGIT_CLONE_TYPE="shallow"

DEPEND=">=net-libs/nodejs-6.0.0"

RDEPEND=">=net-libs/nodejs-6.0.0 \
         >=dev-db/postgresql-9.6.2 \
         lisk-node? ( =net-libs/lisk-node-6.11.1 )
        "

USERNAME="$PN"
DBNAME="$PN"

S=$WORKDIR/$P
EGIT_CHECKOUT_DIR=$S

src_prepare() {
	epatch $FILESDIR/$P-config.patch
	epatch $FILESDIR/$P-config-path-fix.patch
	PATH=$S/node_modules/.bin:$PATH
	npm install bower
	npm install grunt-cli
	npm install --production
	cd public
	npm install
	bower install
	rm font/roboto
	mv bower_components/materialize/font/roboto font/
	rm font/material-design-icons
	mv bower_components/materialize/font/material-design-icons font/
}

src_compile() {
	PATH=$S/node_modules/.bin:$PATH
	cd public
	grunt release
	rm -r node_modules
	rm -r bower_components
}

src_install() {
	elog "To initialise the database with the latest blockchain snapshot"
	elog "run emerge --config =net-p2p/$P"

	insinto /etc/$PN
	doins $S/config.json
	doins $S/genesisBlock.json
	rm $S/genesisBlock.json
	dosym /etc/$PN/genesisBlock.json /usr/lib/$PN/genesisBlock.json

	insinto /usr/lib/$PN
	doins -r $S/*

	if ! use lisk-node
	then
		elog "Enable the lisk-node use flag to run DApps."
	else
		dodir /usr/lib/$PN/nodejs
		dosym /usr/lib/$PN/nodejs/node /usr/lib/lisk-node/bin/node
	fi

	dodir /var/$PN
	dosym /var/$PN /usr/lib/$PN/dapps

	dodir /var/$PN
	dosym /var/$PN /usr/lib/$PN/dapps

	if use systemd
	then
		systemd_dounit $FILESDIR/$PN.service
		elog "Systemd unit $PN.service has been installed."
		elog ""
	fi
}

pkg_postinst() {
	enewuser $USERNAME
	chown $USERNAME $ROOT/etc/$PN/config.json
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
