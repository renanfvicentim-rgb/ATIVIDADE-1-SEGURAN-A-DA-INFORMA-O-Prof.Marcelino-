# Atividade 01 – Planejamento e execução da auditoria: auditoria de controles

> **Professor Esp. Marcelino Dias da Silva Junior** · UNINOVE · Disciplina: **Auditoria Forense de Sistemas Digitais**
> **Aula relacionada:** Planejamento e execução da auditoria (reforça: Introdução à auditoria, Relatórios preliminares)

## 🎯 Objetivo
Executar uma auditoria simples: comparar a configuração de um servidor com **critérios** definidos no planejamento e registrar cada **evidência** num papel de trabalho.

## 📚 Conceito em 1 minuto
- **Planejamento:** antes de começar, a auditoria define **objetivo, escopo e critérios**.
- **Execução:** o auditor coleta **evidências** que mostram se cada critério foi cumprido.
- **Não conformidade (NC):** critério não atendido, descrita de forma **clara, firme e objetiva** (fato, critério e efeito).

**Escopo desta auditoria:** servidor **FIN-SRV01** (setor financeiro), usando uma **cópia** das configurações.

| Critério | Regra (política da empresa) |
|---|---|
| C1 | Somente a conta `root` pode ter UID 0 (privilégio máximo) |
| C2 | Nenhuma conta pode ficar sem senha |
| C3 | Arquivos do financeiro não podem ter permissão de escrita para "outros" |
| C4 | Contas de funcionários desligados devem ser removidas |

## 🧪 Passo a passo

```bash
cd /workspaces/*/labs/01-auditoria-de-controles
bash preparar.sh
tree saida/servidor
```

**C1: contas com UID 0.** O 3º campo do `passwd` é o UID:

```bash
awk -F: '$3 == 0 {print $1, "-> UID", $3}' saida/servidor/etc/passwd
```

**C2: contas sem senha.** No `shadow`, o 2º campo vazio significa conta sem senha:

```bash
awk -F: '$2 == "" {print "SEM SENHA:", $1}' saida/servidor/etc/shadow
```

**C3: arquivos com escrita para "outros".**

```bash
ls -l saida/servidor/financeiro/
find saida/servidor/financeiro -type f -perm -o+w
```

**C4: contas de funcionários desligados.** Leia a descrição (5º campo):

```bash
cut -d: -f1,5 saida/servidor/etc/passwd
grep -i "desligad" saida/servidor/etc/passwd
```

**Guarde as evidências com hash**, para que ninguém possa dizer que foram alteradas depois:

```bash
{ echo "Auditoria FIN-SRV01 - $(date -u '+%Y-%m-%d %H:%M UTC') - auditor: $(whoami)"
  awk -F: '$3 == 0' saida/servidor/etc/passwd
  awk -F: '$2 == ""' saida/servidor/etc/shadow
  find saida/servidor/financeiro -type f -perm -o+w
  grep -i "desligad" saida/servidor/etc/passwd
} > saida/evidencias_auditoria.txt
sha256sum saida/evidencias_auditoria.txt | tee saida/evidencias_auditoria.sha256
```

## 📝 Papel de trabalho (preencha)

| Critério | Evidência (comando + resultado) | Conforme? | NC |
|---|---|---|---|
| C1 | | | |
| C2 | | | |
| C3 | | | |
| C4 | | | |

## ❓ Perguntas
1. Qual conta viola dois critérios ao mesmo tempo? Qual o risco?
2. Escreva a **NC-01** de forma clara, firme e objetiva (fato, critério e efeito).
3. Por que a auditoria foi feita numa **cópia** das configurações, e não no servidor em produção?
4. Qual recomendação você faria para cada não conformidade?
