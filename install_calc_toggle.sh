#!/bin/bash

source non_sudo_check.sh

# INHERIT VARS
INSTALL_DIR_PATH="/usr/share/asus-numberpad-driver"

if [ -z "$INSTALL_DIR_PATH" ]; then
    INSTALL_DIR_PATH="/usr/share/asus-numberpad-driver"
fi

echo "Calculator app"
echo

if [[ $(type gsettings 2>/dev/null) ]]; then

    read -r -p "Do you want try to install toggling script for XF86Calculator key? [y/N]" response
    case "$response" in [yY][eE][sS]|[yY])

        echo

        EXISTING_SHORTCUT_STRING=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

        NEW_SHORTCUT_INDEX=0
        filtered_existing_shortcut_string="["
        filtered_existing_shortcut_count=0

        if [[ "$EXISTING_SHORTCUT_STRING" != "@as []" ]]; then
            IFS=', ' read -ra existing_shortcut_array <<< "$EXISTING_SHORTCUT_STRING"
            for shortcut_index in "${!existing_shortcut_array[@]}"; do
                shortcut="${existing_shortcut_array[$shortcut_index]}"
                shortcut_index=$( echo $shortcut | cut -d/ -f 8 | sed 's/[^0-9]//g')

                # looking for first free highest index (gaps will not be used for sure)
                if [[ "$shortcut_index" -gt "$NEW_SHORTCUT_INDEX" ]]; then
                    NEW_SHORTCUT_INDEX=$shortcut_index
                fi

                # filter out already added the same shortcuts by this driver (can be caused by running install script multiple times so clean and then add only 1 new - we want no duplicates)
                command=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/ 'command')
                if [[ "$command" != "'bash /usr/share/asus_touchpad_numpad-driver/scripts/calculator_toggle.sh'" ]]; then
                    #echo "Found something else on index $shortcut_index"
                    if [[ "$filtered_existing_shortcut_string" != "[" ]]; then
                        filtered_existing_shortcut_string="$filtered_existing_shortcut_string"", '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/'"
                    else
                        filtered_existing_shortcut_string="$filtered_existing_shortcut_string""'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/'"
                    fi
                else
                    echo "Found already existing duplicated shortcut for toggling calculator, will be removed"
                    ((filtered_existing_shortcut_count=filtered_existing_shortcut_count+1))
                    gsettings reset-recursively org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/
                fi
            done
            ((NEW_SHORTCUT_INDEX=NEW_SHORTCUT_INDEX+1))

            filtered_existing_shortcut_string="$filtered_existing_shortcut_string"']'

            if [[ $filtered_existing_shortcut_count != 0 ]]; then
                new_shortcut_string=${filtered_existing_shortcut_string::-2}", /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$NEW_SHORTCUT_INDEX']"
            else
                # after filtering duplicated shortcuts array of shortcuts is completely empty
                new_shortcut_string=" ['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0']"
            fi
        else
            # array of shortcuts is completely empty
            new_shortcut_string=" ['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0']"
        fi

        IS_INSTALLED_ELEMENTARY_OS_CALCULATOR=$(type io.elementary.calculator &>/dev/null ; echo $? )
        if [ $IS_INSTALLED_ELEMENTARY_OS_CALCULATOR == "0" ]; then
            echo "Detected io.elementary.calculator"
        fi

        IS_INSTALLED_GNOME_OS_CALCULATOR=$(type gnome-calculator &>/dev/null ; echo $? )
        if [ $IS_INSTALLED_GNOME_OS_CALCULATOR == "0" ]; then
            echo "Detected gnome-calculator"
        fi

        if [[ $IS_INSTALLED_ELEMENTARY_OS_CALCULATOR -eq 0 ]]; then
            echo "Setting up for io.elementary.calculator"

            mkdir -p $INSTALL_DIR_PATH/scripts
            cp scripts/io_elementary_calculator_toggle.sh $INSTALL_DIR_PATH/scripts/calculator_toggle.sh
            chmod +x $INSTALL_DIR_PATH/scripts/calculator_toggle.sh

            # this has to be empty (no doubled XF86Calculator)
            gsettings set org.gnome.settings-daemon.plugins.media-keys calculator [\'\']
            gsettings set org.gnome.settings-daemon.plugins.media-keys calculator-static [\'\']

            gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${new_shortcut_string}"
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$NEW_SHORTCUT_INDEX/ "name" "Calculator"
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$NEW_SHORTCUT_INDEX/ "command" "bash $INSTALL_DIR_PATH/scripts/calculator_toggle.sh"
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$NEW_SHORTCUT_INDEX/ "binding" "XF86Calculator"

            EXISTING_SHORTCUT_STRING=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

            echo "Toggling script for calculator app io.elementary.calculator has been installed."

        elif [[ $IS_INSTALLED_GNOME_OS_CALCULATOR -eq 0 ]]; then
            echo "Setting up for gnome-calculator"

            mkdir -p /usr/share/asus_touchpad_numpad-driver/scripts
            cp scripts/gnome_calculator_toggle.sh /usr/share/asus_touchpad_numpad-driver/scripts/calculator_toggle.sh
            chmod +x /usr/share/asus_touchpad_numpad-driver/scripts/calculator_toggle.sh

            # this has to be empty (no doubled XF86Calculator)
            gsettings set org.gnome.settings-daemon.plugins.media-keys calculator [\'\']
            gsettings set org.gnome.settings-daemon.plugins.media-keys calculator-static [\'\']

            gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${new_shortcut_string}"
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$NEW_SHORTCUT_INDEX/ "name" "Calculator"
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$NEW_SHORTCUT_INDEX/ "command" "bash $INSTALL_DIR_PATH/scripts/calculator_toggle.sh"
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$NEW_SHORTCUT_INDEX/ "binding" "XF86Calculator"

            EXISTING_SHORTCUT_STRING=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

            echo "Toggling script for calculator app gnome-calculator has been installed."
        else
           echo "Automatic installing of toggling script for XF86Calculator key failed. Please create an issue (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues)."
        fi
        ;;
    *)
        ;;
    esac
else
    echo "Automatic installing of toggling script for XF86Calculator key failed. Gsettings was not found."
fi