#!/bin/bash

# Pause function
pause() {
  read -p "Press Enter to return to the menu..."
}

display_info() {
}

clear
display_info
echo "============================================================"
echo "                    QEMU Menu"
echo "============================================================"
echo "QEMU STATUS : $swap_status"
echo ""
echo "1. Install QEMU"
echo "2. Install OS"
echo "3. Running OS"
echo "4. Create disk"
echo "0. Exit Program"
echo "============================================================"
read -p "Enter your choice number: " choice

case $choice in
  1)
   
   
    pause
    ;;
  2)
    clear
    echo "You chose: Update SWAP"

    
    pause
    ;;
  3)
    clear
    echo "You chose: Disable SWAP"

    

    echo "Swap disabled."
    pause
    ;;
  0)
    echo "Exiting program."
    exit 0
    ;;
  *)
    echo "Unknown choice."
    pause
    ;;
esac
done
