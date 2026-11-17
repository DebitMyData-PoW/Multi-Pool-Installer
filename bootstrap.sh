#!/usr/bin/env bash
#########################################################
# The DebitMyData pool installer, first step. Run it as root on a fresh Ubuntu 24.04 server:
#
#   curl -fsSL https://raw.githubusercontent.com/DebitMyData-PoW/Multi-Pool-Installer/master/bootstrap.sh | bash
#
# It downloads the installer (DebitMyData-PoW/multipool_setup) to ~/multipool/install and
# starts it. SETUP_REF picks another branch or tag of it than master.
#
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use, and by DebitMyData for its pool.
#########################################################

SETUP_REPO=https://github.com/DebitMyData-PoW/multipool_setup
SETUP_REF="${SETUP_REF:-master}"

if [ ! -d "$HOME/multipool/install" ]; then
	if ! command -v git >/dev/null; then
		echo "Installing git..."
		apt-get -q -q update
		DEBIAN_FRONTEND=noninteractive apt-get -q -q install -y git </dev/null
	fi

	echo "Downloading the DebitMyData pool installer ($SETUP_REF)..."
	if ! git clone -q -b "$SETUP_REF" "$SETUP_REPO" "$HOME/multipool/install" </dev/null; then
		echo "The download failed: is $SETUP_REPO reachable from this server?"
		exit 1
	fi
fi

cd "$HOME/multipool/install" || exit 1

# Bring it up to date (a branch moves on; a tag stays where it is).
sudo chown -R "$(id -un)" "$HOME/multipool/install/.git/"
if ! { git fetch -q --tags origin &&
	git checkout -q "$SETUP_REF" &&
	{ ! git show-ref -q --verify "refs/remotes/origin/$SETUP_REF" ||
		git merge -q --ff-only "origin/$SETUP_REF"; }; }; then
	echo "The update failed. Did you change something in $(pwd)?"
	exit 1
fi

bash "$HOME/multipool/install/start.sh"
