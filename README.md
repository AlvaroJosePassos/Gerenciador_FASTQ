# 🧬 GERENCIADOR DE DOWNLOADS FASTQ - BIOTECH

Gerenciador de downloads desenvolvido em **Bash**, utilizando o **Aria2**, para automatizar a transferência de arquivos FASTQ e FASTQ compactados (`.fastq.gz`).

A ferramenta foi desenvolvida para facilitar o download de grandes conjuntos de dados, oferecendo controle de transferências simultâneas, retomada de downloads interrompidos, verificação de integridade e organização dos arquivos.

---

## 📌 1. Funcionalidades

- **Downloads simultâneos:** realiza o download de vários arquivos ao mesmo tempo.
- **Múltiplas conexões:** utiliza até 8 conexões por arquivo, conforme configuração.
- **Retomada de downloads:** permite continuar transferências interrompidas utilizando o Aria2.
- **Lista de exclusão:** permite ignorar arquivos específicos pelo nome ou pela URL.
- **Identificação de arquivos existentes:** evita baixar novamente arquivos que já estão armazenados e validados.
- **Verificação de integridade:** utiliza `gzip -t` para verificar arquivos compactados.
- **Proteção contra duplicidade:** impede que dois downloads com o mesmo nome sejam iniciados na mesma execução.
- **Tratamento de interrupções:** possui tratamento para `Ctrl+C` e `SIGTERM`.
- **Logs individuais:** registra informações e erros de cada download.
- **Relatório final:** apresenta estatísticas da execução.

---

## 💻 2. Requisitos

Para utilizar o programa, você precisa de:

| Requisito | Descrição |
|---|---|
| Sistema operacional | Linux | WSL
| Interpretador | Bash |
| Gerenciador de downloads | Aria2 |
| Compactação | Gzip |
| Ferramentas auxiliares | sed e coreutils |
| Controle de versão | Git (opcional) |

---

## ⚙️ 3. Tutorial de instalação

### 3.1. Atualizar o sistema

Abra o terminal (no Linux ou do WSL) e execute:

```bash
sudo apt update
```

### 3.2. Instalar as dependências

Execute:

```bash
sudo apt install aria2 gzip git sed coreutils -y
```

### 3.3. Verificar a instalação

Verifique o Aria2:

```bash
aria2c --version
```

Verifique o Gzip:

```bash
gzip --version
```

Verifique o Bash:

```bash
bash --version
```

Se os comandos apresentarem suas respectivas versões, as ferramentas estão disponíveis.

### 3.4. Baixar o projeto pelo GitHub

Clone o repositório:

```bash
git clone https://github.com/AlvaroJosePassos/Gerenciador_FASTQ.git
```

Entre no diretório:

```bash
cd Gerenciador_FASTQ
```

### 3.5. Dar permissão de execução

Execute:

```bash
chmod +x baixar.sh
```

### 3.6. Verificar a sintaxe do script

Antes de executar:

```bash
bash -n baixar.sh
```

Se nenhum erro for apresentado, a verificação de sintaxe foi aprovada.

---

## 📁 4. Organização dos arquivos

A estrutura recomendada do projeto é:

```text
GERENCIADOR-FASTQ/
│
├── baixar.sh
├── lista.txt
├── exclusao.txt
├── README.md
│
├── arquivos_fastq/
│
└── logs_download/
```

| Arquivo ou diretório | Finalidade |
|---|---|
| `baixar.sh` | Script principal da ferramenta. |
| `lista.txt` | Lista de URLs dos arquivos FASTQ. |
| `exclusao.txt` | Lista de arquivos que devem ser ignorados. |
| `README.md` | Documentação do projeto. |
| `arquivos_fastq/` | Armazenamento dos arquivos baixados. |
| `logs_download/` | Armazenamento dos registros de execução. |

As pastas `arquivos_fastq/` e `logs_download/` são criadas automaticamente pelo programa.

O arquivo `exclusao.txt` também é criado automaticamente caso não exista.

---

## 🔗 5. Configurando a lista de downloads

O arquivo `lista.txt` contém as URLs dos arquivos que serão baixados.

Cada URL deve ocupar uma linha.

Exemplo:

```text
https://servidor.com/XXXXXXXX1_1.fastq.gz
https://servidor.com/XXXXXXXX1_2.fastq.gz
https://servidor.com/XXXXXXXX2_1.fastq.gz
https://servidor.com/XXXXXXXX3_1.fastq.gz
```

Também é possível utilizar comentários:

```text
# Primeiro conjunto de sequenciamento
https://servidor.com/XXXXXXXX1_1.fastq.gz
https://servidor.com/XXXXXXXX1_2.fastq.gz

# Segundo conjunto de sequenciamento
https://servidor.com/XXXXXXXX2_1.fastq.gz
```

