#!/usr/bin/env bash
# Script para iniciar/instalar o ComfyUI isoladamente no Mac M1

COMFY_DIR="$HOME/ai-tools/ComfyUI"

if [ ! -d "$COMFY_DIR" ]; then
    echo "ComfyUI não encontrado. Baixando e instalando em $COMFY_DIR..."
    mkdir -p "$HOME/ai-tools"
    cd "$HOME/ai-tools" || exit 1
    git clone https://github.com/comfyanonymous/ComfyUI.git
    cd ComfyUI || exit 1
    
    echo "Criando ambiente virtual Python (venv)..."
    python3 -m venv venv
    source venv/bin/activate
    
    echo "Instalando dependências otimizadas para Mac M1 (PyTorch com suporte a Metal/MPS)..."
    pip install --upgrade pip
    pip install torch torchvision torchaudio
    pip install -r requirements.txt
    
    echo "Baixando um modelo leve (Dreamshaper SD 1.5) para você testar sem travar..."
    curl -L -o models/checkpoints/dreamshaper_8.safetensors https://civitai.com/api/download/models/128713
else
    echo "Iniciando ComfyUI..."
    cd "$COMFY_DIR" || exit 1
    source venv/bin/activate
fi

# O argumento --force-fp16 otimiza o uso da memória unificada no M1
python main.py --force-fp16
