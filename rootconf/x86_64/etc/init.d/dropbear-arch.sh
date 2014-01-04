# dropbear config for PowerPC platforms

# The RSA and DSS keys are stored in the ONIE-CONFIG partition.  If
# the keys are missing generate the keys and store the results for
# future boots.
get_keys_arch() {
    if [ -r "$onie_config_mnt/$RSA_KEY" ] ; then
        cp "$onie_config_mnt/$RSA_KEY" $RSA_KEY
    else
        # genereate rsa key
        dropbearkey -t rsa -s 1024 -f $RSA_KEY > /dev/null 2>&1
        mkdir -p "$(dirname $onie_config_mnt/$RSA_KEY)"
        cp $RSA_KEY "$onie_config_mnt/$RSA_KEY"
    fi

    if [ -r "$onie_config_mnt/$DSS_KEY" ] ; then
        cp "$onie_config_mnt/$DSS_KEY" $DSS_KEY
    else
        # genereate dss key
        dropbearkey -t dss -s 1024 -f $DSS_KEY > /dev/null 2>&1
        mkdir -p "$(dirname $onie_config_mnt/$DSS_KEY)"
        cp $DSS_KEY "$onie_config_mnt/$DSS_KEY"
    fi
}

