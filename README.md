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
cd /workspaces/*/labs/04-coleta-de-dados-volateis
bash simular_incidente.sh
```

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
grep sessao saida/coleta_*/09_tmp.txt
```

**4. Verifique a integridade da coleta**

```bash
cd saida/coleta_*/ && sha256sum -c SHA256SUMS && cd -
```

**5. "Desligue" o sistema (encerre o processo) e colete de novo**

```bash
pkill -f "nc -l -k 127.0.0.1 4444"
bash coleta_volatil.sh
ULTIMA=$(ls -d saida/coleta_* | tail -n 1)
grep 4444 "$ULTIMA/04_conexoes.txt" || echo "Porta 4444 NAO encontrada na coleta $ULTIMA"
```

📌 Na segunda coleta a porta **4444 sumiu**: a evidência volátil **se perdeu**. Só existe na primeira coleta.

## ❓ Perguntas
1. Em que ordem o script coletou os dados? Por que processos e conexões vêm antes do disco?
2. Por que o log registra o horário em **UTC** e também o horário local?
3. Que evidência do incidente existia **só** na primeira coleta?
4. A RFC 3227 diz para não confiar nos programas do sistema comprometido. Como o perito resolve isso na prática?
5. O arquivo `/tmp/.sessao_4471` começa com ponto. O que isso significa no Linux?
