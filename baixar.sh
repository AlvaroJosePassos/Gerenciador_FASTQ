
#!/bin/bash

# ==========================================================
# GERENCIADOR DE DOWNLOADS FASTQ - BIOTECH
# VERSAO 2.1 - PAINEL DE PROGRESSO
# ==========================================================

# CONFIGURACOES

LISTA="lista.txt"
EXCLUSAO="exclusao.txt"
PASTA="arquivos_fastq"
LOGS="logs_download"

CONEXOES=8
PARALELOS=2

EXECUCAO=$(date +%Y%m%d_%H%M%S)

# ==========================================================
# VERIFICACOES INICIAIS
# ==========================================================

for COMANDO in aria2c gzip sed basename tr grep tail date; do
    if ! command -v "$COMANDO" >/dev/null 2>&1; then
        echo "Erro: comando $COMANDO nao encontrado."
        exit 1
    fi
done

if [ ! -f "$LISTA" ]; then
    echo "Erro: arquivo $LISTA nao encontrado."
    exit 1
fi

if ! [[ "$CONEXOES" =~ ^[0-9]+$ ]] ||
   ! [[ "$PARALELOS" =~ ^[0-9]+$ ]] ||
   [ "$CONEXOES" -lt 1 ] ||
   [ "$PARALELOS" -lt 1 ]; then
    echo "Erro: configuracoes invalidas."
    exit 1
fi

mkdir -p "$PASTA" "$LOGS" || {
    echo "Erro ao criar diretorios."
    exit 1
}

touch "$EXCLUSAO" || {
    echo "Erro ao criar lista de exclusao."
    exit 1
}

# ==========================================================
# ESCOLHER PONTO DE INICIO
# ==========================================================

echo "=========================================="
echo "       GERENCIADOR FASTQ - BIOTECH"
echo "                VERSAO 2.1"
echo "=========================================="

read -r -p "A partir de qual linha deseja iniciar? [1]: " INICIO
INICIO=${INICIO:-1}

if ! [[ "$INICIO" =~ ^[0-9]+$ ]] || [ "$INICIO" -lt 1 ]; then
    echo "Linha inicial invalida!"
    exit 1
fi

echo ""
echo "Linha inicial: $INICIO"
echo "Conexoes por arquivo: $CONEXOES"
echo "Downloads simultaneos: $PARALELOS"
echo "Pasta de destino: $PASTA"
echo "Pasta de logs: $LOGS"
echo ""

read -r -p "Pressione ENTER para iniciar..."

# ==========================================================
# CONTADORES
# ==========================================================

URLS_VALIDAS=0
INICIADOS=0
SUCESSO=0
ERRO=0
EXCLUIDOS=0
EXISTENTES=0
DUPLICADOS=0
INVALIDOS=0

# ==========================================================
# CONTROLE DOS PROCESSOS
# ==========================================================

PIDS=()
NOMES=()
DESTINOS=()
ARQUIVOS_LOG=()

declare -A NOMES_RESERVADOS=()

# ==========================================================
# FUNCAO: LIMPAR PAINEL
# ==========================================================

limpar_painel() {

    # Verifica se a saida esta conectada a um terminal
    if [[ -t 1 ]]; then

        # Limpa a tela e posiciona o cursor no inicio
        clear

    fi
}

# ==========================================================
# FUNCAO: OBTER PROGRESSO DO ARIA2
# ==========================================================

obter_progresso() {

    local LOG="$1"
    local STATUS
    local PCT
    local VELOCIDADE
    local ETA

    PCT="0"
    VELOCIDADE="--"
    ETA="calculando"

    if [ -f "$LOG" ]; then

        STATUS=$(tr '\r' '\n' < "$LOG" |
            grep -E '\([0-9]+%\)' |
            tail -n 1)

        if [[ -n "$STATUS" ]]; then

            PCT=$(echo "$STATUS" |
                sed -nE 's/.*\(([0-9]+)%\).*/\1/p')

            VELOCIDADE=$(echo "$STATUS" |
                sed -nE 's/.*DL:([^ ]+).*/\1/p')

            ETA=$(echo "$STATUS" |
                sed -nE 's/.*ETA:([^]]+).*/\1/p')

        fi
    fi

    [[ "$PCT" =~ ^[0-9]+$ ]] || PCT=0
    [[ -n "$VELOCIDADE" ]] || VELOCIDADE="--"
    [[ -n "$ETA" ]] || ETA="calculando"

    echo "$PCT|$VELOCIDADE|$ETA"
}

