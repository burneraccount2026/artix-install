#!/bin/bash
# artix-install by burneraccount2026. Licensed under GNU GPL 3.0.

# Formatting stuff. They're just codes that the shell, bash, parses into what their name implies.
# First section; colors.

red='\e[31m'
printf -v green "\001\e[32m\002"
yellow='\e[33m'
blue='\e[34m'
magenta='\e[35m'
cyan='\e[36m'
default='\e[39m'

# General formatting. Should be obvious.

printf -v bold "\001\e[1m\002"
dim='\e[2m'
blinking='\e[5m'
underline='\e[4m'

# Just in case if I need to reset any stuff.

printf -v resetall "\001\e[0m\002"
resetbold='\e[21m'
resetdim='\e[22m'
resetunderline='\e[24m'
resetblink='\e[25m'

# Fetching the system stuff

if [[ -d /sys/firmware/efi ]]; then
  install_systype="UEFI"
else
  install_systype="legacy"
fi

# Just initializing every variable.

timezoneselect=1

install_keymap=""
install_syncmethod=""
install_swap=""

# Debugging. Uncomment only if necessary.
# set -x

# The hall of functions. I use this just to organize my code, especially for stuff I repeat a lot.

senderror () {
	if [[ "$#" -ne 1 ]]; then
		echo -e "${red}${bold}ERROR:${resetall} Invalid number of arguments passed.\n${bold}Proper usage of function:${resetbold} senderror [code]\n\n${yellow}hint: refer to the artix-install documentation directory for more information.${default}"
		exit 1
	fi
	echo -e "${red}${bold}ERROR:${resetall} artix-install has aborted with an error. The error code is $1."
	echo -e "\nFor more information about this code, please look in the documentation directory of the artix-install repository for a detailed guide on error codes."
	exit $1
}

tolower () {
  local varname="$1"
	local -n lowerreturn="${1}"
	lowerreturn="$(echo -e ${!varname} | awk '{print tolower($0)}')"
}

warnfordefaultset () {
  local -n warnreturn="${1}"
  echo -e "${yellow}${bold}WARNING:${resetall} simple-artix-install has detected your output to be empty or out of the scope of the question. ${underline}Setting it to the default option...\n${bold}To clear this message, press any key once it has been completed.${resetall}"
  warnreturn="$2"
  if [[ "$?" -eq 0 ]]; then
    echo -e "${green}${bold}Successfully set the default value! You may press any key to exit now.${resetall}"
  else
    senderror 4
  fi
  read -n1
  clear
}

installquestion () {
  clear
  if [[ "$#" -ne 4 ]] && [[ "$#" -ne 5 ]]; then
    echo -e "${red}${bold}ERROR:${resetall} Invalid number of arguments passed.\n${bold}Proper usage of function:${resetbold} installquestion [messageinquotes] [varname] [answerformat] [default] [amountofoptions]\n\n${yellow}hint: refer to the artix-install documentation directory for more information.${default}" 
    exit 1
  fi

  if [[ "$3" == "yn" ]]; then
    local answer_format_opts_template=(y n)
    local answer_format_opts=()
    local default_formatted="$4"
    tolower default_formatted
    for ((i=0; i<2; i++)); do 
      if [[ "${answer_format_opts_template[${i}]}" == "$default_formatted" ]]; then
        answer_format_opts+=(${green}${bold}${answer_format_opts_template[${i}]}${resetall})
      else
        answer_format_opts+=(${answer_format_opts_template[${i}]})
      fi
    done
    IFS=, answer_format="[${answer_format_opts[*]}]"
  elif [[ "$3" == "open" ]]; then
    local answer_format="[OPEN-ENDED ${green}${bold}[${4}]${resetall}]"
  else
    local n="$5"
    local answer_format_opts=()
    for ((i=1; i<n+1; i++ )); do 
      if [[ "$i" == "$4" ]]; then
        answer_format_opts+=(${green}${bold}${i}${resetall})
      else
        answer_format_opts+=("$i")
      fi
    done
    IFS=, answer_format="[${answer_format_opts[*]}]"
  fi
  local -n installreturn="${2}"
  echo -e "$1\n"
  read -r -p "Answer ${answer_format}: " installreturn

  if [[ "$3" == "yn" ]]; then
    tolower installreturn
    if [[ "$installreturn" != "y" ]] && [[ "$installreturn" != "n" ]]; then
      warnfordefaultset "$2" "$4"
    fi
  fi
    
  if [[ "$3" == "open" ]]; then
    if [[ -z "$installreturn" ]]; then
      warnfordefaultset "$2" "$4"
    fi
  fi

  if [[ "$3" != "yn" ]] && [[ "$3" != "open" ]]; then
    if ! [[ "$installreturn" =~ ^[0-9]+$ ]]; then
      warnfordefaultset "$2" "$4"
    fi
    if [[ "$installreturn" -gt $((n)) ]] || [[ "$installreturn" -lt 1 ]]; then
      warnfordefaultset "$2" "$4"
    fi
  fi

  # FOR DEBUGGING ONLY.
  echo "$installreturn"
}

