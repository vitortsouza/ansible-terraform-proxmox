# Ansible Proxmox — Updates, Snapshots e Provisionamento

Conjunto de projetos Ansible para aplicar atualizações em VMs Linux, nodes Proxmox e VMs Windows, sempre criando um snapshot prévio no Proxmox. Também inclui um projeto de laboratório para testes e um exemplo de provisionamento de VM com Terraform.

> **Dados fictícios:** todos os nomes, IPs, VMIDs, tokens e credenciais deste repositório são exemplos. Os IPs usam a faixa de documentação `192.0.2.0/24` (RFC 5737). Substitua pelos dados do seu ambiente antes de executar.

---

## O que o projeto faz

- Aplica atualizações de segurança ou atualizações completas em VMs Linux (Debian/Ubuntu e RHEL-like).
- Cria um snapshot da VM no Proxmox antes de qualquer atualização.
- Aborta a execução caso o snapshot falhe.
- Atualiza nodes Proxmox (Debian) um por vez, com reboot opcional/controlado.
- Aplica atualizações de segurança e atualizações completas em VMs Windows via WinRM.
- Remove snapshots automáticos criados pelo próprio Ansible.
- Provisiona uma VM Ubuntu com cloud-init usando Terraform e o provider `bpg/proxmox`.

---

## Estrutura do repositório

```text
.
├── ansible-proxmox-hml/            # VMs de homologação (Linux)
│   ├── ansible.cfg
│   ├── inventory/
│   │   ├── hosts.yml
│   │   └── group_vars/hml.yml
│   └── playbooks/
│       ├── hml-full-updates.yml
│       ├── hml-security-updates.yml
│       ├── hml-cleanup-security-snapshots.yml
│       └── tasks/remove_snapshot_vm.yml
├── ansible-proxmox-prod/           # VMs de produção (Linux)
│   ├── ansible.cfg
│   ├── inventory/
│   │   ├── hosts.yml
│   │   └── group_vars/prod.yml
│   └── playbooks/
│       ├── prod-full-updates.yml
│       ├── prod-security-updates.yml
│       ├── prod-cleanup-security-snapshots.yml
│       └── tasks/remove_snapshot_vm.yml
├── ansible-proxmox-nodes/          # Nodes físicos do cluster Proxmox
│   ├── ansible.cfg
│   ├── inventory/
│   │   ├── hosts.yml
│   │   └── group_vars/proxmox_nodes.yml
│   └── playbooks/
│       ├── proxmox-full-updates-reboot.yml
│       └── proxmox-security-updates.yml
├── ansible-proxmox-windows-security/  # VMs Windows
│   ├── ansible.cfg
│   ├── inventory/
│   │   ├── hosts.yml
│   │   └── group_vars/windows_vms.yml
│   ├── playbooks/
│   │   ├── windows-full-updates.yml
│   │   ├── windows-security-updates.yml
│   │   └── remove-windows-security-snapshots.yml
│   └── snapshots-created/          # Registro local dos snapshots criados
├── ansible-proxmox-test/           # Laboratório / testes de conectividade
│   ├── ansible.cfg
│   ├── inventory/
│   │   ├── hosts.yml
│   │   └── pve.proxmox.yml.example
│   └── playbooks/
│       ├── ping.yml
│       └── ubuntu-security.yml
├── terraform-proxmox/              # Provisionamento de VM com Terraform
├── requirements.yml
└── .gitignore
```

Cada pasta é um projeto Ansible independente, com seu próprio `ansible.cfg`. Execute os comandos **de dentro da pasta do projeto**.

---

## Pré-requisitos

- Ansible Core 2.15 ou superior no host de controle.
- Acesso SSH às VMs/nodes com usuário `ansible` e `sudo` sem senha.
- Acesso à API do Proxmox (porta 8006) a partir do host de controle.
- Collections:
  - `community.proxmox`
  - `ansible.windows` (somente para o projeto Windows)
- Para Windows: WinRM habilitado nas VMs e `pywinrm` instalado no controlador.
- Terraform 1.3+ (somente para o projeto Terraform).

### Instalação das collections

```bash
ansible-galaxy collection install -r requirements.yml
```

Instale as dependências Python usadas pelos módulos:

```bash
pip install proxmoxer requests
```

Para Windows, instale também o cliente WinRM do Python:

