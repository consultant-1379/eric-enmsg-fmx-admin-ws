#!/bin/bash
#
##################################################################################################
# global config, common logging & functions, and consul config (requires ERICfmxtools_CXP9031793)
##################################################################################################
FMX_COMMOM_CFG=/etc/opt/ericsson/fmx/tools
FMX_COMMOM_LIB=/opt/ericsson/fmx/tools/lib
. ${FMX_COMMOM_CFG}/fmxstack.cfg
. ${FMX_COMMOM_LIB}/functions
. ${FMX_COMMOM_LIB}/monitor
. ${FMX_COMMOM_LIB}/lsb-functions
. ${FMX_COMMOM_LIB}/ocf-functions

syslog_tag=fmx-preinstall
syslog_fac=user
logger_warn() { msg="$*"; echo -e "[WARN] $msg"; logger -t "${syslog_tag}" -p "${syslog_fac}.warn"  "$msg" ;}
logger_info() { msg="$*"; echo -e "[INFO] $msg"; logger -t "${syslog_tag}" -p "${syslog_fac}.info"  "$msg" ;}
logger_err()  { msg="$*"; echo -e "[ERR ] $msg"; logger -t "${syslog_tag}" -p "${syslog_fac}.err"   "$msg" ;}

ensure_dirs() {
	# Error exit and log if not existing $DATA_SHARE_DIR !!!
	DATA_SHARE_DIR=/ericsson/tor/data
	if [[ ! -d $DATA_SHARE_DIR ]] ; then
		logger_err "Directory $DATA_SHARE_DIR doesn't exist !!"
		exit -1
	fi

	# link from local to shared
	VAR_FMX='/var/opt/ericsson/fmx'
	if [[ ! -L $VAR_FMX ]]; then
		logger_info "Creating softlink: $VAR_FMX to $DATA_SHARE_DIR/fmx/..."
		ln -s $DATA_SHARE_DIR/fmx $VAR_FMX
                logger_info "Successfully created softlink: $VAR_FMX to $DATA_SHARE_DIR/fmx/..."
	fi

        # share_lib_fmx_export
        sync_lib /var/lib/fmx/modules/ $DATA_SHARE_DIR/fmx/export

}
# populate local default config files to shared location
populate_cfg_file() {
	local_cfg_file=$1
	shared_cfg_file=$2

	NFS_SERVER_TIMEOUT=1 # seconds

	if [[ ! -s $local_cfg_file ]]; then
		logger_warn "Cannot read local cfg file to populate: '$local_cfg_file'"
		return 1
	else
		timeout $NFS_SERVER_TIMEOUT ls "$shared_cfg_file" > /dev/null 2>&1
		lsrc=$?
		if [ "$lsrc" -eq 0 ]; then
			logger_info "Skipping populate ruletrace cfg file. Shared file already exists: $shared_cfg_file"
			return 3
		elif [ "$lsrc" -eq 2 ]; then
			logger_info "Populating local cfg file: '$local_cfg_file' to shared location: '$shared_cfg_file' ..."
			cp -a $local_cfg_file $shared_cfg_file
			return 0
		else
			logger_warn "Timeout when trying to check if shared cfg file exists: '$shared_cfg_file'"
			return 2
		fi
	fi
}

populate_cfg() {
	populate_cfg_file /etc/opt/ericsson/fmx/adapters/enmcli/fmxenmcli.properties /ericsson/tor/data/fmx/etc/enm_adapter/fmxenmcli.properties
        populate_cfg_file /etc/opt/ericsson/fmx/engine/rule_trace.properties /ericsson/tor/data/fmx/etc/engine/rule_trace.properties
}

ensure_dirs
populate_cfg