# ==========================================================
# FUNCAO: BARRA DE PROGRESSO
# ==========================================================

criar_barra() {

    local PCT="$1"
    local TAMANHO=20
    local PREENCHIDO
    local VAZIO
    local BARRA1
    local BARRA2

    PREENCHIDO=$((PCT * TAMANHO / 100))
    VAZIO=$((TAMANHO - PREENCHIDO))

    printf -v BARRA1 '%*s' "$PREENCHIDO" ''
    printf -v BARRA2 '%*s' "$VAZIO" ''

    BARRA1=${BARRA1// /█}
    BARRA2=${BARRA2// /░}

    echo "${BARRA1}${BARRA2}"
}

# ==========================================================
# FUNCAO: EXIBIR PAINEL
# ==========================================================

exibir_painel() {

    [[ -t 1 ]] || return

    limpar_painel

    echo "======================================================"
    echo "           GERENCIADOR FASTQ - BIOTECH"
    echo "                  VERSAO 2.1"
    echo "======================================================"
    echo ""

    echo " DOWNLOADS EM ANDAMENTO"
    echo "------------------------------------------------------"

    if [ "${#PIDS[@]}" -eq 0 ]; then
        echo " Nenhum download ativo."
    fi

    for i in "${!PIDS[@]}"; do

        NOME="${NOMES[$i]}"
        LOG="${ARQUIVOS_LOG[$i]}"

        DADOS=$(obter_progresso "$LOG")

        PCT="${DADOS%%|*}"
        RESTO="${DADOS#*|}"

        VELOCIDADE="${RESTO%%|*}"
        ETA="${RESTO#*|}"

        BARRA=$(criar_barra "$PCT")

        echo ""
        echo " Arquivo: $NOME"
        echo " [$BARRA] ${PCT}%"
        echo " Velocidade: $VELOCIDADE"
        echo " Tempo restante: $ETA"

    done

    echo ""
    echo "======================================================"
    echo "                  RESUMO"
    echo "======================================================"

    echo " Downloads ativos: ${#PIDS[@]} / $PARALELOS"
    echo " Downloads iniciados: $INICIADOS"
    echo " Concluidos: $SUCESSO"
    echo " Com erro: $ERRO"
    echo " Excluidos: $EXCLUIDOS"
    echo " Ja existentes: $EXISTENTES"
    echo " Duplicados: $DUPLICADOS"
    echo " Invalidos: $INVALIDOS"

    echo ""
    echo " Atualizacao automatica a cada segundo."
    echo " Pressione CTRL+C para interromper com seguranca."
    echo "======================================================"
}

# ==========================================================
# TRATAMENTO DE INTERRUPCOES
# ==========================================================

interromper() {

    local SINAL="$1"
    local CODIGO=130

    [[ "$SINAL" == "TERM" ]] && CODIGO=143

    trap - INT TERM

    limpar_painel

    echo ""
    echo "=========================================="
    echo "INTERRUPCAO SOLICITADA"
    echo "=========================================="

    echo "Solicitando parada dos downloads..."

    for PID in "${PIDS[@]}"; do
        kill -INT "$PID" 2>/dev/null || true
    done

    for PID in "${PIDS[@]}"; do
        wait "$PID" 2>/dev/null || true
    done

    echo ""
    echo "Downloads interrompidos."
    echo "Os arquivos de controle do Aria2 foram preservados quando possivel."
    echo "Execute novamente para tentar retomar as transferencias."
    echo ""
    echo "Logs: $LOGS"

    exit "$CODIGO"
}

trap 'interromper INT' INT
trap 'interromper TERM' TERM

# ==========================================================
# FUNCAO: VALIDAR DOWNLOAD CONCLUIDO
# ==========================================================

validar_download() {

    local DESTINO="$1"
    local NOME="$2"
    local LOG="$3"

    if [ ! -s "$DESTINO" ]; then

        echo "[ERRO] Arquivo ausente ou vazio: $NOME"
        echo "Arquivo ausente ou vazio." >> "$LOG"
        ERRO=$((ERRO + 1))

    elif [[ "$NOME" == *.gz ]]; then

        if gzip -t "$DESTINO" >> "$LOG" 2>&1; then

            echo "[SUCESSO] $NOME"
            SUCESSO=$((SUCESSO + 1))

        else

            echo "[ERRO] Arquivo gzip invalido: $NOME"
            echo "Falha na verificacao gzip." >> "$LOG"
            ERRO=$((ERRO + 1))

        fi

    else

        echo "[SUCESSO] $NOME"
        SUCESSO=$((SUCESSO + 1))

    fi
}

# ==========================================================
# FUNCAO: FINALIZAR DOWNLOADS E ATUALIZAR PAINEL
# ==========================================================

finalizar_lote() {

    while [ "${#PIDS[@]}" -gt 0 ]; do

        exibir_painel

        # Verifica individualmente quais processos terminaram.
        for ((i=${#PIDS[@]}-1; i>=0; i--)); do

            PID="${PIDS[$i]}"

            if ! kill -0 "$PID" 2>/dev/null; then

                if wait "$PID"; then
                    STATUS=0
                else
                    STATUS=$?
                fi

                DESTINO="${DESTINOS[$i]}"
                NOME="${NOMES[$i]}"
                LOG="${ARQUIVOS_LOG[$i]}"

                if [ "$STATUS" -eq 0 ]; then
                    validar_download "$DESTINO" "$NOME" "$LOG"
                else
                    echo "[ERRO] $NOME"
                    echo "Detalhes do erro:"
                    tail -n 8 "$LOG"
                    ERRO=$((ERRO + 1))
                fi

                unset 'PIDS[i]'
                unset 'NOMES[i]'
                unset 'DESTINOS[i]'
                unset 'ARQUIVOS_LOG[i]'

            fi

        done

        # Reorganiza os vetores depois das remocoes.
        PIDS=("${PIDS[@]}")
        NOMES=("${NOMES[@]}")
        DESTINOS=("${DESTINOS[@]}")
        ARQUIVOS_LOG=("${ARQUIVOS_LOG[@]}")

        if [ "${#PIDS[@]}" -gt 0 ]; then
            sleep 1
        fi

    done

    limpar_painel
}

# ==========================================================
# LEITURA DA LISTA PRINCIPAL
# ==========================================================

LINHA=0

while IFS= read -r URL || [[ -n "$URL" ]]; do

    LINHA=$((LINHA + 1))

    if [ "$LINHA" -lt "$INICIO" ]; then
        continue
    fi

    URL="${URL%$'\r'}"

    [[ -z "$URL" || "$URL" =~ ^[[:space:]]*# ]] && continue

    # ======================================================
    # VALIDAR URL
    # ======================================================

    if [[ ! "$URL" =~ ^https?:// ]]; then

        echo "[ERRO] URL invalida na linha $LINHA"

        INVALIDOS=$((INVALIDOS + 1))
        ERRO=$((ERRO + 1))

        continue
    fi

    # ======================================================
    # IDENTIFICAR NOME DO ARQUIVO
    # ======================================================

    URL_LIMPA="${URL%%\?*}"
    URL_LIMPA="${URL_LIMPA%%\#*}"

    NOME=$(basename "$URL_LIMPA")

    if [[ -z "$NOME" || "$NOME" == "." || "$NOME" == "/" ]]; then

        echo "[ERRO] Nome de arquivo invalido na linha $LINHA"

        INVALIDOS=$((INVALIDOS + 1))
        ERRO=$((ERRO + 1))

        continue
    fi

    URLS_VALIDAS=$((URLS_VALIDAS + 1))

    DESTINO="$PASTA/$NOME"

    # ======================================================
    # VERIFICAR LISTA DE EXCLUSAO
    # ======================================================

    EXCLUIR=false

    while IFS= read -r ITEM || [[ -n "$ITEM" ]]; do

        ITEM="${ITEM%$'\r'}"

        ITEM=$(echo "$ITEM" |
            sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        [[ -z "$ITEM" || "$ITEM" == \#* ]] && continue

        if [[ "$ITEM" == "$URL" || "$ITEM" == "$NOME" ]]; then
            EXCLUIR=true
            break
        fi

    done < "$EXCLUSAO"

    if [[ "$EXCLUIR" == true ]]; then

        echo "[EXCLUIDO] Linha $LINHA: $NOME"
        EXCLUIDOS=$((EXCLUIDOS + 1))

        continue
    fi

    # ======================================================
    # VERIFICAR ARQUIVOS JA EXISTENTES
    # ======================================================

    if [ -f "$DESTINO" ] && [ ! -f "$DESTINO.aria2" ]; then

        if [[ "$NOME" == *.gz ]]; then

            if gzip -t "$DESTINO" 2>/dev/null; then

                echo "[JA EXISTE] $NOME"
                EXISTENTES=$((EXISTENTES + 1))

                continue

            else

                echo "[AVISO] Arquivo gzip invalido: $NOME"

                ARQUIVO_INVALIDO="$DESTINO.invalido.$EXECUCAO"

                if ! mv "$DESTINO" "$ARQUIVO_INVALIDO"; then

                    echo "[ERRO] Nao foi possivel renomear $NOME"
                    ERRO=$((ERRO + 1))

                    continue
                fi

                INVALIDOS=$((INVALIDOS + 1))

            fi

        else

            echo "[JA EXISTE] $NOME"
            EXISTENTES=$((EXISTENTES + 1))

            continue

        fi
    fi

    # ======================================================
    # EVITAR NOMES DUPLICADOS
    # ======================================================

    if [[ -n "${NOMES_RESERVADOS[$NOME]+x}" ]]; then

        echo "[DUPLICADO] Linha $LINHA: $NOME"
        DUPLICADOS=$((DUPLICADOS + 1))

        continue
    fi

    NOMES_RESERVADOS["$NOME"]=1

    # ======================================================
    # INICIAR DOWNLOAD
    # ======================================================

    ARQUIVO_LOG="$LOGS/linha_${LINHA}_${EXECUCAO}.log"

    aria2c \
        --continue=true \
        --max-connection-per-server="$CONEXOES" \
        --split="$CONEXOES" \
        --min-split-size=1M \
        --file-allocation=none \
        --auto-file-renaming=false \
        --max-tries=5 \
        --retry-wait=10 \
        --timeout=30 \
        --connect-timeout=30 \
        --summary-interval=1 \
        --console-log-level=notice \
        --dir="$PASTA" \
        --out="$NOME" \
        "$URL" > "$ARQUIVO_LOG" 2>&1 &

    PID=$!

    PIDS+=("$PID")
    NOMES+=("$NOME")
    DESTINOS+=("$DESTINO")
    ARQUIVOS_LOG+=("$ARQUIVO_LOG")

    INICIADOS=$((INICIADOS + 1))

    # ======================================================
    # CONTROLAR DOWNLOADS SIMULTANEOS
    # ======================================================

    if [ "${#PIDS[@]}" -ge "$PARALELOS" ]; then
        finalizar_lote
    fi

done < "$LISTA"

# ==========================================================
# FINALIZAR DOWNLOADS RESTANTES
# ==========================================================

finalizar_lote

# ==========================================================
# RELATORIO FINAL
# ==========================================================

trap - INT TERM

echo ""
echo "=========================================="
echo "              RELATORIO FINAL"
echo "       GERENCIADOR FASTQ - BIOTECH"
echo "=========================================="

echo ""
echo "URLs validas analisadas: $URLS_VALIDAS"
echo "Downloads iniciados: $INICIADOS"
echo "Concluidos: $SUCESSO"
echo "Com erro: $ERRO"
echo "Excluidos: $EXCLUIDOS"
echo "Ja existentes: $EXISTENTES"
echo "Duplicados: $DUPLICADOS"
echo "Arquivos invalidos encontrados: $INVALIDOS"

echo ""
echo "Linha inicial: $INICIO"
echo "Pasta de arquivos: $PASTA"
echo "Pasta de logs: $LOGS"
echo "Identificador da execucao: $EXECUCAO"

echo ""
echo "=========================================="

if [ "$ERRO" -gt 0 ]; then

    echo "ATENCAO: Foram encontrados erros."
    echo "Consulte os logs para identificar os problemas."

elif [ "$INICIADOS" -eq 0 ]; then

    echo "Nenhum novo download precisou ser iniciado."

else

    echo "Todos os downloads iniciados foram concluidos!"

fi

echo "=========================================="