```bash
pip install pywinrm
```

---

## Configuração

### 1. Usuário e chave SSH

Os inventários usam o usuário `ansible` e a chave `~/.ssh/id_ed25519` como exemplo. Ajuste `ansible_user` e `ansible_ssh_private_key_file` nos arquivos `inventory/hosts.yml` de cada projeto.

O usuário precisa de `sudo` sem senha. Exemplo para Debian/Ubuntu:

```bash
adduser --disabled-password --gecos "" ansible
echo 'ansible ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/ansible
sudo chmod 440 /etc/sudoers.d/ansible
sudo visudo -c
```

### 2. Token da API do Proxmox

Crie um token em **Datacenter > Permissions > API Tokens** com permissões suficientes para ler VMs e gerenciar snapshots.

O segredo do token **não fica no repositório**. Ele é lido da variável de ambiente `PROXMOX_API_TOKEN_SECRET`:

```bash
export PROXMOX_API_TOKEN_SECRET='00000000-0000-0000-0000-000000000000'
```

Os demais dados de conexão ficam em `inventory/group_vars/*.yml`:

```yaml
proxmox_api_host: "pve-node01.example.com"
proxmox_api_user: "ansible@pve"
proxmox_api_token_id: "ansible"
proxmox_api_token_secret: "{{ lookup('env', 'PROXMOX_API_TOKEN_SECRET') }}"
proxmox_validate_certs: false
```

> Em produção, habilite a validação TLS (`proxmox_validate_certs: true`) e use um certificado confiável no Proxmox.

### 3. Credenciais das VMs Windows

A senha do usuário Ansible do Windows também é lida do ambiente:

```bash
export WINDOWS_ANSIBLE_PASSWORD='SuaSenhaForte'
```

O inventário usa WinRM sobre HTTP/NTLM na porta 5985, conforme exemplo. Ajuste `ansible_user`, `ansible_host`, `proxmox_node` e `vmid` em `ansible-proxmox-windows-security/inventory/hosts.yml`.

### 4. Inventário dinâmico do Proxmox (opcional)

O projeto de testes inclui `inventory/pve.proxmox.yml.example`. Copie para `pve.proxmox.yml` e preencha o token:

```bash
cp ansible-proxmox-test/inventory/pve.proxmox.yml.example \
   ansible-proxmox-test/inventory/pve.proxmox.yml
```

O arquivo real está no `.gitignore` e não deve ser versionado.

---

## Como usar

### VMs Linux de homologação (HML)

```bash
cd ansible-proxmox-hml

# Validar conectividade
ansible hml -m ping

# Aplicar somente atualizações de segurança (cria snapshot antes)
ansible-playbook playbooks/hml-security-updates.yml

# Aplicar todas as atualizações (cria snapshot e reinicia se necessário)
ansible-playbook playbooks/hml-full-updates.yml
```

### VMs Linux de produção (PROD)

```bash
cd ansible-proxmox-prod

ansible prd-tools01 -m ping

# Atualizações de segurança (não reinicia automaticamente)
ansible-playbook playbooks/prod-security-updates.yml

# Atualizações completas (reinicia se necessário)
ansible-playbook playbooks/prod-full-updates.yml
```

### Nodes Proxmox

```bash
cd ansible-proxmox-nodes

ansible proxmox_nodes -m ping

# Atualizações de segurança; reboot somente se perform_reboot=true
ansible-playbook playbooks/proxmox-security-updates.yml

# Atualização completa com reboot automático quando necessário
ansible-playbook playbooks/proxmox-full-updates-reboot.yml

# Habilitar reboot no playbook de segurança
ansible-playbook playbooks/proxmox-security-updates.yml -e perform_reboot=true
```

Os playbooks de nodes usam `serial: 1`, atualizando um node por vez.

### VMs Windows

```bash
cd ansible-proxmox-windows-security

# Testar WinRM
ansible windows_vms -m ansible.windows.win_ping

# Atualizações de segurança (não reinicia automaticamente)
ansible-playbook playbooks/windows-security-updates.yml

# Atualizações completas, incluindo winget, e reboot quando necessário
ansible-playbook playbooks/windows-full-updates.yml
```

Os playbooks Windows registram o nome do snapshot criado em `snapshots-created/<host>.snapshot`.