**Observações:**

- Uma URL por linha.
- Linhas vazias são ignoradas.
- Linhas iniciadas por `#` são consideradas comentários.
- As URLs precisam utilizar HTTP ou HTTPS.
- O programa identifica o nome do arquivo a partir da URL.

---

## 🚫 6. Configurando a lista de exclusão

O arquivo `exclusao.txt` permite determinar quais arquivos não devem ser baixados.

Existem duas formas de exclusão.

### 6.1. Exclusão pelo nome

```text
XXXXXXXX1_1.fastq.gz
XXXXXXXX1_2.fastq.gz
```

### 6.2. Exclusão pela URL completa

```text
https://servidor.com/XXXXXXXX2_1.fastq.gz
https://servidor.com/XXXXXXXX3_1.fastq.gz
```

Também são permitidos comentários:

```text
# Arquivos que nao devem ser baixados
XXXXXXXX1_1.fastq.gz

# URLs ignoradas
https://servidor.com/XXXXXXXX1_1.fastq.gz
```

A comparação é feita pelo nome exato do arquivo ou pela URL exata.

---

## 🚀 7. Como executar o programa

Após configurar `lista.txt` e `exclusao.txt`, execute:

```bash
./baixar.sh
```

O programa apresentará:

```text
==========================================
       GERENCIADOR FASTQ - BIOTECH
                VERSAO 2.0
==========================================

A partir de qual linha deseja iniciar? [1]:
```

Informe a linha desejada.

Exemplo:

```text
A partir de qual linha deseja iniciar? [1]: 2
```

Nesse exemplo, o processamento começará pela segunda linha do arquivo `lista.txt`.

Se pressionar Enter sem informar um número, o processamento começará pela primeira linha.

**Importante:** a numeração considera todas as linhas físicas do arquivo, incluindo comentários e linhas vazias.

---

## 🔧 8. Configurações do programa

As configurações principais ficam no início do script:

```bash
LISTA="lista.txt"
EXCLUSAO="exclusao.txt"
PASTA="arquivos_fastq"
LOGS="logs_download"

CONEXOES=8
PARALELOS=2
```

Descrição:

| Variável | Função | Padrão |
|---|---|---|
| `LISTA` | Arquivo com as URLs. | lista.txt |
| `EXCLUSAO` | Arquivo de exclusão. | exclusao.txt |
| `PASTA` | Diretório dos downloads. | arquivos_fastq |
| `LOGS` | Diretório dos registros. | logs_download |
| `CONEXOES` | Conexões por arquivo. | 8 |
| `PARALELOS` | Downloads simultâneos. | 2 |

### Exemplo de configuração

Para realizar quatro downloads simultâneos com quatro conexões por arquivo:

```bash
CONEXOES=4
PARALELOS=4
```

O desempenho depende da conexão de internet, da capacidade do servidor e dos limites de transferência. Aumentar os valores não garante maior velocidade. (mas é cabível a testes dependendo da velocidade)

---

## ⏸️ 9. Interrupção e retomada de downloads

Uma das principais funcionalidades do programa é permitir a retomada de downloads interrompidos.

O Aria2 utiliza a opção:

```bash
--continue=true
```

Ela permite continuar transferências incompletas quando os arquivos de controle necessários estão preservados.

### 9.1. Exemplo de interrupção

Imagine que o programa esteja baixando:

```text
XXXXXXXX1_1.fastq.gz
```

O download chega a 40% e você precisa interromper a execução.

Pressione:

```text
Ctrl + C
```

O programa solicitará a interrupção dos processos de download e aguardará seu encerramento.

### 9.2. Arquivos após a interrupção

Dependendo do estado da transferência, poderão permanecer:

```text
arquivos_fastq/
│
├── DRR865893_1.fastq.gz
└── DRR865893_1.fastq.gz.aria2
```

O arquivo `.aria2` contém informações necessárias para a retomada.

### 9.3. Como continuar o download

Execute novamente:

```bash
./gerenciador_fastq.sh
```

Quando solicitado, informe a linha correspondente ao arquivo interrompido.

Exemplo:

```text
A partir de qual linha deseja iniciar? [1]: 2
```

O programa identificará que o arquivo parcial não está concluído e chamará o Aria2 novamente.

O Aria2 tentará aproveitar os dados já transferidos, evitando reiniciar o download do zero.

**Atenção:**

- Não apague os arquivos `.aria2` antes de tentar a retomada.
- Preserve o arquivo parcial.
- Utilize a mesma pasta de destino.
- A retomada depende da disponibilidade e compatibilidade dos dados no servidor.
- Não é garantido que todos os servidores aceitem retomada de transferências.

---

## 🧪 10. Verificação de integridade

