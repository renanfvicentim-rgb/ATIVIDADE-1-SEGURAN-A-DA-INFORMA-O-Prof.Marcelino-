# Atividade 04 – RFC 3227 e ordem de volatilidade: coleta de dados voláteis

> **Professor Esp. Marcelino Dias da Silva Junior** · UNINOVE · Disciplina: **Auditoria Forense de Sistemas Digitais**
> **Aulas relacionadas:** Norma Internacional: RFC 3227 · Ordem de volatilidade na análise de evidências

## 🎯 Objetivo
Coletar as evidências de uma máquina **ainda ligada**, na ordem **do mais volátil para o menos volátil**, registrando horário (UTC) e hash de cada coleta.

## 📚 Conceito em 1 minuto
- **RFC 3227:** boas práticas do IETF para coleta e arquivamento de evidências: coletar primeiro e analisar depois, documentar tudo, informar o fuso horário e alterar o mínimo possível.
- **Ordem de volatilidade:** o que some primeiro deve ser coletado primeiro.

```
MAIS VOLÁTIL  ─►  registradores/cache ─► rotas, ARP, processos, conexões, memória
              ─►  arquivos temporários ─► disco ─► logs remotos ─► mídias de arquivo  ─►  MENOS VOLÁTIL
```

- Se o computador for **desligado**, processos, conexões e memória **se perdem**.

## 🧪 Passo a passo

```bash
cd labs/04-coleta-de-dados-volateis
bash simular_incidente.sh
```

O simulador requer `nc` (netcat). A coleta registra informações e estatísticas do sistema, mas não faz uma imagem física da memória RAM; este roteiro é didático e não substitui uma aquisição pericial completa.

**1. Leia o script de coleta ANTES de rodar** (a RFC 3227 pede procedimentos testados e documentados):

```bash
cat coleta_volatil.sh
```

**2. Execute a coleta**

```bash
bash coleta_volatil.sh
```

**3. Analise o que foi coletado**

```bash
ls saida/coleta_*/
cat saida/coleta_*/00_log_coleta.txt
```

Procure sinais do incidente:

```bash
grep 4444 saida/coleta_*/04_conexoes.txt
grep "nc -l" saida/coleta_*/03_processos.txt
grep sessao saida/coleta_*/07_tmp.txt
```

**4. Verifique a integridade da coleta**

```bash
ULTIMA=$(ls -dt saida/coleta_* | head -n 1)
(cd "$ULTIMA" && sha256sum -c SHA256SUMS)
```

**5. "Desligue" o sistema (encerre o processo) e colete de novo**

```bash
pkill -f '[n]c -l -k 127.0.0.1 4444'
bash coleta_volatil.sh
ULTIMA=$(ls -dt saida/coleta_* | head -n 1)
grep 4444 "$ULTIMA/04_conexoes.txt" || echo "Porta 4444 NAO encontrada na coleta $ULTIMA"
```

Após encerrar o listener, a segunda coleta deve deixar de mostrar o socket de escuta na porta **4444** e o processo `nc`. O arquivo temporário permanece até ser removido separadamente.

## Desenvolvimento e resultados esperados

1. Antes da execução, deve-se ler `coleta_volatil.sh` para conhecer os comandos, a ordem de coleta e os arquivos gerados. Esse cuidado ajuda a prever alterações na máquina investigada e a documentar o procedimento.
2. A simulação prepara o cenário do incidente. Na primeira coleta, o computador deve permanecer ligado para preservar as evidências voláteis. A coleta gera uma pasta em `saida/coleta_*`, com o registro dos horários em UTC e local e os hashes dos arquivos coletados.
3. Na análise da primeira coleta, os comandos do roteiro procuram o socket de escuta na porta `4444`, o processo do `nc` que o mantém aberto e o arquivo temporário `/tmp/.sessao_4471`. Esses itens são resultados previstos pelo exercício; a confirmação depende dos arquivos efetivamente gerados.
4. `sha256sum -c SHA256SUMS` compara os arquivos coletados com os hashes registrados. A indicação `OK` para cada arquivo confirma que ele não foi alterado desde o cálculo do hash; divergências devem ser investigadas e documentadas.
5. Após encerrar o processo que escuta na porta `4444`, uma nova coleta não deve encontrar essa conexão. A comparação com a primeira coleta demonstra por que conexões e processos precisam ser registrados enquanto o sistema ainda está ativo.

## ❓ Perguntas
1. Em que ordem o script coletou os dados? Por que processos e conexões vêm antes do disco?
2. Por que o log registra o horário em **UTC** e também o horário local?
3. Que evidência do incidente existia **só** na primeira coleta?
4. A RFC 3227 diz para não confiar nos programas do sistema comprometido. Como o perito resolve isso na prática?
5. O arquivo `/tmp/.sessao_4471` começa com ponto. O que isso significa no Linux?

## Respostas

1. O script registra primeiro o horário; depois, rede (endereços, rotas e vizinhos ARP/ND), processos, sockets, dados do kernel, estatísticas de memória, arquivos temporários, montagens e uso de disco. Os arquivos correspondentes são numerados de `01_horarios.txt` a `09_disco.txt`. Processos e sockets são coletados antes dos dados de disco porque podem desaparecer quando o sistema é desligado ou quando o incidente muda. A leitura de `/proc/meminfo` registra estatísticas, não uma imagem da RAM.
2. O horário em UTC permite comparar os registros com evidências de outros sistemas e fusos sem ambiguidade. O horário local também é registrado para facilitar a compreensão dos acontecimentos por quem administra ou investiga a máquina. Registrar ambos, junto com o fuso, ajuda a construir uma linha do tempo confiável.
3. Conforme o resultado esperado do roteiro, a primeira coleta deve registrar o socket de escuta na porta `4444` e o processo `nc` que o mantém aberto. Depois que esse processo é encerrado, ambos deixam de aparecer na segunda coleta. O arquivo temporário continua existindo até ser removido; portanto, ele não é uma evidência exclusiva da primeira coleta.
4. Em uma investigação real, o perito deve usar ferramentas confiáveis, previamente testadas e, sempre que possível, executadas a partir de uma mídia externa confiável, em vez de depender dos programas instalados no sistema investigado. Deve minimizar alterações na máquina, registrar os procedimentos, preservar as saídas e calcular hashes. A coleta, a cadeia de custódia e as limitações das ferramentas precisam ser documentadas. O script deste exercício é demonstrativo e não deve ser tratado como ferramenta de aquisição pericial completa.
5. No Linux, um nome iniciado por ponto é tratado como oculto por convenção: comandos como `ls` normalmente não o exibem sem a opção `-a`. Isso não significa que o arquivo esteja protegido ou criptografado; ele pode ser listado, por exemplo, com `ls -a /tmp`.
