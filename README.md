# Trabalho prático Unidade 1 Docker (Felipe Barbosa Hollerbach)

Este repositório tem a infraestrutura em Docker Compose pra rodar o projeto **Guess Game** (código fonte original em https://github.com/fams/guess_game). A arquitetura engloba um frontend em React servido via NGINX, um backend em Python (Flask) e um banco de dados Postgres.

### 1. Arquitetura
- **Backend (Python/Flask):** Construído a partir de `backend.Dockerfile`. Usa a imagem base `python:3.11-slim` por ser leve e segura. O contêiner roda a aplicação Flask e conecta no banco de dados Postgres. A aplicação é dimensionada horizontalmente (`replicas: 2` no compose) pra demonstrar balanceamento de carga.
- **Frontend & Proxy Reverso (NGINX):** Construído a partir de `frontend.Dockerfile`. Usa uma imagem `node:18-alpine` pra o build do React e `nginx:alpine` pra servir o app. O NGINX serve o conteúdo estático do React e atua como proxy reverso, interceptando chamadas da API (rotas `/api/`) e encaminhando elas aos contêineres do backend de forma segura.
- **Banco de Dados (Postgres):** Usa a imagem `postgres:15-alpine` pra garantir durabilidade e armazenamento seguro do estado do jogo (game IDs, senhas, tentativas).

### 2. Volumes
- **Persistência de Dados (`postgres_data`):** Um volume nomeado gerenciado pelo Docker foi configurado no `docker-compose.yml` e mapeado pra `/var/lib/postgresql/data`. Isso garante que o banco de dados não perca as informações e o estado do jogo caso o contêiner seja recriado.

### 3. Redes e Comunicação
- **Rede Padrão Bridge:** Os contêineres se comunicam através da rede padrão criada pelo Docker Compose. O frontend (via proxy NGINX) e os backends se referenciam pelo nome dos serviços, isolando as portas de comunicação do mundo exterior, expondo apenas a porta `80`.

### 4. Estratégia de Balanceamento de Carga
- O balanceamento de carga é realizado pelo NGINX atuando como proxy reverso. O NGINX está configurado (`nginx.conf`) com um `upstream` apontando pra o nome do serviço `backend`. Graças ao DNS embutido do Docker, esse nome resolve pra os IPs das `2` réplicas em execução de maneira rotativa (round-robin), distribuindo a carga de trabalho de forma automática.

### 5. Resiliência
- Todos os serviços possuem a política `restart: always`. Em caso de falha de algum contêiner ou se o Docker for reiniciado, os serviços subirão automaticamente, garantindo a disponibilidade do sistema.

## Como Instalar e Rodar

### Pré-requisitos
- [Docker](https://docs.docker.com/get-docker/) e [Docker Compose](https://docs.docker.com/compose/install/) instalados.

### Execução

1. Certifique-se de estar na raiz do diretório, onde se encontram os arquivos `docker-compose.yml`, `backend.Dockerfile`, `frontend.Dockerfile`, `nginx.conf` e a pasta `guess_game-main`.

2. Inicie os serviços construindo as imagens em background:
   ```bash
   docker-compose up --build -d
   ```

3. **URL de Acesso:** Após os contêineres estarem em execução, acesse a aplicação localmente pelo navegador na URL:
   👉 **http://localhost**

## Como Atualizar Componentes e Serviços

A separação de cada serviço em seu próprio contêiner simplifica o processo de atualização:

- **Atualizar o Backend ou Frontend:** Se o código na pasta `guess_game-main` for alterado, você pode aplicar a atualização executando:
  ```bash
  docker-compose up --build -d backend
  # ou
  docker-compose up --build -d frontend
  ```
  O Docker construirá a nova imagem com o código novo, e fará a substituição rápida, reiniciando o respectivo contêiner, mantendo o banco de dados e os outros serviços intactos.
  
- **Atualizar Versões das Ferramentas (Node, Python, Postgres):** Basta modificar as tags das imagens base nos arquivos `backend.Dockerfile`, `frontend.Dockerfile` ou diretamente no `docker-compose.yml` (pra o Postgres) e executar o `docker-compose up --build -d`. O Docker baixará a nova imagem e provisionará o novo ambiente instantaneamente.

- **Escalonar a Capacidade:** pra aumentar a capacidade do sistema em suportar acessos concorrentes, edite o campo `replicas: 2` do backend no `docker-compose.yml` pra um número maior e rode o `docker-compose up -d`.

## Estrutura do Projeto na Raiz

- `/guess_game-main`: O repositório original completo do projeto **intacto**.
- `docker-compose.yml`: Orquestração de todos os recursos Docker.
- `backend.Dockerfile`: Instruções pra criar a imagem do Flask utilizando os arquivos de dentro de `/guess_game-main`.
- `frontend.Dockerfile`: Instruções de multi-stage build do React copiando de `/guess_game-main/frontend` e injetando o NGINX.
- `nginx.conf`: Configuração base de roteamento do frontend e balanceamento de carga pra a API.
- `README.md`: Este documento contendo especificações e instruções da arquitetura atual.
