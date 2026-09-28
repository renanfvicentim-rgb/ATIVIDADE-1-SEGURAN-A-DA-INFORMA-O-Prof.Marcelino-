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
| C1 | `awk -F: '$3 == 0 {print $1, "-> UID", $3}' saida/servidor/etc/passwd` deve retornar somente `root -> UID 0`. Os dados de evidência não estão disponíveis neste checkout. | A confirmar | NC-01 se houver conta não-root com UID 0 |
| C2 | `awk -F: '$2 == "" {print "SEM SENHA:", $1}' saida/servidor/etc/shadow` não deve retornar nenhuma conta. Os dados de evidência não estão disponíveis neste checkout. | A confirmar | NC-02 se houver conta sem senha |
| C3 | `find saida/servidor/financeiro -type f -perm -o+w` não deve retornar arquivos. Os dados de evidência não estão disponíveis neste checkout. | A confirmar | NC-03 se houver arquivo com escrita para outros |
| C4 | `grep -i "desligad" saida/servidor/etc/passwd` não deve retornar contas de funcionários desligados. Os dados de evidência não estão disponíveis neste checkout. | A confirmar | NC-04 se houver conta desligada |

## ❓ Perguntas
1. A conta é a conta não-`root` que aparecer simultaneamente no resultado do C1 (UID 0) e do C2 (sem senha). O risco é a obtenção de privilégio máximo sem autenticação, permitindo alteração ou exclusão de dados, instalação de código malicioso e comprometimento completo do servidor.
2. **NC-01:** Foi identificada uma conta diferente de `root` com UID 0. A política determina que somente `root` pode possuir UID 0. Essa configuração concede privilégio máximo à conta e aumenta o risco de acesso administrativo indevido e comprometimento integral do servidor.
3. A auditoria foi realizada em uma cópia para preservar a disponibilidade e a integridade do servidor em produção. Assim, a coleta não altera configurações, não interrompe serviços e permite repetir os testes, mantendo as evidências para análise e rastreabilidade.
4. Recomendações: para C1, remover o UID 0 da conta não autorizada e revisar os privilégios; para C2, definir uma senha forte ou bloquear/remover a conta conforme a necessidade; para C3, retirar a permissão de escrita para `outros` e aplicar o princípio do menor privilégio; para C4, remover ou bloquear imediatamente as contas de funcionários desligados e revisar periodicamente as contas ativas. Após as correções, repetir os testes e registrar novas evidências com hash.
