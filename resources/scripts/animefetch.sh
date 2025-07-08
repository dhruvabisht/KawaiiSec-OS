#!/bin/bash

# ASCII Mascot - Cute hacker chibi with cat-ears
if [[ "$1" != "--no-ascii" ]]; then
  cat << "EOF"
      ／＞　 フ
     | 　_　_| 
   ／` ミ＿xノ 
  /　　　　 |
 /　 ヽ　　 ﾉ
│　　|　|　|
／￣|　　 |　|
(￣ヽ＿_ヽ_)__)
＼二)

EOF
fi

# Get memory info from macOS vm_stat
mem_used=$(vm_stat | awk '/Pages active/ {active=$3} /Pages wired/ {wired=$3} /Pages speculative/ {spec=$3} END {used=(active + wired + spec) * 4096 / 1048576; printf("%.0fMB", used)}')
mem_total=$(sysctl -n hw.memsize | awk '{printf("%.0fMB", $1 / 1048576)}')

echo -e "\033[1;35m     🌸 KawaiiSec OS 🌸"
echo -e "\033[0;35m   Cute. Dangerous. UwU-powered.\033[0m"
echo
echo -e "\033[1;34mUser:\033[0m       $(whoami)"
echo -e "\033[1;34mHost:\033[0m       $(hostname)"
echo -e "\033[1;34mUptime:\033[0m     $(uptime | sed 's/.*up \([^,]*\), .*/\1/')"
echo -e "\033[1;34mOS:\033[0m         $(uname -o 2>/dev/null || echo Darwin)"
echo -e "\033[1;34mKernel:\033[0m     $(uname -r)"
echo -e "\033[1;34mShell:\033[0m      $SHELL"
echo -e "\033[1;34mMemory:\033[0m     $mem_used / $mem_total"
echo
echo -e "\033[1;35mStay cute, stay root 💖\033[0m"