### Laboratório / testes

```bash
cd ansible-proxmox-test

ansible test_vms -m ping
ansible-playbook playbooks/ping.yml
ansible-playbook playbooks/ubuntu-security.yml
```

### Limpeza de snapshots

Os playbooks de limpeza removem apenas snapshots com os prefixos criados pelo projeto:

- Linux: `pre-sec-update-*` e `pre-full-update-*`
- Windows: o snapshot exato registrado em `snapshots-created/<host>.snapshot`

```bash
cd ansible-proxmox-hml
ansible-playbook playbooks/hml-cleanup-security-snapshots.yml

cd ../ansible-proxmox-prod
ansible-playbook playbooks/prod-cleanup-security-snapshots.yml

cd ../ansible-proxmox-windows-security
ansible-playbook playbooks/remove-windows-security-snapshots.yml
```

Revise a lista de snapshots candidatos exibida pelo playbook antes de confirmar a remoção em produção.

---

## Terraform

O projeto `terraform-proxmox` cria uma VM Ubuntu com cloud-init usando o provider `bpg/proxmox`.

```bash
cd terraform-proxmox

export PROXMOX_VE_API_TOKEN='ansible@pve!ansible=00000000-0000-0000-0000-000000000000'
# Opcional: copie e ajuste as variáveis locais
cp terraform.tfvars.example terraform.tfvars

terraform init
terraform plan
terraform apply
```

Para destruir a VM criada:

```bash
terraform destroy
```

O arquivo de estado (`terraform.tfstate`) contém dados sensíveis e está no `.gitignore`. Para uso em equipe/produção, configure um backend remoto.

---

## Segurança

- Nunca versione tokens, senhas, chaves privadas ou arquivos de estado.
- O `.gitignore` já exclui `.ssh/`, `*.tfstate`, `.terraform/`, `terraform.tfvars`, `*.docx` e o inventário real do Proxmox.
- Prefira variáveis de ambiente ou `ansible-vault` para segredos.
- Use tokens do Proxmox com o menor privilégio possível.
- Mantenha `validate_certs: true` em produção.
- Revise os dados fictícios antes de executar em um ambiente real.
- Os playbooks de atualização criam snapshots, mas snapshots não substituem backups.

### Alternativa com Ansible Vault

Se preferir não usar variáveis de ambiente, crie um arquivo criptografado e referencie os segredos:

```bash
ansible-vault create inventory/group_vars/vault.yml
```

```yaml
vault_proxmox_api_token_secret: "00000000-0000-0000-0000-000000000000"
vault_windows_ansible_password: "SuaSenhaForte"
```

Depois altere as variáveis para usar `vault_proxmox_api_token_secret` e execute com `--ask-vault-pass`. Mantenha o arquivo de vault fora do Git ou versionado apenas criptografado.

---

## Personalização

- **Inventário:** edite `inventory/hosts.yml` de cada projeto.
- **VMIDs:** edite `inventory/group_vars/hml.yml` ou `prod.yml`.
- **API Proxmox:** host, usuário e token em `inventory/group_vars/*.yml`.
- **Nodes Proxmox:** usuário, chave e comportamento de reboot em `inventory/group_vars/proxmox_nodes.yml`.
- **Windows:** credenciais e VMIDs no inventário; categorias de update em `inventory/group_vars/windows_vms.yml`.
- **Terraform:** ajuste `terraform.tfvars` ou as variáveis em `variables.tf`.

---

## Solução de problemas

- **Erro de autenticação na API:** confirme `PROXMOX_API_TOKEN_SECRET` e se o token tem permissão nos recursos alvo.
- **Falha de SSH:** valide a chave, o usuário `ansible` e o `sudo` sem senha.
- **WinRM indisponível:** confirme porta 5985, firewall, NTLM e se o serviço WinRM está habilitado.
- **Snapshot não encontrado na limpeza:** o playbook valida o VMID em `/cluster/resources`; confirme se a VM está no cluster e se o tipo é `qemu` ou `lxc`.
- **Reboot não ocorre:** no projeto de nodes, o playbook de segurança só reinicia com `-e perform_reboot=true`.
- **Terraform não encontra a chave:** o caminho é expandido com `pathexpand()`; ajuste `pm_ssh_private_key_path` e `ssh_key_path`.