Após o download, o programa verifica se o arquivo possui a extensão `.gz`.

Nesse caso, executa:

```bash
gzip -t arquivos_fastq/DRR865893_1.fastq.gz
```

Se o teste for aprovado, o arquivo será considerado íntegro em relação à compactação Gzip.

Se apresentar falha, o programa registrará o erro.

Na próxima execução, um arquivo `.gz` inválido encontrado sem arquivo de controle será renomeado com um identificador de data e horário.

Exemplo:

```text
XXXXXXXX1_1.fastq.gz.invalido.20261110_183000
```

---

## 📋 11. Sistema de logs

Os registros são armazenados automaticamente no diretório:

```text
logs_download/
```

Cada tentativa de download recebe um arquivo de log individual, identificado pela linha e pela execução.

Exemplo:

```text
logs_download/
│
├── linha_1_20261110_180000.log
├── linha_2_20261110_180000.log
├── linha_1_20261110_190000.log
└── linha_2_20261110_190000.log
```

Os logs permitem consultar:

- Informações sobre transferências.
- Mensagens do Aria2.
- Problemas de conexão.
- Erros de download.
- Falhas na validação Gzip.

Para visualizar um log:

```bash
cat logs_download/linha_2_20261110_180000.log
```

Para visualizar somente as últimas mensagens:

```bash
tail -n 20 logs_download/linha_2_20261110_180000.log
```

---

## 📊 12. Relatório final

Ao finalizar o processamento, o programa apresenta um relatório semelhante a este:

```text
==========================================
           RELATORIO FINAL
       GERENCIADOR FASTQ - BIOTECH
==========================================

URLs validas analisadas: 10
Downloads iniciados: 7
Concluidos: 6
Com erro: 1
Excluidos: 1
Ja existentes: 1
Duplicados: 1
Arquivos invalidos encontrados: 0

Linha inicial: 1

Pasta de arquivos: arquivos_fastq
Pasta de logs: logs_download

Identificador da execucao: 20261110_180000

==========================================
```

Descrição dos indicadores:

| Indicador | Significado |
|---|---|
| URLs válidas analisadas | Quantidade de URLs válidas processadas. |
| Downloads iniciados | Quantidade de transferências iniciadas. |
| Concluídos | Downloads finalizados e aprovados nas verificações aplicáveis. |
| Com erro | Transferências ou verificações que falharam. |
| Excluídos | Arquivos ignorados pela lista de exclusão. |
| Já existentes | Arquivos previamente encontrados e considerados válidos. |
| Duplicados | Arquivos com nomes já reservados na mesma execução. |
| Arquivos inválidos encontrados | URLs inválidas e arquivos Gzip inválidos identificados. |

---

## 🛠️ 13. Solução de problemas

### Erro: aria2 não está instalado

Execute:

```bash
sudo apt install aria2 -y
```

### Erro: lista.txt não encontrado

Verifique se o arquivo está no mesmo diretório do script:

```bash
ls -l
```

### Erro: gzip não está instalado

Execute:

```bash
sudo apt install gzip -y
```

### Erro: permissão negada

Execute:

```bash
chmod +x baixar.sh
```

### Download interrompido

Execute novamente o programa e informe a linha correspondente ao arquivo.

Não remova o arquivo `.aria2` nem o arquivo parcial antes de tentar a retomada.

### Arquivo já existente

O programa verifica se o arquivo está presente e, no caso de arquivos `.gz`, realiza uma verificação de integridade antes de ignorar o download.

### Arquivo duplicado

Se duas URLs produzirem o mesmo nome de arquivo durante a mesma execução, a segunda será ignorada para evitar conflitos.

### Download com erro

Consulte o log correspondente:

```bash
tail -n 30 logs_download/ARQUIVO_DE_LOG.log
```

---

## 🔒 14. Recomendações de uso

- Utilize listas de URLs organizadas.
- Faça testes com poucos arquivos antes de iniciar grandes transferências.
- Preserve os arquivos de controle `.aria2`.
- Evite excluir arquivos parcialmente baixados.
- Verifique periodicamente os logs.
- Mantenha espaço livre suficiente no armazenamento.
- Ajuste a quantidade de conexões conforme a capacidade do servidor.
- Faça cópias de segurança das listas de URLs e de exclusão.

### Arquivo `.gitignore`

Para evitar enviar dados de download e logs ao GitHub, recomenda-se criar um arquivo `.gitignore` com:

```gitignore
arquivos_fastq/
logs_download/
*.aria2
*.invalido.*
```

---

## 🧬 16. Tecnologias utilizadas

- **Bash:** automação e gerenciamento de processos.
- **Aria2:** gerenciamento de transferências.
- **Gzip:** verificação da integridade dos arquivos compactados.
- **Linux(WSL):** ambiente de execução.

---
