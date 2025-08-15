# Projeto Wordpress DevOpsSec 2025 | Wordpress em alta disponibilidade na AWS 

## Objetivo:
Com o crescimento contínuo do uso de aplicações web, garantir alta disponibilidade, escalabilidade e resiliência se tornou crucial em qualquer arquitetura moderna, ou seja, esses fatores somados asseguram que os serviços permaneçam acessíveis, suportem altos picos de demanda e se recuperem rapidamente de falhas sem comprometer a experiência do usuário. Por isso, este projeto visa implantar a plataforma Wordpress na nuvem da AWS (Amazon Web Services) de forma escalável e tolerante a falhas, utilizando os principais serviços gerenciados da AWS para garantir o máximo de desempenho, disponibilidade e resiliência.


## Diagrama do sistema:
<img width="1438" height="634" alt="image" src="https://github.com/user-attachments/assets/395a69c6-0f52-4e62-ba60-39821a3535e3" />


## Tecnologias Utilizadas

* **Plataforma de Nuvem:** Amazon Web Services (AWS)
* **Rede e Segurança:**
    * Amazon VPC (Virtual Private Cloud)
    * Subnets (públicas e privadas)
    * Internet Gateway (IGW) e NAT Gateway
    * Security Groups (SGs)
* **Computação e Orquestração:**
    * Amazon EC2 (Elastic Compute Cloud)
    * Ubuntu
    * Application Load Balancer (ALB)
    * Auto Scaling Group (ASG)
    * Launch Templates
* **Banco de Dados e Armazenamento:**
    * Amazon RDS (Relational Database Service) com MySQL 
    * Amazon EFS (Elastic File System)
* **Contêineres e Aplicação:**
    * Docker
    * Docker Compose
    * WordPress com PHP
    * phpMyAdmin

## Pré-requisitos:
Antes de iniciar a replicação deste projeto, garanta que você tenha todos os seguintes pré-requisitos atendidos:

