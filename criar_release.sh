#!/bin/bash

# Configurações de diretório
DIR_PROJETO="/root/FarmBOT"
ARQUIVO_CREDENCIAIS="${DIR_PROJETO}/enviar_git"
EXE_NOME="FarmBOTMir4.exe"

cd "$DIR_PROJETO" || { echo "Erro: Pasta $DIR_PROJETO não encontrada."; exit 1; }

# 1. 🟢 RECUPERA O TOKEN AUTOMATICAMENTE
if [ -f "$ARQUIVO_CREDENCIAIS" ]; then
    # Extrai apenas o Token da URL salva no arquivo (o texto entre o ':' e o '@')
    GIT_TOKEN=$(cat "$ARQUIVO_CREDENCIAIS" | sed -n 's/.*:\(.*\)@.*/\1/p')
else
    echo "=== TOKEN NÃO ENCONTRADO ==="
    read -sp "Cole seu GitHub Token (GH_TOKEN) para continuar: " GIT_TOKEN
    echo ""
fi

# Exporta o token para que o comando 'gh' (GitHub CLI) consiga autenticar
export GH_TOKEN="$GIT_TOKEN"

# 2. 🟡 VALIDAÇÃO DA FERRAMENTA GH (GitHub CLI)
if ! command -v gh &> /dev/null; then
    echo "[ERRO] A ferramenta 'gh' não está instalada. Instale com: sudo apt install gh"
    exit 1
fi

# 3. 🔵 SOLICITAÇÃO DA VERSÃO
echo "=== CRIAÇÃO DE RELEASE GITHUB ==="
read -p "Digite a versão da Release (Ex: v1.2.20260702): " VERSAO_ALVO

# Verifica se o arquivo .exe existe antes de tentar enviar
if [ ! -f "/$EXE_NOME" ]; then
    echo "[ERRO] Arquivo $EXE_NOME não encontrado na pasta para upload."
    exit 1
fi

# 4. 🚀 EXECUÇÃO DA RELEASE
echo "Criando release $VERSAO_ALVO e enviando o executável..."

# Comando oficial para criar a release, subir o arquivo e definir título/notas
gh release create "$VERSAO_ALVO" "./$EXE_NOME" \
    --title "FarmBOT $VERSAO_ALVO" \
    --notes "Lançamento automatizado do executável FarmBOTMir4.exe"

if [ $? -eq  ]; then
    echo ""
    echo "[SUCESSO] Release $VERSAO_ALVO criada e arquivo enviado!"
else
    echo ""
    echo "[FALHA] Não foi possível criar a release. Verifique o Token ou se a versão já existe."
fi
