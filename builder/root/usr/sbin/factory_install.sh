#!/bin/bash
# daub script + powerwash
# Based on work by HarryJarry1

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
            
            # Get internal disk
            root_dev=$(rootdev -s 2>/dev/null)
            if [ -z "$root_dev" ]; then
                ROOTDEV_LIST=$(cgpt find -t rootfs 2>/dev/null)
                if [ -z "$ROOTDEV_LIST" ]; then
                    echo "Could not find root devices."
                    read -p "Press Enter to return to menu..."
                    continue
                fi
                intdis=$(echo "$ROOTDEV_LIST" | head -n1 | sed 's/p[0-9]*$//' | sed 's/n[0-9]*$//')
            else
                intdis=$(echo "$root_dev" | sed 's/p[0-9]*$//' | sed 's/n[0-9]*$//')
            fi
            
            if echo "$intdis" | grep -q "mmcblk"; then
                intdis_prefix="p"
            elif echo "$intdis" | grep -q "nvme"; then
                intdis_prefix="p"
            else
                intdis_prefix=""
            fi
            
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
                # Check if LVM tools are available
                if command -v vgchange >/dev/null 2>&1 && command -v vgscan >/dev/null 2>&1; then
                    vgchange -ay 2>/dev/null
                    volgroup=$(vgscan 2>/dev/null | grep "Found volume group" | awk '{print $4}' | tr -d '"')
                    echo "found volume group: $volgroup"
                    mount "/dev/$volgroup/unencrypted" /stateful 2>/dev/null
                    if [ $? -ne 0 ]; then
                        echo "couldn't mount p1 or lvm group. Please recover"
                        read -p "Press Enter to return to menu..."
                        continue
                    fi
                else
                    echo "LVM tools not available. Cannot mount LVM volumes."
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
            # Get internal disk
            root_dev=$(rootdev -s 2>/dev/null)
            if [ -z "$root_dev" ]; then
                ROOTDEV_LIST=$(cgpt find -t rootfs 2>/dev/null)
                if [ -z "$ROOTDEV_LIST" ]; then
                    echo "Could not find root devices."
                    read -p "Press Enter to return to menu..."
                    continue
                fi
                intdis=$(echo "$ROOTDEV_LIST" | head -n1 | sed 's/p[0-9]*$//' | sed 's/n[0-9]*$//')
            else
                intdis=$(echo "$root_dev" | sed 's/p[0-9]*$//' | sed 's/n[0-9]*$//')
            fi
            
            if echo "$intdis" | grep -q "mmcblk"; then
                intdis_prefix="p"
            elif echo "$intdis" | grep -q "nvme"; then
                intdis_prefix="p"
            else
                intdis_prefix=""
            fi
            
            echo "Detected internal disk: $intdis"
            
            # Create stateful directory if it doesn't exist
            mkdir -p /stateful
            
            # Try to mount stateful partition
            if ! mount "${intdis}${intdis_prefix}1" /stateful 2>/dev/null; then
                # Check if LVM tools are available
                if command -v vgchange >/dev/null 2>&1 && command -v vgscan >/dev/null 2>&1; then
                    vgchange -ay 2>/dev/null
                    volgroup=$(vgscan 2>/dev/null | grep "Found volume group" | awk '{print $4}' | tr -d '"')
                    echo "found volume group: $volgroup"
                    mount "/dev/$volgroup/unencrypted" /stateful 2>/dev/null
                    if [ $? -ne 0 ]; then
                        echo "couldn't mount p1 or lvm group. Please recover"
                        read -p "Press Enter to return to menu..."
                        continue
                    fi
                else
                    echo "LVM tools not available. Cannot mount LVM volumes."
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