# The actual code starts here. Using -e here because we need echo to parse backslashes for codes. Without the -e parameter, it wouldn't work.

clear
echo -e "${green}${bold}simple-artix-install v. 1.00 by burneraccount2026 on Github${resetall}"
echo -e "\nartix-install is a shell script that is meant to be the equivalent of ${cyan}Calamares${default} for base installarion CDs on Artix Linux."
echo -e "\nIt was created as a response to the overall bugginess I saw some of my peers and friends go through while trying to install their Artix system via Calamares. This script provides a way for both curious but new Linux users, those who want to avoid Calamares bugginess, and those who want to have a guided install in the base ISO to install Artix."
echo -e "\nIt was also created as a more flexible command line based install script. artix-install has decided to go for a mainly command-based interface over a more menu-like interface like nmtui. For comparison, it has a similar interface to a manual Artix installation."
echo -e "\n${red}As a warning, this script is for ${bold}Artix Linux only.${resetall} If you are on a base Arch installation, then this is not for you."
echo -e "\nThis script is text-based, which means there is no graphic options to control it. You will be asked questions with either [Y/N] or [1,2,3,4,5...n], and you will have to type it out into the terminal. The ${underline}default option${resetunderline} will be picked if your choice is invalid."
echo -e "\n${yellow}WARNING:${default} artix-install has detected your BIOS to be in ${install_systype} mode. If this is incorrect, please submit an issue under the correct format."
echo -e "\nTo know which option will be the default, the default option will be in ${green}green.${default}\nWould you like to start the guided installation? [Y/${green}N${default}]\n"

# Just to take user input that the user can get their little hands into.

read -r -p "ANSWER: " installprompt
tolower installprompt

if [[ "$installprompt" == "y" ]]; then
  clear
	echo -e "${green}${bold}Installation Questions${resetall}"
  echo -e "\nDuring this stage of the guided installation, you will be given numerous questions regarding the installation. You will decide all of the installation steps."
  echo -e "\nArtix-install, as a note, is only meant to install Artix and tries to do that well in exchange, as defined by the Unix philosophy."
  echo -e "\n${red}Any post-installation hiccups that are not caused by a bug in artix-install unfortunately cannot be solved by us due to this. Please try to research the error in question to try to find a solution. If you found a major hiccup that you think is caused by a quirk in the code, clone the repository and submit a pull request.${resetall}\n"
else
	echo -e "\n${bold}Aborting artix-install...${resetall}"
	exit 0
fi

while [[ "${timezoneselect}" -eq 1 ]]; do
  installquestion "What keymap would you like the installer to be in? Type in list to see all keymaps.\n${yellow}${bold}Be careful here. Typing in an invalid keymap will lead to the us keymap being selected. The keymap you choose here will be the one installed onto your system. ${underline}Press the enter key to automatically set the keymap to us if you don't know what keymap you have.${resetall}" install_keymap open "us"
  if [[ "$install_keymap" == "list" ]]; then
    clear
    installquestion "Would you like to search for a specific term? If so, type it in here. If not, press enter to continue without searching for any specific terms.\n${blue}${bold}Note:${resetall} To exit the list once you are in it, simply press q while inside of the list. You should be redirected back to the keymap selector after exiting the keymap list." install_listquery open ""
    ls -R /usr/share/kbd/keymaps/ | grep .map.gz | grep "$install_listquery" | less || senderror 5
  fi
# Adding this in case the user thinks they're cool by putting in an invalid keymap.
  if [[ -z "$(find /usr/share/kbd/keymaps/ -name "${install_keymap}.map.gz")" ]] && [[ "$install_keymap" != "list" ]]; then
    clear
    echo -e "${yellow}${bold}WARNING:${resetall} $install_keymap does not exist. ${cyan}Switching to fallback layout us...${default}\nTo close this message, type any key into the terminal."
    install_keymap="us"
    timezoneselect=0
    loadkeys us
    read -n1
  else
      if [[ "$install_keymap" != "list" ]]; then
        timezoneselect=0
        loadkeys ${install_keymap}
      fi
  fi
done
installquestion "Which service would you like to synchronize the time with?\n\n${green}${bold}[1]:${resetall} Chrony, an alternative to ntpd for synchronizing the clock of your device using the NTP. Supports manual input and some more advanced features, unlike ntpd (recommended).\n${cyan}${bold}[2]:${resetall} ntpd, a more basic time syncrhonizer. Can sometimes not work on certain devices, especially those with a dead CMOS battery.\n${cyan}${bold}[3]:${resetall} No time synchronizer.\n${cyan}${bold}[4]:${resetall} Install both crony and ntpd (not recommended, esp. for minimalists)" install_syncmethod number 1 4

installquestion "How would you like to use swap on your device?\n\n${cyan}${bold}[1]:${resetall} Dedicated swap partition.\n${green}${bold}[2]:${resetall} Zram, compressed swap that resides on your RAM instead of your storage. (recommended)\n${cyan}${bold}[3]:${resetall} Swapfile on root partition\n${cyan}${bold}[4]:${resetall} Swapfile with Zswap\n${cyan}${bold}[5]:${resetall} Swap partition with Zswap" install_swap number 2 5
