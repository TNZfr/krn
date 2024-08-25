
. $KRN_EXE/lib/ARCH/Module.sh

#-------------------------------------------------------------------------------
# Same as ARCH definition, but overloading with ...
#-------------------------------------------------------------------------------
_InstallPackage()
{
    [ ! -d $KRN_LVBuild ] && continue
    cd $KRN_LVBuild

    KernelVersion=$(make kernelversion)

    # Modules install (and signature)
    printh "Linux $KernelVersion modules installation ..."
    chmod 644 certs/signing_key.*
    $KRN_sudo make modules_install -j$(nproc)
    _Status=$?; [ $_Status -ne 0 ] && exit $_Status

    # Copie des fichiers dans /boot
    printh "Deploy vmlinuz-linux-$KernelVersion ..."
    $KRN_sudo cp $(make image_name) /boot/vmlinuz-linux-$KernelVersion
    _Status=$?; [ $_Status -ne 0 ] && exit $_Status
    
    printh "Build initramfs-linux-$KernelVersion.img ..."
    $KRN_sudo mkinitcpio \
	      --kernel   /boot/vmlinuz-linux-$KernelVersion \
	      --generate /boot/initramfs-linux-$KernelVersion.img
    
    _Status=$?; [ $_Status -ne 0 ] && exit $_Status

    which dkms > /dev/null 2>&1; DKMS_Available=$?
    if [ $DKMS_Available ]
    then
	printh "DKMS modules build for $KernelVersion ..."
	$KRN_sudo dkms autoinstall -k $KernelVersion
	_Status=$?; [ $_Status -ne 0 ] && exit $_Status
    fi

    echo ""
    cd $TempDir
    
    # Mise a jour de GRUB
    # -------------------
    printh "GRUB update ..."
    _UpdateGrub
    _Status=$?; [ $_Status -ne 0 ] && exit $_Status
}

#-------------------------------------------------------------------------------
# Remove
#-------------------------------------------------------------------------------
_RemovePackage ()
{
    printh "Cleaning /boot directory ..."
    $KRN_sudo rm -f \
	      /boot/vmlinuz-linux-$(basename $ModuleDirectory)* \
	      /boot/initramfs-linux-$(basename $ModuleDirectory)*.img
    rm_status=$?

    printh "GRUB update ..."
    _UpdateGrub
    _Status=$?; [ $_Status -ne 0 ] && exit $_Status

    return $rm_status
}
