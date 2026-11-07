# ==============================================================================
# 1. POWERLEVEL10K INSTANT PROMPT (Keep at the absolute top)
# ==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================================================================
# 2. ZINIT PLUGIN MANAGER BOOTSTRAP
# ==============================================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Load essential Zinit annexes
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

# ==============================================================================
# 3. THEMES, PLUGINS & SNIPPETS
# ==============================================================================
zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-completions
zinit ice wait lucid; zinit light zsh-users/zsh-syntax-highlighting
zinit ice wait lucid; zinit light zsh-users/zsh-autosuggestions
zinit ice wait lucid; zinit light Aloxaf/fzf-tab

# Oh-My-Zsh Snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::extract   # Archive extractor (extract <filename>)

# ==============================================================================
# 4. PENTESTING HISTORY CONFIGURATION
# ==============================================================================
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY          # Share history fluidly between Herdr panes
setopt HIST_IGNORE_ALL_DUPS    # De-clutter duplicate entries
setopt HIST_IGNORE_SPACE       # Prefix command with a space to hide passwords/keys from history

# ==============================================================================
# 4b. SSH AGENT (shared across terminals, key auto-loaded)
# ==============================================================================
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-$HOME/.ssh}/ssh-agent.sock"
ssh-add -l >/dev/null 2>&1
_ssh_agent_state=$?
if (( _ssh_agent_state == 2 )); then
  rm -f "$SSH_AUTH_SOCK"
  eval "$(ssh-agent -s -a "$SSH_AUTH_SOCK")" >/dev/null 2>&1
  ssh-add -q "$HOME/.ssh/github_access" </dev/null >/dev/null 2>&1
elif (( _ssh_agent_state == 1 )); then
  ssh-add -q "$HOME/.ssh/github_access" </dev/null >/dev/null 2>&1
fi
unset _ssh_agent_state

# ==============================================================================
# 5. MODERN REPLACEMENTS & COMPLETIONS INITIALIZATION
# ==============================================================================
export PATH="/home/schizo/.local/bin:$PATH"

mkdir -p ~/.zfunc
if command -v herdr >/dev/null 2>&1 && [[ ! -f ~/.zfunc/_herdr || ~/.local/bin/herdr -nt ~/.zfunc/_herdr ]]; then
  herdr completion zsh > ~/.zfunc/_herdr 2>/dev/null
fi
fpath=(~/.zfunc $fpath)

autoload -Uz compinit && compinit -i
zinit cdreplay -q

eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Environment Paths
export PATH=$PATH:/opt/android-sdk/platform-tools

# ==============================================================================
# 6. QUALITY OF LIFE & CYBERSECURITY ALIASES
# ==============================================================================
# Core Nav & System
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias update='cachyos-rate-mirrors && sudo pacman -Syu' 
alias grep='grep --color=auto'

# CLI Tools
alias ls='eza -l --group-directories-first'
alias ll='eza -al'
alias cat='bat --style=plain'

# Herdr workspace helpers
alias hs='herdr-sessions'
alias pen='herdr-pentest'
alias snap='herdr-snap'
hws() { herdr workspace list 2>/dev/null | jq -r '.result.workspaces[] | "\(.workspace_id)\t\(.label)"'; }

# Networking & Recon
alias myip="ip -br addr | grep UP"
alias ports="sudo ss -tulanp"
tunip() { ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}'; }
listener() { ncat -l -v -n -p "${1:-4444}"; }
ferox() {
    [[ -n "${1:-}" ]] || { echo "Usage: ferox <url> [wordlist]"; return 1; }
    feroxbuster -u "$1" -w "${2:-/usr/share/wordlists/big.txt}" -d 2 -t 30
}
sniff() { sudo tshark -i "${1:-tun0}" "${@:2}"; }
serve() {
    local ip=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    
    if [[ -z "$ip" ]]; then
        echo "❌ VPN not connected (tun0 not found)."
        return 1
    fi

    echo "✅ Serving on http://$ip:8000"
    echo "📋 Copied IP to clipboard!"
    echo "$ip" | wl-copy  

    python3 -m http.server 8000
}

nscan() {
    if [[ -z "$1" ]]; then
        echo "⚙️ Usage: nscan <ip-or-subnet>"
        return 1
    fi

    # Check if target is a subnet (contains a '/')
    if [[ "$1" == *"/"* ]]; then
        echo "[🔍] Subnet detected. Sweeping for live hosts..."
        # -sn (No port scan), -oG - (Grepable output to stdout)
        local ips=$(nmap -sn "$1" -oG - | awk '/Up$/{print $2}' | paste -sd ' ')
        
        if [[ -n "$ips" ]]; then
            echo "$ips" | wl-copy
            echo "✅ Copied live IPs to clipboard!"
            echo "   IPs: $ips"
        else
            echo "❌ No live hosts found."
        fi

    # Otherwise, treat as a single IP for port scanning
    else
        echo "[🔍] Single IP detected. Running fast all-port scan..."
        # --min-rate 5000 makes this take seconds instead of minutes
        local ports=$(sudo nmap -sS -p- --min-rate 5000 -n -Pn "$1" -oG - | grep -i "Ports:" | grep -oP '\d+(?=/open/)' | paste -sd ',')
        
        if [[ -n "$ports" ]]; then
            echo "$ports" | wl-copy
            echo "✅ Copied open ports to clipboard!"
            echo "   Ports: $ports"
            echo "   Next: nmap -p$ports -sC -sV $1"
        else
            echo "❌ No open ports found."
        fi
    fi
}

# Targeted SSH Connections
alias 242='ssh 242'
alias 181='ssh 181'
alias 133='ssh 133'
alias 225='ssh 225'
alias oracle='ssh oracle'

fast-rdp() {
    sdl-freerdp3 /dynamic-resolution /network:auto /gfx:avc420 +clipboard /v:"$1"
}

vpn() {
    # 1. Catch the 'down' command first so it doesn't need a config file
    if [[ "$1" == "down" ]]; then
        sudo killall openvpn
        echo "VPN disconnected."
        return 0
    fi

    # 2. Map your arguments to their config files
    local config=""
    case "$1" in
        sphtbt) config="$HOME/.vpn/HTB_starting-point_lab_Schiz0_TCP.ovpn" ;;
        sphtbu) config="$HOME/.vpn/HTB_starting-point_lab_Schiz0_UDP.ovpn" ;;
        mhtbt)  config="$HOME/.vpn/schizo-htb-machine-2-tcp.ovpn" ;;
        mhtbu)  config="$HOME/.vpn/schizo-htb-machine-2-udp.ovpn" ;;
        ahtbu)  config="$HOME/.vpn/htb-academy-udp.ovpn" ;;
        thm)    config="$HOME/.vpn/ap-south-1-suheshKasti-regular.ovpn" ;;
        *) 
            echo "Usage: vpn {sphtbt|sphtbu|mhtbt|mhtbu|ahtbu|thm|down}"
            return 1 
            ;;
    esac

    # 3. Ask for sudo password in the foreground
    sudo -v || return 1

    # 4. Run OpenVPN, redirect noisy logs to /tmp, background (&), and disown (!)
    sudo openvpn --config "$config" > "/tmp/vpn_$1.log" 2>&1 &!
    
    echo "[+] Connected to $1 in the background."
    echo "[i] Logs: tail -f /tmp/vpn_$1.log"
}

# ==============================================================================
# 7. THE P10K THEME COUPLING 
# ==============================================================================
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
