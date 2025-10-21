#!/bin/bash
# daub + powerwash
# daub script by HarryTarryJarry

while true; do
    clear
    echo ""
    echo "    ██████╗  █████╗ ██╗   ██╗██████╗ "
    echo "    ██╔══██╗██╔══██╗██║   ██║██╔══██╗"
    echo "    ██║  ██║███████║██║   ██║██████╔╝"
    echo "    ██║  ██║██╔══██║██║   ██║██╔══██╗"
    echo "    ██████╔╝██║  ██║╚██████╔╝██████╔╝"
    echo "    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝"
    echo "  depthcharge automatic update blocking"
    echo "    daub was found by zeglol (Hannah)"
    echo "        script by HarryTarryJarry"
    echo ""

    echo "1) Block updates"
    echo "2) Powerwash"
    echo "3) Shell"
    echo "4) Reboot"
    read -p "Choose option: " choice

    case $choice in
        1)
            echo "Starting Daub..."
            
            # get_internal take from https://github.com/applefritter-inc/BadApple-icarus
            get_internal() {
                # get_largest_cros_blockdev does not work in BadApple.
                local ROOTDEV_LIST=$(cgpt find -t rootfs) # thanks stella
                if [ -z "$ROOTDEV_LIST" ]; then
                    echo "Could not find root devices."
                    read -p "Press Enter to return to menu..."
                    return 1
                fi
                local device_type=$(echo "$ROOTDEV_LIST" | grep -oE 'mmc|nvme|sda' | head -n 1)
                case $device_type in
                "mmc")
                    intdis=/dev/mmcblk0
                    intdis_prefix="p"
                    ;;
                "nvme")
                    intdis=/dev/nvme0
                    intdis_prefix="n"
                    ;;
                "sda")
                    intdis=/dev/sda
                    intdis_prefix=""
                    ;;
                *)
                    echo "an unknown error occured. this should not have happened."
                    read -p "Press Enter to return to menu..."
                    return 1
                    ;;
                esac
            }
            
            get_internal || continue
            
            echo "Detected internal disk: $intdis"
            
            # Create necessary directories
            mkdir -p /localroot /stateful
            
            # Mount and prepare chroot environment
            mount "${intdis}${intdis_prefix}3" /localroot -o ro 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "Failed to mount root partition"
                read -p "Press Enter to return to menu..."
                continue
            fi
            
            mount --bind /dev /localroot/dev 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "Failed to bind mount /dev"
                umount /localroot
                read -p "Press Enter to return to menu..."
                continue
            fi
            
            # Modify partition attributes
            chroot /localroot cgpt add "$intdis" -i 2 -P 10 -T 5 -S 1 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "Failed to modify partition attributes"
                umount /localroot/dev
                umount /localroot
                read -p "Press Enter to return to menu..."
                continue
            fi
            
            # Use fdisk to delete partitions
            echo -e "d\n4\nd\n5\nw" | chroot /localroot fdisk "$intdis" >/dev/null 2>&1
            
            # Cleanup
            umount /localroot/dev
            umount /localroot
            rmdir /localroot
            
            crossystem disable_dev_request=1 2>/dev/null
            
            # Try to mount stateful partition
            if ! mount "${intdis}${intdis_prefix}1" /stateful 2>/dev/null; then
                mountlvm
                if [ $? -ne 0 ]; then
                    read -p "Press Enter to return to menu..."
                    continue
                fi
            fi
            
            # Clear stateful partition
            rm -rf /stateful/*
            umount /stateful
            
            echo "Daub completed successfully!"
            read -p "Press Enter to return to menu..."
            ;;
        2)
            # get_internal take from https://github.com/applefritter-inc/BadApple-icarus
            get_internal() {
                local ROOTDEV_LIST=$(cgpt find -t rootfs)
                if [ -z "$ROOTDEV_LIST" ]; then
                    echo "Could not find root devices."
                    read -p "Press Enter to return to menu..."
                    return 1
                fi
                local device_type=$(echo "$ROOTDEV_LIST" | grep -oE 'mmc|nvme|sda' | head -n 1)
                case $device_type in
                "mmc")
                    intdis=/dev/mmcblk0
                    intdis_prefix="p"
                    ;;
                "nvme")
                    intdis=/dev/nvme0
                    intdis_prefix="n"
                    ;;
                "sda")
                    intdis=/dev/sda
                    intdis_prefix=""
                    ;;
                *)
                    echo "an unknown error occured. this should not have happened."
                    read -p "Press Enter to return to menu..."
                    return 1
                    ;;
                esac
            }
            
            get_internal || continue
            
            echo "Detected internal disk: $intdis"
            
            # Create stateful directory if it doesn't exist
            mkdir -p /stateful
            
            # Try to mount stateful partition
            if ! mount "${intdis}${intdis_prefix}1" /stateful 2>/dev/null; then
                mountlvm
                if [ $? -ne 0 ]; then
                    read -p "Press Enter to return to menu..."
                    continue
                fi
            fi
            
            # Unmount first to format
            umount /stateful 2>/dev/null
            
            # Format the stateful partition
            echo "Formatting ${intdis}${intdis_prefix}1 with ext4..."
            mkfs.ext4 "${intdis}${intdis_prefix}1" 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "Failed to format stateful partition"
                read -p "Press Enter to return to menu..."
                continue
            fi
            echo "Powerwash completed successfully!"
            echo "DO NOT POWERWASH IN CHROMEOS! YOU MUST USE THE POWERWASH OPTION IN THIS SHIM INSTEAD, OTHERWISE YOUR DEVICE WILL BOOTLOOP! (bootloop is fixable by recovering)
            read -p "Press Enter to return to menu..."
            ;;
        3)
            echo "Type 'exit' to go back to main menu"
            /bin/bash 2>/dev/null
            ;;
        4)
            reboot -f
            ;;
        *)
            echo "Invalid option, please try again..."
            read -p "Press Enter to return to menu..."
            ;;
    esac
done

# written mostly by HarryJarry1
mountlvm(){
     vgchange -ay #active all volume groups
     volgroup=$(vgscan | grep "Found volume group" | awk '{print $4}' | tr -d '"')
     echo "found volume group:  $volgroup"
     mount "/dev/$volgroup/unencrypted" /stateful || {
         echo "couldnt mount p1 or lvm group.  Please recover"
         return 1
     }
}
