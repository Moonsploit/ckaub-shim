#!/bin/bash
# written mostly by HarryJarry1
# get_stateful take from https://github.com/applefritter-inc/BadApple-icarus
fail(){
    printf "$1\n"
    printf "exiting...\n"
    exit 1
}

main(){
    echo
    get_internal
    
    # Create necessary directories
    mkdir -p /localroot /stateful
    
    # Mount and prepare chroot environment
    mount "${intdis}${intdis_prefix}3" /localroot -o ro || fail "Failed to mount root partition"
    mount --bind /dev /localroot/dev || fail "Failed to bind mount /dev"
    
    # Modify partition attributes
    chroot /localroot cgpt add "$intdis" -i 2 -P 10 -T 5 -S 1 || fail "Failed to modify partition attributes"
    
    # Use sfdisk for non-interactive partitioning (cleaner than fdisk)
    echo -e "d\n4\nd\n5\nw" | chroot /localroot fdisk "$intdis" >/dev/null 2>&1
    
    
    # Cleanup
    umount /localroot/dev
    umount /localroot
    rmdir /localroot
    
    crossystem disable_dev_request=1
    
    # Try to mount stateful partition
    if ! mount "${intdis}${intdis_prefix}1" /stateful; then
        mountlvm
    fi
    
    # Clear stateful partition
    rm -rf /stateful/*
    umount /stateful
    
    echo "Done! Run reboot -f to reboot."
}

mountlvm(){
    # Check if LVM tools are available
    if command -v vgchange >/dev/null 2>&1 && command -v vgscan >/dev/null 2>&1; then
        vgchange -ay # activate all volume groups
        volgroup=$(vgscan | grep "Found volume group" | awk '{print $4}' | tr -d '"')
        echo "found volume group: $volgroup"
        mount "/dev/$volgroup/unencrypted" /stateful || fail "couldn't mount p1 or lvm group. Please recover"
    else
        fail "LVM tools not available. Cannot mount LVM volumes."
    fi
}

get_internal() {
    # Get root device from kernel cmdline
    local root_dev=$(rootdev -s 2>/dev/null)
    
    if [ -z "$root_dev" ]; then
        # Fallback: try to find root device
        local ROOTDEV_LIST=$(cgpt find -t rootfs 2>/dev/null)
        if [ -z "$ROOTDEV_LIST" ]; then
            fail "could not find root devices."
        fi
        
        # Get the first root device
        intdis=$(echo "$ROOTDEV_LIST" | head -n1 | sed 's/p[0-9]*$//' | sed 's/n[0-9]*$//')
    else
        # Extract base device from rootdev
        intdis=$(echo "$root_dev" | sed 's/p[0-9]*$//' | sed 's/n[0-9]*$//')
    fi
    
    # Determine device prefix
    if echo "$intdis" | grep -q "mmcblk"; then
        intdis_prefix="p"
    elif echo "$intdis" | grep -q "nvme"; then
        intdis_prefix="p"  # nvme usually uses p prefix
    else
        intdis_prefix=""
    fi
    
    echo "Detected internal disk: $intdis"
    echo "Partition prefix: $intdis_prefix"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

read -p "are you sure you want to run daub? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    main
fi
