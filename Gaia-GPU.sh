
#!/bin/bash
# Warna teks
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Update sistem & install dependencies (hanya sekali)
prepare_system() {
    echo -e "🔄 ${CYAN}Preparing system (update & install dependencies)...${NC}"
    
    apt update && apt upgrade -y
    apt-get update && apt-get upgrade -y
    apt install -y pciutils lsof curl nvtop btop jq wget unzip git nano

    # Install CUDA Toolkit (hanya jika belum ada)
    if ! command -v nvcc &> /dev/null; then
        echo -e "🚀 ${GREEN}Installing CUDA Toolkit...${NC}"
        CUDA_KEYRING="cuda-keyring_1.1-1_all.deb"
        wget "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/$CUDA_KEYRING"
        dpkg -i $CUDA_KEYRING
        apt-get update
        apt-get install -y cuda-toolkit-12-8
        rm -f $CUDA_KEYRING
    else
        echo -e "✅ ${YELLOW}CUDA Toolkit already installed, skipping...${NC}"
    fi

    echo -e "✅ ${GREEN}System preparation complete!${NC}"
}

# Instalasi banyak node
install_multiple_nodes() {
    read -p "How many nodes do you want to install?: " node_count

    if ! [[ "$node_count" =~ ^[1-9][0-9]*$ ]]; then
        echo -e "${RED}❌ Input should be a positive number, example: 1${NC}"
        return 1
    fi

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
        curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash -s -- --ggmlcuda 12 --base "$node_path"
        source $HOME/.bashrc
        gaianet init --base "$node_path"

        # Update konfigurasi GaiaNet
        CONFIG_URL="https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen-2.5-coder-7b-instruct_rustlang/config.json"
        CONFIG_FILE="$node_path/config.json"

        wget -O "$CONFIG_FILE" "$CONFIG_URL"
        jq '.chat = "https://huggingface.co/gaianet/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-3B-Instruct-Q5_K_M.gguf"' "$CONFIG_FILE" > tmp.json && mv tmp.json "$CONFIG_FILE"
        jq '.chat_name = "Qwen2.5-Coder-3B-Instruct"' "$CONFIG_FILE" > tmp.json && mv tmp.json "$CONFIG_FILE"

        # Cek apakah konfigurasi telah diperbarui
        grep '"chat":' "$CONFIG_FILE"
        grep '"chat_name":' "$CONFIG_FILE"

        gaianet config --base "$node_path" --port "$port"
        gaianet init --base "$node_path"
    done

    echo -e "✅ ${GREEN}All new nodes have been installed successfully!${NC}"
    sleep 2
}

# Start semua node
start_all_nodes() {
    echo -e "🛑 Stopping all existing GaiaNet processes..."
    
    pids=$(pgrep -f "gaianet")
    
    if [[ -n "$pids" ]]; then
        echo -e "🔴 Killing existing GaiaNet processes (PIDs: $pids)"
        kill -9 $pids
    else
        echo -e "✅ No existing GaiaNet processes found."
    fi

    echo -e "🚀 ${GREEN}Starting all nodes...${NC}"
    
    base_dir="$HOME"

    for node_path in "$base_dir"/gaia-*; do
        if [[ -d "$node_path" ]]; then
            echo -e "🟢 ${GREEN}Starting node: $(basename $node_path)...${NC}"
            gaianet start --base "$node_path" &
        fi
    done
    
    echo -e "✅ ${GREEN}All nodes started successfully!${NC}"
}

# Tampilkan info node
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

# Tampilkan menu
show_menu() {
    echo -e "\n${CYAN}=== GaiaNet Node Management ===${NC}"
    echo -e "1️⃣  Prepare (Update & Install Dependencies)"
    echo -e "2️⃣  Install Multiple Nodes"
    echo -e "3️⃣  Start All Nodes"
    echo -e "4️⃣  Show Node Info"
    echo -e "5️⃣  Exit"
}

# Loop menu interaktif
while true; do
    show_menu
    read -p "Select an option (1-5): " choice
    case $choice in
        1) prepare_system ;;
        2) install_multiple_nodes ;;
        3) start_all_nodes ;;
        4) show_info ;;
        5) echo -e "🚪 ${RED}Exiting...${NC}"; break ;;
        *) echo -e "❌ ${RED}Invalid option. Please try again.${NC}" ;;
    esac
    echo ""
done
