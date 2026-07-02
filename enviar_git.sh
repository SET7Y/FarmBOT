#!/bin/bash

# Configurações globais padrão do seu perfil
git config --global user.name "SET7Y"
git config --global user.email "jogosgratiz@gmail.com"

DIR_PROJETO="/root/FarmBOT"
ARQUIVO_CREDENCIAIS="${DIR_PROJETO}/enviar_git"

cd "$DIR_PROJETO" || { echo "Erro: Pasta não encontrada."; exit 1; }

testar_conexao() {
    git ls-remote origin &>/dev/null
    return $?
}

# 1. 🟢 TENTA LER AS CREDENCIAIS DIRETAMENTE DO ARQUIVO LOCAL CORRIGIDO
if [ -f "$ARQUIVO_CREDENCIAIS" ]; then
    echo "Lendo credenciais do arquivo local..."
    URL_ARQUIVO=$(cat "$ARQUIVO_CREDENCIAIS" | tr -d '\r\n[:space:]')
    
    # Extrai o token puro para exportar no ambiente global do Linux
    GIT_TOKEN=$(echo "$URL_ARQUIVO" | sed -n 's/.*:\(.*\)@.*/\1/p')
    export GH_TOKEN="$GIT_TOKEN"
    
    git remote set-url origin "$URL_ARQUIVO"
    
    if testar_conexao; then
        echo "[SUCESSO] Logado automaticamente via arquivo 'enviar_git'!"
        LOGADO=true
    else
        echo "[AVISO] O token salvo no arquivo falhou. Entrando em modo manual..."
        LOGADO=false
    fi
else
    LOGADO=false
fi

# 2. 🟡 SE O ARQUIVO NÃO EXISTIR OU O TOKEN FALHAR, PEDE OS DADOS
while [ "$LOGADO" = false ]; do
    echo "=== AUTENTICAÇÃO MANUAL NECESSÁRIA ==="
    read -p "Digite seu usuário do GitHub (Ex: SET7Y): " GIT_USER
    read -sp "Digite seu Token (GH_TOKEN): " GIT_TOKEN
    echo ""

    # Limpa as variáveis informadas de espaços invisíveis
    GIT_USER=$(echo "$GIT_USER" | tr -d '[:space:]')
    GIT_TOKEN=$(echo "$GIT_TOKEN" | tr -d '[:space:]')
    export GH_TOKEN="$GIT_TOKEN"

    URL_MONTADA="https://${GIT_USER}:${GIT_TOKEN}@://github.com"
    git remote set-url origin "$URL_MONTADA"

    if testar_conexao; then
        echo "[SUCESSO] Autenticação manual aprovada!"
        echo "$URL_MONTADA" > "$ARQUIVO_CREDENCIAIS"
        chmod 600 "$ARQUIVO_CREDENCIAIS"
        echo "Credenciais salvas com sucesso para os próximos logins."
        LOGADO=true
    else
        echo "[ERRO] Usuário ou Token incorretos. Tente novamente."
    fi
done

# 3. 🔵 PROCESSO DE COMMIT (Lógica de versão 1 ou 2)
echo ""
echo "=== CONFIGURAÇÃO DO COMMIT ==="
echo "Escolha o tipo da versão:"
echo "1) Minha versão oficial (Meu=1)"
echo "2) Versão de terceiros / Modificada (2)"
read -p "Opção (1 ou 2): " TIPO_VER

if [ "$TIPO_VER" != "1" ] && [ "$TIPO_VER" != "2" ]; then
    TIPO_VER="1"
fi

DATA_ATUAL=$(date +"%Y%m%d")
MSG_FINAL="Denominando como a versão versão.(${TIPO_VER}).${DATA_ATUAL}"

read -p "Deseja adicionar um comentário complementar? " COMPLEMENTO
if [ ! -z "$COMPLEMENTO" ]; then
    MSG_FINAL="${MSG_FINAL} - ${COMPLEMENTO}"
fi

echo "Enviando alterações para o repositório..."
git add .
git commit -m "$MSG_FINAL"
git push origin main

if [ $? -eq 0 ]; then
    echo "[OK] Projeto atualizado no GitHub com sucesso!"
else
    echo "[FALHA] Erro no envio. Verifique conflitos."
fi
