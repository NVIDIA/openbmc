FILESEXTRAPATHS:prepend := "${THISDIR}:"

FILESEXTRAPATHS:prepend := "${THISDIR}/ltssm_dump/:"

SRC_URI:append = " \
                   file://check_logmount.sh \
                   file://aries-link-dump.tar.gz \
                   file://hmc_dump_link_logs.bash \
                   file://retimerLtssmDump.sh "

INSANE_SKIP:${PN} += "already-stripped"

FILES:${PN}-manager +=  "${bindir}/hmc_dump_link_logs.bash"
FILES:${PN}-manager +=  "${bindir}/aries-link-dump.tar.gz"
FILES:${PN}-manager +=  "${bindir}/aries-link-dump-obmc-ast2600"
FILES:${PN}-manager +=  "${bindir}/retimerLtssmDump.sh"

install_nvidia_hgx_plugins() {
    install ${S}/tools/dreport.d/nvidia.d/hgx.d/* ${D}${dreport_plugin_dir}/

    # No retimer on GB200NVL
    rm ${D}${dreport_plugin_dir}/hgxretimerbootstate
    rm ${D}${dreport_plugin_dir}/hgxpcieaer
}

#Link in the plugins so dreport run them at the appropriate time
python link_nvidia_hgx_plugins() {
    source = d.getVar('S', True)
    source_path = os.path.join(source, "tools", "dreport.d", "nvidia.d", "hgx.d")
    op_plugins = os.listdir(source_path)
    for op_plugin in op_plugins:
        op_plugin_name = os.path.join(source_path, op_plugin)
        if op_plugin_name != "hgxretimerbootstate" and op_plugin_name != "hgxpcieaer" :
            install_dreport_user_script(op_plugin_name, d)
}

NVIDIA_HGX_INSTALL_POSTFUNCS = "install_nvidia_hgx_plugins link_nvidia_hgx_plugins"

do_install[postfuncs] += "${NVIDIA_HGX_INSTALL_POSTFUNCS}"
