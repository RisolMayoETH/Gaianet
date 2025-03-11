#!/bin/bash

# Warna teks
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_menu() {
    echo -e "${CYAN}==============================================${NC}"
    echo -e "  🚀 ${YELLOW}G A I A N E T   N O D E   M A N A G E M E N T${NC} 🚀"
    echo -e ""
    echo -e "                    ${BOLD}${YELLOW}by RisolMayoETH${NC}"
    echo -e ""
    echo -e ""
    echo -e "  ${RED}Big thanks to Andrew|Toda who taught me the beginning of Gaianet${NC}"
    echo -e ""
    echo -e "          ${BOLD}${YELLOW}vortex.gaia.domains or optimize.gaia.domains${NC}"
    echo -e "${CYAN}==============================================${NC}"
    echo -e "  ${GREEN}1.${NC} 📥 Install Node"
    echo -e "  ${GREEN}2.${NC} 🚀 Start a Specific Node"
    echo -e "  ${GREEN}3.${NC} ℹ️  Show Node Data"  # Reset warna sebelum teks
    echo -e "  ${GREEN}4.${NC} ❌ Exit"
    echo -e "${CYAN}==============================================${NC}"
}

install_multiple_nodes() {
    read -p "How many nodes do you want to install?: " node_count

    if ! [[ "$node_count" =~ ^[1-9][0-9]*$ ]]; then
        echo -e "${RED}❌ Input should be a positive number, example: 1${NC}"
        return 1
    fi

    sudo apt update && sudo apt upgrade -y
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install -y curl wget unzip git nano jq lsof

    for ((i=1; i<=node_count; i++)); do
        node_name=$(printf "gaia-%02d" $i)
        node_path="$HOME/$node_name"
        port=$((8000 + i - 1))             

        if [[ -d "$node_path" ]]; then
            echo -e "⚠️  ${YELLOW}Node $node_name already exists, skipping...${NC}"
            continue
        fi

        echo -e "🚀 ${GREEN}Installing node: $node_name...${NC}"
        mkdir -p "$node_path"
        curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash -s -- --base "$node_path"
        source $HOME/.bashrc
        gaianet init --base "$node_path" --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json
        gaianet config --base "$node_path" --port "$port"
        gaianet init --base "$node_path"
    done

    echo -e "✅ ${GREEN}All new nodes have been installed successfully!${NC}"
    sleep 2
}

start_specific_node() {
    read -p "Enter node one by one (example 1 after then 2 and so on): " node_number

    if ! [[ "$node_number" =~ ^[1-9][0-9]*$ ]]; then
        echo -e "${RED}❌ Invalid input! Please enter a valid number.${NC}"
        return 1
    fi
    
    port=$((8000 + node_number - 1))
    echo -e "🛑 Stopping existing process on port $port..."
    pids=$(sudo lsof -t -i:$port 2>/dev/null)
    
    if [[ -n "$pids" ]]; then
        echo -e "🔴 Killing process on port $port (PID: $pids)"
        for pid in $pids; do
            sudo kill -9 "$pid"
        done
    else
        echo -e "✅ No existing process found on port $port."
    fi

    
    node_name=$(printf "gaia-%02d" $node_number)
    node_path="$HOME/$node_name"

    if [[ ! -d "$node_path" ]]; then
        echo -e "${RED}❌ Node $node_name does not exist!${NC}"
        return 1
    fi

    echo -e "🟢 ${GREEN}Starting node: $node_name...${NC}"
    gaianet start --base "$node_path"
}

show_info() {
    echo -e "📡 ${CYAN}Displaying Node Info...${NC}"
    base_dir="$HOME"

    for node_path in "$base_dir"/gaia-*; do
        if [[ -d "$node_path" ]]; then
            echo -e "ℹ️  ${GREEN}Node Info for: $(basename $node_path)${NC}"
            gaianet info --base "$node_path"
        fi
    done
}

while true; do
    show_menu
    read -p "Select an option (1-4): " choice
    case $choice in
        1) install_multiple_nodes ;;
        2) start_specific_node ;;
        3) show_info ;;
        4) echo -e "🚪 ${RED}Exiting...${NC}"; break ;;  # Menggunakan break, bukan exit
        *) echo -e "❌ ${RED}Invalid option. Please try again.${NC}" ;;
    esac
    echo ""
done
