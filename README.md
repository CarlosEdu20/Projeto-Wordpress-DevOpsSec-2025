# Projeto Wordpress DevOpsSec 2025 | Wordpress em alta disponibilidade na AWS 

## Objetivo:
Com o crescimento contínuo do uso de aplicações web, garantir alta disponibilidade, escalabilidade e resiliência se tornou crucial em qualquer arquitetura moderna, ou seja, esses fatores somados asseguram que os serviços permaneçam acessíveis, suportem picos de demanda e se recuperem rapidamente de falhas sem comprometer a experiência do usuário. Por isso, este projeto visa implantar a plataforma Wordpress na nuvem AWS (Amazon Web Services) de forma escalável e tolerante a falhas, utilizando os principais serviços gerenciados da AWS para garantir o máximo de desempenho, disponibilidade e resiliência.


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
    * WordPress com PHP.i
    * phpMyAdmin

## Pré-requisitos:
Antes de iniciar a replicação deste projeto, garanta que você tenha os seguintes pré-requisitos atendidos:

* **Conta na AWS:** Uma conta na Amazon Web Services com permissões administrativas ou suficientes para criar os recursos listados no projeto como (VPC, EC2, RDS, EFS, etc.).
* **Git:** O [Git](https://git-scm.com/) instalado em sua máquina local ou na nuvem para clonar este repositório.
* **Docker e Docker Compose:** Ter o [Docker Desktop](https://www.docker.com/products/docker-desktop/) ou o motor do Docker e o Docker Compose instalados localmente, caso deseje testar ou modificar o arquivo `docker-compose.yml`.

## Etapa 1: Criação e personalização da VPC
A base de toda a arquitetura dessa aplicação está na AWS VPC (Virtual Private Cloud). A VPC atua como um perímetro virtual, mantendo o sistema privado e totalmente isolado da internet pública. Essa separação é a primeira e mais importante camada de segurança para que os recursos que serão implantados em seu interior estejam completamente seguros. Para este projeto, foi considerado as seguintes configurações.
- **Endereçamento IP da VPC:** Foi escolhido o seguinte bloco IP `10.0.0.0/16`, o mesmo fornece mais de 65.000 endereços de IPs. Isso nos dá um espaço extremamente amplo para escalar a aplicação no futuro, adicionando novos serviços sem o risco de esgotar os endereços.
- **Múltiplas Zonas de Disponibilidade (AZs):** A VPC foi alocada em duas zonas de disponibilidade distintas, fazendo que a mesma possua uma alta disponibilidade em caso de falhas. Uma AZ é composta por um ou mais servidores discretos, se caso ocorrer uma falha na zona `us-east-2a`, por exemplo, a `us-east-2b` estaria operando normalmente, garantindo que a aplicação permaneça no ar e acessível aos usuários.
- **Segmentação em 6 subnets:** Para garantir a segurança em camadas (princípio de "defesa em profundidade"), A VPC será divida em 6 sub-redes, sendo elas:
  * **2 Subnets Públicas:** Uma em cada AZ. Elas servem como a "zona desmilitarizada" (DMZ), abrigando recursos que precisam de acesso direto à internet, como nosso Application Load Balancer.
  * **2 Subnets Privadas para Aplicação (App):** Uma em cada AZ. Aqui residem nossas instâncias EC2 com o WordPress. As mesmas não são acessíveis diretamente pela internet, sendo protegidas pelo Application Load Balancer.
  * **2 Subnets Privadas para Dados (Data):** Uma em cada AZ. Esta é a nossa camada mais segura. Nela, colocamos nosso banco de dados RDS e os pontos de acesso do EFS, garantindo que apenas as EC2 possam se comunicar com eles.
- **Conectividade e Roteamento:**
  * Um **Internet Gateway (IGW)** foi anexado à VPC para funcionar como a porta de entrada e saída para a internet.
  * Um **NAT Gateway** foi posicionado nas duas subnets públicas. A sua função é crucial, ele permite que as instâncias nas sub-redes privadas (como os servidores WordPress) acessem a internet para baixar atualizações ou pacotes, funcionando como um escudo de segurança para o tráfego de saída.
  * **Tabelas de Rotas** foram configuradas para controlar o fluxo de tráfego.

## Etapa 1.2: Passo a passo para criação na AWS
Para facilitar a criação de VPCs, a AWS possui uma maneira mais rápida para subir uma VPC na AWS, que é através do assistente "VPC e muito mais".Siga os seguintes passos a seguir:
- Acesse o console da VPC e clique em **"Criar VPC"**.
- Selecione a opção **"VPC e muito mais**.
- Adicione as seguintes configurações:
<img width="1912" height="783" alt="image" src="https://github.com/user-attachments/assets/0fab1690-43ce-407a-88f9-5da0e2aa3620" />

* **Nome:** `adicione algum nome para sua VPC`
* **Bloco CIDR IPv4:** `10.0.0.0/16`
<img width="1912" height="653" alt="image" src="https://github.com/user-attachments/assets/961bdd97-3491-44ae-8717-f2de875c6088" />

* **Número de zonas de disponibilidade (AZs):** `2`
* **Número de sub-redes públicas:** `2` (O assistente irá nomeá-las e distribuir os IPs, exemplo: 10.0.1.0/24, 10.0.2.0/24)
* **Número de sub-redes privadas:** `4` (Estas serão nossas sub-redes de Aplicação (App) onde irão ficar as duas EC2 da aplicação. Ex: 10.0.3.0/24, 10.0.4.0/24 e também serão usadas para o Data onde ficará o RDS). Após a criação das subnets privadas, o assistente pode acabar deixando o nome delas bem genérico, para seguir a organização da aplicação, é uma boa escolha deixar os nomes `Private subnet(App)1`, `Private subnet(App)2`, `Private subnet(Data)1` e `Private subnet (Data)2`.
* **Gateways NAT:** Selecione "Nenhum" (posteriomente iremos adiciona-los manualmente na aplicação).
* **Endpoints da VPC:** Mantenha como "Nenhum".
* Agora clique em **Criar VPC.**

## Etapa 2: Criação do banco de dados Amazon RDS (Relational Database System)
Para que dados como posts, usuários e configuração possam persistir na aplicação, precisamos de um banco de dados para que essa possibilidade seja possível, com isso, vamos usar o **Amazon RDS.** O RDS é um serviço de banco de dados relacional gerenciado, o que significa que a AWS automatiza tarefas complexas e repetitivas, como provisionamento de hardware, instalação um sistema operacional, aplicação de patches de segurança e backups. Isso nos permite focar no desenvolvimento da aplicação em si, ao invés de gerenciar o banco de dados.

As configurações escolhidas para o RDS foram:
* **Mecanismo (Engine):** Foi escolhido o MySQL Community, versão 8.0.42, ele é um dos sistemas de gerenciamento de banco de dados de código aberto mais populares do mundo e totalmente compatível com os requisitos do WordPress.
* **Tipo de Instância:** Para esse projeto bem simples e didático e para reduzir os custos, foi selecionada a instância `db.t3.micro`. Ela faz parte da família de instâncias "burstable", oferecendo um desempenho de linha de base com a capacidade de "burst" (picos de performance) para lidar com cargas de trabalho variáveis, ideal para um site com tráfego de baixo a moderado.
* **Posicionamento na Rede:** O banco de dados foi estrategicamente posicionado na camada mais segura da rede: as sub-redes privadas de dados. Essa configuração garante que ele não tenha nenhuma exposição à internet e só possa ser acessado pela nossa camada de aplicação (as instâncias EC2), conforme definido pelas regras do Security Group do RDS.
* **Disponibilidade (Multi-AZ):** Visando o controle de custos para este ambiente de aprendizado, a funcionalidade de Multi-AZ foi desativada. Em um ambiente de produção real, ativar o Multi-AZ é uma melhor prática crucial, pois cria uma réplica de standby do banco de dados em outra Zona de Disponibilidade, garantindo a recuperação automática e rápida em caso de falha da instância primária.

## Etapa 2.1: Security Groups
Os Security Groups (SGs) atuam como firewalls virtuais para nossos recursos na nuvem. Eles são o principal mecanismo de controle de tráfego, funcionando como porteiros que decidem exatamente quem pode entrar e em qual porta. Para este projeto, criei uma "cadeia de confiança" entre os SGs, garantindo o princípio do menor privilégio, onde cada camada só confia na camada imediatamente anterior a ela.

### Etapa 2.2: Criação do Security Group EC2
Antes de criamos a regra do security group do RDS, precisamos primeiro criar o da EC2. O mesmo possui o propósito de proteger as instâncias EC2 que rodam os contêineres Docker com o WordPress e o phpMyAdmin.
- **Regras de Entrada Principais:**
    * **Tráfego Web:** Permite tráfego na porta 80 (HTTP) vindo apenas do Security Group do Application Load Balancer (alb-sg, a ser criado). Isso garante que todo o tráfego dos usuários passe primeiro pelo balanceador.






 


  