* **Conta na AWS:** Uma conta na Amazon Web Services com permissões administrativas ou suficientes para criar os recursos listados no projeto como (VPC, EC2, RDS, EFS, etc.).
* **Git:** O [Git](https://git-scm.com/) instalado em sua máquina local ou na nuvem para clonar este repositório.
* **Docker e Docker Compose:** Ter o [Docker Desktop](https://www.docker.com/products/docker-desktop/) ou o motor do Docker e o Docker Compose instalados localmente, caso deseje testar ou modificar o arquivo `docker-compose.yml`.

Caso todos esses requisitos estejam atendidos, siga as seguintes etapas de execução do projeto.

## Etapa 1: Criação e personalização da VPC
A base de toda a arquitetura desta aplicação está na AWS VPC (Virtual Private Cloud). A VPC atua como um perímetro virtual, mantendo o sistema privado e totalmente isolado da internet pública. Essa separação é a primeira e mais importante camada de segurança para que os recursos que serão implantados em seu interior estejam completamente seguros e isolados. Para este projeto, foram consideradas as seguintes configurações da VPC.

- **Endereçamento IP da VPC:** Foi escolhido o seguinte bloco IP `10.0.0.0/16`, o mesmo fornece mais de 65.000 endereços de IPs. Isso nos dá um espaço extremamente amplo para escalar a aplicação no futuro, adicionando novos serviços sem o risco de esgotar os endereços.

- **Múltiplas Zonas de Disponibilidade (AZs):** A VPC foi alocada em duas zonas de disponibilidade distintas, o que garante alta disponibilidade em caso de falhas. Uma AZ é composta por um ou mais data centers discretos. Caso ocorra uma falha na zona us-east-2a, por exemplo, a us-east-2b continuará operando normalmente, garantindo que a aplicação permaneça no ar e acessível aos usuários.

- **Segmentação em 6 subnets:** Para garantir a segurança em camadas (princípio de "defesa em profundidade"), a VPC foi divida em 6 sub-redes, sendo elas:

  * **2 Subnets Públicas:** Uma em cada AZ. Elas servem como a "zona desmilitarizada" (DMZ), abrigando recursos que precisam de acesso direto à internet, como o Application Load Balancer.
    
  * **2 Subnets Privadas para Aplicação (App):** Uma em cada AZ. Aqui residem nossas instâncias EC2 com o WordPress. As mesmas não são acessíveis diretamente pela internet, sendo protegidas pelo Application Load Balancer.
  
  * **2 Subnets Privadas para Dados (Data):** Uma em cada AZ. Esta é a camada mais segura, nela ficarão hospedados o banco de dados RDS e os pontos de acesso do EFS (EFS Mount Target), garantindo que apenas as EC2 possam se comunicar com eles.

- **Conectividade e Roteamento:**
  * Um **Internet Gateway (IGW)** foi anexado à VPC para funcionar como a porta de entrada e saída para a internet.
 
  * Um **NAT Gateway** foi posicionado nas duas subnets públicas. A sua função é crucial, ele permite que as instâncias nas sub-redes privadas (como os servidores WordPress) acessem a internet para baixar atualizações ou pacotes, funcionando como um escudo de segurança para o tráfego de saída.

  * **Tabelas de Rotas** foram configuradas para controlar o fluxo de tráfego.

## Etapa 1.1: Passo a passo para criação da VPC na AWS
Para facilitar a criação de VPCs, a AWS possui uma maneira mais rápida e eficiente para subir uma VPC na mesma, que é através do assistente "VPC e muito mais". Siga os passos a seguir:
- Na barra de pesquisa do console, pesquise por VPC.

<img width="919" height="187" alt="image" src="https://github.com/user-attachments/assets/cc3623cf-0fa5-423f-873b-071d9ea7ab8f" />

- No painel da VPC, clique em "Suas VPCs" e, em seguida, em "Criar VPC".
- Selecione a opção **"VPC e muito mais**.
- Adicione as seguintes configurações:

<img width="1912" height="783" alt="image" src="https://github.com/user-attachments/assets/0fab1690-43ce-407a-88f9-5da0e2aa3620" />

* **Nome:** `defina um nome para sua VPC`
* **Bloco CIDR IPv4:** `10.0.0.0/16`

<img width="1912" height="653" alt="image" src="https://github.com/user-attachments/assets/961bdd97-3491-44ae-8717-f2de875c6088" />

* **Número de zonas de disponibilidade (AZs):** `2`

* **Número de sub-redes públicas:** `2` (O assistente irá nomeá-las e distribuir os IPs, exemplo: 10.0.1.0/24, 10.0.2.0/24)

* **Número de sub-redes privadas:** `4` (Estas serão nossas sub-redes de Aplicação (App) onde irão ficar as duas EC2 da aplicação. Exemplo: 10.0.3.0/24, 10.0.4.0/24 e também serão usadas para o Data onde ficará o RDS). Após a criação das subnets privadas, o assistente pode acabar deixando o nome delas bem genérico, para seguir a organização da aplicação, é uma boa escolha deixar os nomes `Private subnet(App)1`, `Private subnet(App)2`, `Private subnet(Data)1` e `Private subnet (Data)2` como mostra no diagrama do projeto.

* O **internet Gateway** será gerado automaticamente pelo assistente, logo não é preciso adiciona-lo manualmente.

* **Endpoints da VPC:** Mantenha como "Nenhum".

* Agora clique em **Criar VPC.**

## Etapa 1.2: NAT Gateway (A saída segura para a Internet)
As instâncias EC2 nas sub-redes privadas (App e Data) estão seguras, pois não podem ser acessadas diretamente da internet já que não recebem IPs. No entanto, elas precisam de uma forma de se conectar com as conexões de internet para tarefas essenciais, como baixar as atualizações de pacotes do Ubuntu (`apt update`) ou baixar as imagens Docker.

É nesse cenário que entra o **NAT (Network Address Translation) Gateway**. Ele atua como uma "ponte" segura, posicionado nas sub-redes públicas. O fluxo de tráfego funciona da seguinte forma:

-  Uma instância EC2 na sub-rede privada envia uma solicitação para a internet.
-  A Tabela de Rotas daquela sub-rede privada direciona essa solicitação para o NAT Gateway.
-  O NAT Gateway, que possui um endereço de IP público (IP Elástico), encaminha a solicitação para a o Internet Gateway, que possui acesso à internet, em nome da instância privada.
-  A resposta da internet volta para o NAT Gateway, que a repassa para a instância privada original.

## Etapa 1.3: Criação do NAT Gateway

**Crie os IPs Públicos (Elastic IPs):**
- O NAT Gateway precisa de um endereço de IP público fixo.
- No console da VPC, no menu à esquerda, clique em **"IPs Elásticos"**.
- Clique em **"Alocar endereço IP elástico"** e depois em **"Alocar"**.

<img width="1892" height="804" alt="image" src="https://github.com/user-attachments/assets/c7daba9a-ed02-492c-a305-22eb3a5066fb" />

- Repita mais uma vez o processo para ter um total de dois IPs Elásticos (um para cada NAT Gateway).

**Crie os NAT Gateways:**
Foram criados dois NAT Gateways, um em cada Zona de Disponibilidade, para garantir a **alta disponibilidade**. Se uma zona falhar, as instâncias na outra zona ainda ainda possuirão uma saída para a internet.
- Agora, no menu à esquerda, clique em **"Gateways NAT"** e em **"Criar gateway NAT"**.

<img width="1892" height="693" alt="image" src="https://github.com/user-attachments/assets/5b65571f-8429-4099-b850-e06add6ba208" />

- Digite um nome para seu NAT Gateway
- Sub-rede: Selecione a sua primeira sub-rede pública (exemplo: public-subnet-a).
- **Tipo de conectividade:** Público.
- **ID de alocação do IP elástico:** Selecione o primeiro IP Elástico que você criou.
- Repita o processo para criar o nat-gateway-b, mas desta vez, associe-o à segunda sub-rede publica (public-subnet-b) e ao segundo IP Elástico.

## Etapa 1.4: Configure as Tabelas de Rotas Privadas 
As Tabelas de Rotas (Route Tables) são um conjunto de regras que atuam como o "GPS" da VPC, determinando para onde o tráfego de rede originado das sub-redes é direcionado. Para essa arquitetura, criei um esquema de roteamento resiliente e seguro com três tabelas principais:

- **wordpress-rtb-public:** Esta tabela deve estar associada às duas sub-redes públicas. Verifique na aba "Rotas" se a rota de destino 0.0.0.0/0 aponta para o **Internet Gateway (IGW)**, como mostra a imagem.
  
<img width="1585" height="498" alt="image" src="https://github.com/user-attachments/assets/674f8a3a-8930-4904-b65c-c49afd687a18" />

- wordpress-rtb-private1-us-east-2a: Esta tabela atenderá as sub-redes privadas da Zona A.
  * Selecione uma tabela de rotas que estejam na zona A.
  * Vá em **"Rotas"** e clique em **editar rotas**.
  
  <img width="1917" height="437" alt="image" src="https://github.com/user-attachments/assets/fbf602dd-9656-4765-81a0-c45c4c934f6f" />

* Clique em **"adicionar rotas"**.
* **Destino:** `0.0.0.0/0`
* **Alvo: Gateway NAT**
* Selecione seu NAT Gateway A
* Clique em **Salvar configurações**

<img width="1630" height="493" alt="image" src="https://github.com/user-attachments/assets/ea7276d4-7509-4f41-a46f-5b7c468f4e04" />

- Vá em **"Associações de sub-rede"**.
- Clique em **"Editar associações de sub-rede**

<img width="1895" height="674" alt="image" src="https://github.com/user-attachments/assets/5dc1bcec-fbec-4644-9e6a-9bb90c841330" />

 - Vá em **"Associações de sub-rede"** e associe as seguintes sub-redes:
    - `wordpress-subnet-private(app)1-us-east-2a`
    - `wordpress-subnet-private(data)1-us-east-2a`
 - Clique em **"Salvar associações"**.

wordpress-rtb-private2-us-east-2b: Esta tabela atenderá as sub-redes privadas da Zona B.
* Clique novamente em **"adicionar rotas"**.
* **Destino:** `0.0.0.0/0`
* **Alvo: Gateway NAT**
* Selecione seu NAT Gateway B
* Clique em **Salvar configurações**
  - Vá em **"Associações de sub-rede"** e associe as seguintes sub-redes:
    - `wordpress-subnet-private(app)2-us-east-2b`
    - `wordpress-subnet-private(data)2-us-east-2b`
* Clique **"Salvar associações"**.


### Mapa dos recursos.

<img width="1640" height="530" alt="image" src="https://github.com/user-attachments/assets/5eed27a5-4a1a-464a-b20b-f036ea881e42" />

Ao final desse processo, o mapa de recursos deve estar parecido com esse mostrado na imagem.
  

## Etapa 2: Security Groups
Os Security Groups (SGs) atuam como firewalls virtuais para nossos recursos na nuvem. Eles são o principal mecanismo de controle de tráfego, funcionando como porteiros que decidem exatamente quem pode entrar e em qual porta. Para este projeto, criei uma "cadeia de confiança" entre os SGs, garantindo o princípio do menor privilégio, onde cada camada só confia na camada imediatamente anterior a ela.

## Etapa 2.1: Criação do Security group Application Load Balancer
Este primeiro Security Group irá atuar como uma **porta de entrada principal** da aplicação, controlando todo o tráfego que chega da internet ao **Application Load Balancer (ALB)**. Ele define as regras que determinam quais conexões externas podem acessar a camada de balanceamento, garantindo segurança e filtragem antes que os dados da internet sejam encaminhado para as instâncias EC2.

- Na barra de pesquisa do console, digite por **"EC2"**. 

- No painel da EC2 vá em **"Rede e segurança"** depois em **"Security groups"**.

- Depois clique em **"Criar Grupo de Segurança"**

<img width="1883" height="583" alt="image" src="https://github.com/user-attachments/assets/def89828-e8b7-40d6-bc3a-d967123f8a06" />


- Insira o nome do grupo de segurança.

- Adicione alguma descrição para não se perder.

- Selecione a VPC que você criou.

<img width="1893" height="603" alt="image" src="https://github.com/user-attachments/assets/af4fdc39-83d0-42fa-a02d-bf25310ab176" />

Adicione as seguintes regras de entrada:
**Regras de entrada:**
  * **Tipo:** `HTTP`.
  * **Protocolo:** `TCP`.
  * **Intervalos de portas:** `80`.
  * **Origem:** `Qualquer lugar-IPv4 (0.0.0.0/0)`.
 
justificativa: A origem 0.0.0.0/0 é utilizada para que o Application Load Balancer seja o único ponto de acesso público do WordPress e precisa aceitar conexões de qualquer usuário da internet.

- **Regras de saída:**
Você pode manter a regra padrão (Todo o tráfego para 0.0.0.0/0). O Load Balancer precisa dessa regra para encaminhar o tráfego para as instâncias EC2.

- Clique em **"Criar grupo de segurança"**.

## Etapa 2.2: Criação do Security Group do Bastion Host
O Security Group do Bastion atua como uma porta de entrada fortificada para o acesso administrativo da rede privada. Diferente do ALB, que é público, a função deste SG é ser extremamente restritivo. Ele define as regras que permitem conexões `SSH` (Secure Shell), garantindo que apenas administradores autorizados, de endereços de IP conhecidos, possam acessar o Bastion Host. Este servidor, por sua vez, servirá como um "ponto de pulo" (jump host) seguro para as instâncias EC2 privadas.

- No painel da EC2, vá em **"Rede e segurança"** e depois em **"Grupos de segurança"**.
- Clique em **"Criar Grupo de Segurança"**.

<img width="1883" height="583" alt="image" src="https://github.com/user-attachments/assets/def89828-e8b7-40d6-bc3a-d967123f8a06" />

- Insira o nome do grupo de segurança.

- Adicione alguma descrição para não se perder.

- Selecione a VPC que você criou.

<img width="1892" height="535" alt="image" src="https://github.com/user-attachments/assets/31aed00f-1120-47bc-90d2-3bd5d9d66abf" />

Adicione as seguintes regras de entrada:
- **Regras de entrada:**
    * **Tipo:** `SSH`
    * **Protocolo:** `TCP`
    * **Intervalo de portas:** `22`
    * **Origem:** `Meu IP`
    
**Justificativa:** A origem `Meu IP` é uma medida de segurança crucial e a configuração correta para um Bastion Host. Ela garante que apenas o seu endereço de IP atual possa tentar uma conexão SSH, bloqueando tentativas de acesso de força bruta do resto do mundo e minimizando a superfície de ataque, lembre-se de sempre alterar essa regra caso mude de rede.

- **Regras de saída:**
Você pode manter a regra padrão (Todo o tráfego para `0.0.0.0/0`). Isso permitirá que o Bastion Host inicie as conexões SSH para as instâncias privadas na sua VPC.

- Clique em **"Criar grupo de segurança"**.

## Etapa 2.3: Criação do Security Group EC2
Este Security Group tem o propósito de proteger as instâncias EC2 que rodam os **contêineres Docker com o WordPress.** As regras a seguir foram configuradas para garantir que apenas tráfego autorizado e proveniente de fontes confiáveis chegue até os servidores da aplicação.

- Repita o mesmo processo de criação descrito anteriomente.

**Regras de entradas:**
<img width="1900" height="770" alt="image" src="https://github.com/user-attachments/assets/fb1173e3-530a-4706-a39a-5cd66337da61" />

Aqui foram adicionadas duas regras de entrada:
- 1° Regra:
  
  * **Tipo:** `HTTP`
  * **Intervalos de portas:** `80` 
  * **Origem:** Exclusivamente do Security Group do Application Load Balancer (`alb-security group`).

 Esta regra assegura que todo acesso ao WordPress passe primeiro pelo Load Balancer, impedindo conexões diretas vindas da internet para as instâncias EC2. Dessa forma, aplica-se o princípio do menor privilégio e mantemos a arquitetura em camadas (layered security).

- 2° Regra:

  * **Tipo:** `TCP Personalizado`
  * **Intervalos de portas:** `8080`
  * **Origem:** `Meu IP`
  
 Esta regra permite que o administrador acesse a interface do phpMyAdmin pela porta `8080`. Ao restringir a origem a um IP específico, garantimos que esta ferramenta administrativa não fique exposta à internet pública, uma medida de segurança crucial nesta aplicação.

- 3° Regra:

  * **Tipo:** `SSH`
  * **Intervalo de portas:** `22`
  * **Origem:** Exclusivamente do Security Group do **Bastion Host**.

Esta regra garante que o único caminho para acessar o terminal de uma instância da aplicação é através do Bastion Host. Isso centraliza o acesso administrativo e remove completamente a exposição da porta SSH das instâncias da aplicação, mesmo para IPs conhecidos.

## Etapa 2.4: Criação do Security Group RDS
O Security Group RDS foi configurado para proteger o banco de dados MySQL utilizado pelo WordPress. Seu objetivo é restringir ao máximo seu acesso, permitindo conexões apenas das instâncias EC2 autorizadas.

Vamos novamente criar um novo grupo de segurança, adicionando o nome, selecionando a VPC que foi criada, porém vamos adicionar a seguinte regra de entrada.

<img width="1905" height="631" alt="image" src="https://github.com/user-attachments/assets/d665c394-bb9c-4fb0-9c50-88a36e73ffb6" />

* **Tipo:** `MYSQL/Aurora`

* **Protocolo:** `TCP`

* **Intervalo de portas:** `3306`

* **Origem:** Exclusivamente vindo do security group da EC2.

* As regras de saída serão mantidas padrão

Essa configuração permite que somente as EC2 que executam o WordPress possam se conectar ao banco de dados RDS, impedindo qualquer acesso direto da internet ou de outros serviços não autorizados. Logo após as configurações, clique em "Criar grupo de Segurança.

## Etapa 2.5: Criação do Security Group para o EFS
O Security Group EFS foi criado para proteger o sistema de arquivos compartilhado utilizado pelas instâncias EC2 para armazenar conteúdos persistentes do WordPress. Sua função é garantir que apenas instâncias autorizadas possam montar e acessar os arquivos do EFS.

Criaremos novamente outro grupo de segurança, adicionando o nome, selecionando a VPC já criada e adicionando as seguintes regras de entrada.


<img width="1905" height="504" alt="image" src="https://github.com/user-attachments/assets/6ed92812-c6f3-4cf3-bfad-74940ea06197" />

* **Tipo:** `NFS`

* **Protocolo:** `TCP`

* **Intervalo de portas: `2049`

* Origem: Exclusivamente do Security Group das instâncias EC2.

* As regras de saída serão mantidas como padrão

Essa configuração adicionada permite que apenas as EC2 do projeto acessem os arquivos do EFS e impedem que qualquer outro recurso (interno ou externo) consiga montar ou ler o sistema de arquivos. Logo após adicionar essas configurações, clique em "Criar grupo de segurança.

## Etapa 3: Criação do banco de dados Amazon RDS (Relational Database Service)
Para que dados como posts, usuários e configuração possam persistir na aplicação, precisamos de um banco de dados para que essa possibilidade seja possível, com isso, vamos usar o **Amazon RDS (Relational Database System).** O RDS é um serviço de banco de dados relacional gerenciado, o que significa que a AWS automatiza tarefas complexas e repetitivas, como provisionamento de hardware, instalação de um sistema operacional, aplicação de patches de segurança e backups. Isso nos permite focar no desenvolvimento da aplicação em si, ao invés de gerenciar o banco de dados.

As configurações escolhidas para o RDS foram:
* **Mecanismo (Engine):** Foi escolhido o MySQL Community, versão 8.0.42, ele é um dos sistemas de gerenciamento de banco de dados de código aberto mais populares do mundo e totalmente compatível com os requisitos do WordPress.
  
* **Tipo de Instância:** Para esse projeto bem simples e didático e para reduzir os custos, foi selecionada a instância `db.t3.micro`. Ela faz parte da família de instâncias "burstable", oferecendo um desempenho de linha de base com a capacidade de "burst" (picos de performance) para lidar com cargas de trabalho variáveis, ideal para um site com tráfego de baixo a moderado.
  
* **Posicionamento na Rede:** O banco de dados foi estrategicamente posicionado na camada mais segura da rede: as sub-redes privadas de dados. Essa configuração garante que ele não tenha nenhuma exposição à internet e só possa ser acessado pela nossa camada de aplicação (as instâncias EC2), conforme definido pelas regras do Security Group do RDS.
  
* **Disponibilidade (Multi-AZ):** Visando o controle de custos para este ambiente de aprendizado, a funcionalidade de Multi-AZ foi desativada. Em um ambiente de produção real, ativar o Multi-AZ é uma melhor prática crucial, pois cria uma réplica de standby do banco de dados em outra Zona de Disponibilidade, garantindo a recuperação automática e rápida em caso de falha da instância primária.

## Etapa 3.1: Criação do Grupo de Sub-redes de Banco de Dados (RDS)
O Grupo de Sub-redes de Banco de Dados (DB Subnet Group) é um componente de configuração para o Amazon RDS. Sua função é definir uma coleção de sub-redes (geralmente privadas) dentro de uma VPC onde o Amazon RDS tem permissão para provisionar uma instância de banco de dados. Ao criar este grupo, garantimos que nosso banco de dados seja lançado na camada mais segura da nossa rede, isolado do acesso direto da internet, e com a capacidade de operar em múltiplas Zonas de Disponibilidade para alta resiliência.

No console da AWS, na barra de busca, pesquise por "RDS" e selecione o serviço.

<img width="702" height="114" alt="image" src="https://github.com/user-attachments/assets/2170e0b8-ab15-4933-951e-6746e927a2dd" />

- Na página do RDS vá em **"Grupos de sub-redes"** e depois clique em **"Criar grupo de sub-redes de banco de dados"**.


<img width="1884" height="792" alt="image" src="https://github.com/user-attachments/assets/6bab8dae-ae5e-43ec-b6f1-d9661b7fd56c" />

- **Nome:** Selecione um nome para seu grupo.
- **Descrição:** Digite uma descrição
- **VPC:** Escolha sua VPC já criada.

<img width="1886" height="615" alt="image" src="https://github.com/user-attachments/assets/ebd82499-f009-42b7-92a6-13950c24b961" />

- **Zonas de disponibilidade:** Selecione as zonas `us-east-2a` e `us-east-2b`.
- **Sub-redes:** selecione as subnets privadas que estão em zonas diferentes.
- Clique em **Criar**.


## Etapa 3.2: Passo a passo da criação do RDS
No console da AWS, na barra de busca, pesquise por "RDS" e selecione o serviço.

<img width="702" height="114" alt="image" src="https://github.com/user-attachments/assets/2170e0b8-ab15-4933-951e-6746e927a2dd" />


- Na página do RDS vá em **"Banco de dados"** e depois clique em **"Criar banco de dados"**.


<img width="1887" height="839" alt="image" src="https://github.com/user-attachments/assets/dc84ba08-e8c8-4efe-86a2-fc4bb2f762f9" />

- **Escolher um método de criação de banco de dados**: `Criação Padrão`.
- **Opção de mecanismo:** `MySQL`.
- **Edição:** `MySQL Community`.
- **Versão do mecanismo:** Deixe a versão padrão selecionada pela AWS, que geralmente é a mais recente e estável, ou escolha uma versão específica da série 8.0.x, se necessário.

<img width="1888" height="839" alt="image" src="https://github.com/user-attachments/assets/d2adef93-6617-4855-bbcc-fdf7d2956799" />

- **Modelos:** `Nível gratuito`.
- **Disponibilidade e durabilidade:** `Implantação de instância de banco de dados Single-AZ (1 instância).`

<img width="1895" height="681" alt="image" src="https://github.com/user-attachments/assets/b4510105-724c-4048-9618-3a65b322b296" />

- **Identificador da instância de banco de dados:** Defina um nome para seu banco de dados.
- **Nome do usuário principal:** Defina o admin do seu banco de dados.
- **Gerenciamento de credenciais:** Você pode escolher entre autogerenciada, ou seja, gerar automanticamente uma senha ou pode definir uma própria (lembre de anotar essa senha).

<img width="1884" height="792" alt="image" src="https://github.com/user-attachments/assets/af9102eb-1287-4c2b-babf-819987cb147d" />

-  **Configuração da instância:** escolha o `db.t3.micro`.
-  **Armazenamento:** `SSD de uso geral (gp2)`.
-  **Armazenamento alocado:** `20 GB`.

<img width="1894" height="840" alt="image" src="https://github.com/user-attachments/assets/fed7b6e7-9a66-4e54-98a8-7e3857a007f2" />

- **Recurso de computação:** Selecione `Não se conectar a um recurso de computação do EC2`.
- **Tipo de rede:** `IPv4`.
- **Nuvem privada virtual (VPC):** Selecione sua VPC já criada.
- **Grupo de sub-redes de banco de dados:** Selecione o grupo de subredes criado.
- **Acesso público:** Selecione **Não**.

  <img width="1887" height="665" alt="image" src="https://github.com/user-attachments/assets/6b2c8edb-6944-4eb0-b758-b2394a3f03ae" />

- **Grupo de segurança de VPC (firewall):** Selecione sua VPC existente.
- **Grupos de segurança da VPC existentes:** Selecione seu security group do RDS.
- **Zona de disponibilidade:** `us-east-2a`.

Após clicar em "Criar banco de dados", o provisionamento será iniciado. Aguarde alguns minutos até que o status do banco de dados mude de "Criando" para "Disponível" antes de prosseguir.



## Etapa 4: Criação do Amazon EFS (Elastic File System)
**Amazon EFS (Elastic File System)** é um serviço da AWS que atua como um sistema de arquivos centralizado e compartilhado, semelhante a um “HD de rede” na nuvem da AWS. Ele fornece armazenamento escalável e de alta disponibilidade, permitindo que múltiplas instâncias EC2 acessem os mesmos arquivos simultaneamente. Sua implementação é essencial para garantir a **persistência e consistência dos dados** em arquiteturas com mais de uma instância. Por exemplo, se um usuário fizer upload de uma imagem para a instância **A**, a instância **B** não terá acesso a esse arquivo caso utilize apenas armazenamento local, o que pode gerar falhas e inconsistências na aplicação. Com o EFS, todos os arquivos ficam centralizados, garantindo que qualquer instância conectada tenha acesso imediato às alterações realizadas por outra, eliminando problemas de sincronização e preservando a integridade dos dados.

As seguintes configurações serão usadas no EFS:

**Classe de Armazenamento (Regional):** Utilizei a classe de armazenamento "Regional", que cópia os dados automaticamente em múltiplas Zonas de Disponibilidade. Isso garante que o sistema de arquivos seja tão resiliente e disponível quanto o resto da nossa aplicação, sobrevivendo até mesmo à falha completa de um data center.

**Pontos de Acesso (Mount Targets):** Para permitir que as instâncias na VPC se conectem ao EFS, os Mount Targets são criados automaticamente na criação do EFS. Cada Mount Target é uma "tomada de rede" com um endereço de IP, posicionada estrategicamente em nossas sub-redes privadas onde estão as EC2. Essa configuração garante o acesso seguro e de alta performance a partir da camada de aplicação.

**Segurança de Acesso:** O acesso aos Mount Targets é rigorosamente controlado pelo security group do efs, que só permite conexões na porta 2049 (protocolo NFS) vindas exclusivamente do security group da EC2.

## Etapa 4.1: Passo a passo para criação do EFS na AWS

- No console da AWS, pesquise pelo serviço do EFS.

  <img width="1888" height="809" alt="image" src="https://github.com/user-attachments/assets/7506a7ac-0f90-437b-b4ec-359e0a1cb34c" />
  
- Clique em "Criar sistema de arquivos".

<img width="1013" height="900" alt="image" src="https://github.com/user-attachments/assets/f032493a-315c-48b5-b204-a74f3424e65d" />

- Clique em "Personalizar"

<img width="1895" height="809" alt="image" src="https://github.com/user-attachments/assets/a63c8cd8-e675-499c-8938-c6e670f6c4a9" />

- Escolha um nome para seu EFS
- Tipo do sistema de arquivos: Regional
- Clique em "próximo"

<img width="1846" height="828" alt="image" src="https://github.com/user-attachments/assets/8ef2bf86-7862-4e36-9275-4c90c88c3d8f" />

- Zona de disponibilidade: `us-east-2a`, `us-east-2b`
- ID da sub-rede: `subnet-private-data1`, `subnet-private-data2`
- Grupos de segurança: `security-group efs`
- Clique em **"próximo"**
- Após revisar seu EFS, clique em **"Criar"**

<img width="1911" height="837" alt="image" src="https://github.com/user-attachments/assets/879c3475-b2b0-404a-9c42-ffd2d5fd82b9" />

Após a criação do seu EFS, anote o ID do Sistema de arquivos (ex: fs-0123...) ou o endereço de IP de um dos Mount Targets. Essa informação será útil para o script user-data que irá montar o EFS automaticamente nas instâncias EC2.

## Etapa 5: Automação com Launch Template e User Data
Para que essa arquitetura desse projeto seja completamente escalável e resiliente, precisamos de uma forma de lançar novas instâncias EC2 de forma totalmente automatizda, sem precisar ir manualmente no console. Para que as instâncias da EC2 sejam lançadas automaticamente, o Auto Scaling Group precisa de uma "receita de bolo" para saber exatamente como configurar um novo servidor. Essa receita é composta por duas peças chaves: o Launch Template e o script User Data.

### Etapa 5.1: O Launch Template
O Launch Template funciona como o **"molde"** para nossas instâncias EC2, demonstrando passo a passo de como serão criadas. Ele é um recurso da AWS onde salvamos todas as configurações base de uma instância, garantindo que cada novo servidor criado pelo Auto Scaling seja idêntico e consistente. Logo abaixo estão as informações de como criar o mesmo.

- No painel da EC2, clique em **"Modelos de execução"**.
- Depois clique em **"Criar modelo de execução"**.

<img width="1258" height="610" alt="image" src="https://github.com/user-attachments/assets/77b6f442-a585-41b9-93b1-75c6f5d8f288" />

- Digite um nome para o seu modelo de execução.
- Digite também uma descrição sobre o que ele faz.

<img width="1269" height="815" alt="image" src="https://github.com/user-attachments/assets/9c3f54cc-1bbd-432c-8906-f37021fec855" />

- Selecione a AMI do Ubuntu.
- Tipo de instância: `t2.micro`.

<img width="1265" height="652" alt="image" src="https://github.com/user-attachments/assets/2bd848dd-d292-4837-bdfc-775ef711db43" />

- Par de chaves: Selecione um par de chaves existente ou crie um novo. Ele será **necessário para permitir seu acesso administrativo** à instância via SSH para qualquer depuração.
  
- Configuração de rede:  Deixe o campo 'Sub-rede' vazio, mas em 'Grupos de segurança', **selecione o grupo de segurança da EC2** que criamos anteriormente.
  
- Agora, expanda a seção **"Detalhes avançados"** e role até o final, onde encontraremos o campo para inserir o script de User Data.

### Etapa 5.2: O Script User Data 
Se o Launch Template é o molde, o script `user-data` é o **"robô construtor"** que entra em ação na primeira vez que a instância é ligada. Ele executa uma sequência de passos para transformar uma instância Ubuntu "limpa" em um servidor WordPress totalmente funcional e conteinerizado. O Script do user-data está disponível neste repositório, antes de fazer o upload, lembre-se de **editar as variáveis** no início do script com suas informações (credenciais do RDS, ID do EFS, etc.). O possui placeholders de onde colocar suas credenciais.

O script criado realiza as seguintes tarefas:

1.  **Atualiza o Sistema:** Garante que o Ubuntu esteja com os pacotes mais recentes.
2.  **Instala o Docker e o Docker Compose:** Prepara o ambiente para rodar os contêineres.
3.  **Monta o Sistema de Arquivos (EFS):** Conecta a instância ao EFS para garantir que os arquivos do WordPress sejam persistentes e compartilhados.
4.  **Cria o `docker-compose.yml`:** Gera dinamicamente o arquivo de orquestração dos contêineres, inserindo as credenciais do banco de dados RDS.
5.  **Inicia os Serviços:** Executa o `docker compose up -d` para baixar as imagens e iniciar os contêineres do WordPress e do phpMyAdmin.

<img width="1207" height="480" alt="image" src="https://github.com/user-attachments/assets/af21664a-6102-4865-980e-d201dab654f7" />

- Em dados do usuário, clique em **"Escolher arquivo"** e suba o script.
- E clique em **"Criar modelos de execução"**.

Ao final desses passos, o template será mostrado no painel.
<img width="1661" height="391" alt="image" src="https://github.com/user-attachments/assets/482d3462-4014-44e1-880a-c28bbd8e840b" />


## Etapa 6: Balanceamento de Carga com Application Load Balancer (ALB)

O Application Load Balancer (ALB) atua como uma **"porta de entrada "** da nossa aplicação. Ele é uma ponte de contato com a internet e é responsável por gerenciar todo o tráfego de entrada de forma eficiente e segura, cumprindo duas funções principais descritas neste projeto:

- **Distribuição de Tráfego:** O ALB recebe todas as solicitações dos usuários e as distribui de forma equilibrada entre as instâncias EC2 saudáveis (funcionando) que estão rodando em diferentes Zonas de Disponibilidade. Isso evita que uma única instância fique sobrecarregada e melhora o desempenho geral do site.

- **Configuração de Health Check:** O ALB, através de seu **Grupo de Destino (Target Group)**, realiza verificações de saúde constantes em cada instância. Ele foi configurado para acessar a página inicial (`/`) de cada servidor via HTTP. Se uma instância falhar em responder ou retornar um erro, o ALB a marca como "não saudável" e para de enviar tráfego para ela imediatamente, redirecionando os usuários para as instâncias que estão operando normalmente. Isso garante a resiliência e a confiabilidade da aplicação.

Adicionalmente, o ALB é um serviço altamente disponível, posicionado nas **duas sub-redes públicas** para garantir que o site permaneça acessível mesmo com a falha de uma Zona de Disponibilidade inteira.

## Etapa 6.1: Criação do Application Load Balancer
- No console da EC2, no menu à esquerda, clique em **"Load Balancers"**.
- Logo após clique em **"Criar load balancer"**

<img width="1897" height="842" alt="image" src="https://github.com/user-attachments/assets/b2374cbd-adac-4ff8-b1e6-de9e572a2808" />

- Selecione o card do application load balancer e clique em **"criar"**

<img width="1915" height="758" alt="image" src="https://github.com/user-attachments/assets/bb6a0d4f-ad4c-43ab-b9d8-bc2c189c8b20" />

- Escolha um nome para seu load balancer
- **Esquema:** Voltado para internet
- **Tipo de endereço do balanceador de carga:** IPv4

<img width="1848" height="665" alt="image" src="https://github.com/user-attachments/assets/0dde7ad3-395b-4cba-96ae-b7a1183dfc0a" />

- **VPC:** selecione a sua VPC já criada.
- **Grupos de IPs:** deixe essa opção desmarcada.
- **Zonas de disponibilidade e sub-redes:** selecione suas subnets públicas que estão em Zonas de disponibilidade diferente.
  
**Observação:** É importante que você tenha criado sua VPC em Zonas de disponibilidades diferentes para prosseguir nessa parte.

<img width="1789" height="241" alt="image" src="https://github.com/user-attachments/assets/8a8aa533-f7bf-4f7e-8da8-4fd1a791f8dc" />

- Selecione o grupo de segurança onde contém as regras para o load balancer.

<img width="1871" height="514" alt="image" src="https://github.com/user-attachments/assets/510f59c4-b75a-414c-aeb2-911e373f8603" />

- **Protocolo:** `HTTP`.
- **Porta:** `80`.
- Na ação padrão, clique em **"Criar grupo de destino"** (Create target group)
- Abrirá uma nova aba com as seguintes informações:

<img width="1906" height="834" alt="image" src="https://github.com/user-attachments/assets/890fadd6-2b6e-4b16-b565-cb37dd2cad5c" />

- Escolha um tipo de destino: `Instâncias`
- Digite um nome para seu grupo de destino

<img width="1905" height="805" alt="image" src="https://github.com/user-attachments/assets/89f29358-fdb0-4246-a01f-a58a0256ddbc" />

- Verifique se suas informações estão em conformidade com a imagem.
- Vá em **"Configurações avançadas de verificação de integridade"**.

<img width="1891" height="840" alt="image" src="https://github.com/user-attachments/assets/2dbe20dd-8bf2-4cee-9486-80610b747967" />

Adicione as seguintes configurações:

- **Porta da verificação:** `Porta de tráfego (Traffic port)`.
- **Limite íntegro:** `2 verificações consecutivas`.
- **Limite não íntegro:** `2 verificações consecutivas`.
- **Tempo limite:** `5 segundos`.
- **Intervalo:** `30 segundos`.
- **Códigos de sucesso:** `200`.

Essa configuração de verificação de saúde do Application Load Balancer foi projetada para criar um sistema resiliente e com capacidade de autocorreção. A cada 30 segundos, o balanceador testa a página inicial de cada instância na porta 80, esperando uma resposta de sucesso (código 200 OK) em menos de 5 segundos. Na tela seguinte, de "Registrar destinos", não selecione nenhuma instância. Deixe a lista vazia e apenas clique em "Criar grupo de destino". O Auto Scaling Group cuidará do registro automaticamente.

Após a aplicação destas configurações, clique no botão do círculo para atualizar os grupos de destinos e selecione seu grupo já criado.

<img width="1909" height="505" alt="image" src="https://github.com/user-attachments/assets/f1c4b7d2-a32d-4df2-8b97-f50a2b33cdea" />

Verifique no seu resumo se está tudo certo e clique em **criar load balancer**.


## Etapa 7: Escalabilidade e Resiliência com Auto Scaling Group (ASG)
O serviço do Auto Scaling Group (ASG) atua como um **"Gerente de RH"** da aplicação. Sua função é gerenciar o ciclo de vida das instâncias EC2 para garantir que a aplicação tenha sempre a capacidade ideal para atender à demanda dos usuários e se manter resiliente a falhas, cumprindo todos os requisitos do projeto. O mesmo usa-se dos seguintes requisitos.

- **Uso do Launch Template:** O ASG utiliza-se do Launch Template como a "planta" para criar cada nova instância, garantindo que todos os servidores sejam idênticos e configurados corretamente a partir do user data.

- **Posicionamento em Sub-redes Privadas:** Todas as instâncias são criadas dentro das **sub-redes privadas de aplicação**. Isso garante que elas permaneçam seguras e não sejam expostas diretamente à internet.

- **Associação com o ALB:** Toda nova instância criada pelo ASG é automaticamente registrada no Target Group do Application Load Balancer. Ela só começará a receber tráfego do site após passar nas verificações de saúde, garantindo que apenas instâncias 100% funcionais atendam aos usuários.

- **Escalabilidade baseada em CPU:** Foi configurada uma política de escalabilidade dinâmica. Se o uso médio de CPU de todas as instâncias ultrapassar 70%, o ASG automaticamente lançará automaticamente novas instâncias para lidar com o aumento da carga. Da mesma forma, ele pode remover instâncias se a carga diminuir, otimizando os custos.


# Etapa 7.1: Criação do Auto Scaling Group
Antes de começarmos o passo a passo da criação do ASG, seu launch template e seu Target Group já devem estar devidamente criados.

- No console da EC2, no menu à esquerda, role até o final e clique em **"Grupos do Auto Scaling".**

<img width="1901" height="839" alt="image" src="https://github.com/user-attachments/assets/df405261-0dd0-4d3d-b76a-fbcbfc3b91cf" />

- Clique em **"Criar grupo do Auto Scaling"**.
- Após clicar, você será direcionado para a seguinte tela.

<img width="1899" height="848" alt="image" src="https://github.com/user-attachments/assets/c2ec8903-e2f7-4067-bee7-96ea50997900" />

- **Nome do grupo do Auto Scaling**: Digite o nome do seu grupo.
- **Modelo de execução:** Selecione seu modelo de execução.
- Clique em **"próximo"**.

  <img width="1909" height="850" alt="image" src="https://github.com/user-attachments/assets/93873a8a-ab7b-4faa-b0f7-0a6382df15ce" />

- **VPC:** Selecione sua VPC criada.
- **Zonas de disponibilidade e sub-redes:** Na lista, selecione as **duas sub-redes privadas da aplicação** (ex: app-subnet-aeapp-subnet-b). É crucial escolher as sub-redes privadas corretas para proteger as instâncias.
- **Distribuição da zona de disponibilidade**: Melhor esforço equilibrado.
- Clique em **"próximo"**.

<img width="1910" height="706" alt="image" src="https://github.com/user-attachments/assets/faad4486-d8dd-420b-ad00-37cee1d91e19" />

- **Balanceamento de carga:** Anexar a um balanceador de carga existente.
- **Grupos de destino de balanceador de carga existentes:** Selecione o seu load balancer criado.
- Clique em **"próximo"**.

<img width="1889" height="515" alt="image" src="https://github.com/user-attachments/assets/9c17e8ce-553e-415e-85d8-29489da34825" />

Na etapa de "Configurar opções avançadas", você pode manter as configurações de monitoramento padrão do CloudWatch e clicar em "Próximo".

<img width="1726" height="654" alt="image" src="https://github.com/user-attachments/assets/f8891775-7197-465b-92d7-ef814d6840cf" />
 
- **Tipos de verificações de integridade adicionais:** Ative as verificações de integridade do Elastic Load Balancing.
Com essa opção ativada, o Auto Scaling Group passa a considerar o status de saúde reportado pelo Application Load Balancer para determinar se uma instância está funcional.

- Clique em **"próximo"**.

<img width="1884" height="715" alt="image" src="https://github.com/user-attachments/assets/a8e288b7-29ef-4386-a98a-7cb8232afb4e" />

- **Capacidade desejada: 2**
- **Capacidade mínima desejada: 2**
Este valor foi escolhido para garantir **Alta Disponibilidade (High Availability)** desde o primeiro momento. Como a arquitetura está distribuída em duas Zonas de Disponibilidade (AZs), manter um mínimo de duas instâncias garante que, se uma instância (ou uma AZ inteira) falhar, a outra instância na outra AZ continuará servindo o tráfego, evitando que o site saia do ar. O Auto Scaling Group então trabalhará para substituir a instância que falhou, retornando ao estado saudável de duas instâncias.

- **Capacidade máxima desejada: 4**
O valor máximo de quatro instâncias define o limite de **Escalabilidade** da nossa aplicação e também atua como uma medida de **Controle de Custos**. Se houver um pico de acessos e a utilização da CPU ultrapassar nosso alvo de 70%, o Auto Scaling Group tem permissão para adicionar até mais duas instâncias para lidar com a carga. Ao mesmo tempo, este limite impede que o grupo crie um número ilimitado de instâncias em caso de um pico de tráfego anormal ou um ataque, o que poderia levar a uma fatura inesperada na AWS.

<img width="1520" height="610" alt="image" src="https://github.com/user-attachments/assets/e21e6c64-16ea-4916-8e0f-4b2ad1d21fa5" />

Para automatizar a escalabilidade, foi configurada uma **"Política de dimensionamento com monitoramento do objetivo" (Target Tracking Policy)**. Esta é uma política inteligente que funciona como um termostato para a nossa aplicação, ajustando automaticamente o número de instâncias para manter o desempenho ideal para a aplicação.

As configurações específicas foram:

- **Tipo de Métrica:** Média de utilização da CPU O Auto Scaling Group irá monitorar constantemente a carga de processamento média de todas as instâncias em execução.
  
- **Valor de Destino:** 70%. Este é o nosso "ponto de equilíbrio". Se o tráfego no site aumentar e a média de uso da CPU de todas as instâncias ultrapassar 70%, o Auto Scaling Group automaticamente adicionará novas instâncias para distribuir a carga. Da mesma forma, se o tráfego diminuir e a CPU ficar ociosa, ele removerá instâncias para otimizar os custos (sempre respeitando a capacidade mínima de 2).
  
- **Aquecimento da Instância:** 300 segundos. Esta configuração instrui o Auto Scaling a esperar 5 minutos antes de incluir uma instância recém-lançada nas métricas de CPU. Isso dá tempo para a instância iniciar, executar o script `user-data` e estabilizar, evitando que picos de uso durante a inicialização causem decisões de escalabilidade prematuras.

Essa combinação de regras garante que a aplicação responda dinamicamente à demanda real dos usuários, crescendo para suportar picos de tráfego e encolhendo para economizar recursos, tudo de forma 100% automática.


## Próximos Passos e Melhorias

Para evoluir ainda mais esta arquitetura, os próximos passos lógicos seriam:
* **Infraestrutura como Código (IaC):** Automatizar toda a criação da infraestrutura utilizando Terraform ou AWS CloudFormation, conforme sugerido nas atividades extras.
* **Monitoramento Avançado:** Criar dashboards detalhados no Amazon CloudWatch e configurar alarmes para notificar sobre falhas ou picos de uso.
* **DNS Personalizado:** Utilizar o Amazon Route 53 para associar um domínio personalizado (ex: `www.meusite.com`) ao Application Load Balancer.
* **Segurança Reforçada:** Implementar HTTPS no Load Balancer com um certificado do AWS Certificate Manager (ACM) para garantir tráfego criptografado.

Com isso, o projeto seria ainda mais robusto. Porém devido a tempo e custos, apenas com esses passos mencionados, a aplicação atende bem aos requisitos pedidos.


































 


  
