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
    * Security Groups
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
    * WordPress
    * phpMyAdmin

## Pré-requisitos:
Antes de iniciar a replicação deste projeto, garanta que você tenha os seguintes pré-requisitos atendidos:

* **Conta na AWS:** Uma conta na Amazon Web Services com permissões administrativas ou suficientes para criar os recursos listados no projeto como (VPC, EC2, RDS, EFS, etc.).
* **Git:** O [Git](https://git-scm.com/) instalado em sua máquina local ou na nuvem para clonar este repositório.
* **Docker e Docker Compose:** Ter o [Docker Desktop](https://www.docker.com/products/docker-desktop/) ou o motor do Docker e o Docker Compose instalados localmente, caso deseje testar ou modificar o arquivo `docker-compose.yml`.

## Etapa 1: Criação e personalização da VPC
A base de toda a arquitetura dessa aplicação está na AWS VPC (Virtual Private Cloud). A VPC atua como um perímetro virtual, mantendo o sistema privado e totalmente isolado da internet pública. Essa separação é a primeira e mais importante camada de segurança para que os recursos que serão implantados em seu interior estejam completamente seguros. Para este projeto, foi considerado as seguintes configurações.
- **Endereçamento IP da VPC:** Foi escolhido o seguinte bloco IP `10.0.0.0/16`, o mesmo fornece mais de 65.000 endereços de IPs. Isso nos dá um espaço extremamente amplo para escalar a aplicação no futuro, adicionando novos serviços sem o risco de esgotar os endereços.
- **Múltiplas Zonas de Disponibilidade (AZs):** A VPC foi alocada em duas zonas de disponibilidade distintas, fazendo que a mesma possua uma alta disponibilidade em caso de falhas. Uma AZ é um servidor fisicamente separado, se caso ocorrer uma falha na zona `us-east-2a`, por exemplo, a `us-east-2b` estaria operando normalmente, garantindo que a aplicação permaneça no ar e acessível aos usuários.
- **Segmentação em 6 subnets:** Para garantir a segurança em camadas (princípio de "defesa em profundidade"), A VPC será divida em 6 sub-redes, sendo elas:
  * **2 Subnets Públicas:** Uma em cada AZ. Elas servem como a "zona desmilitarizada" (DMZ), abrigando recursos que precisam de acesso direto à internet, como nosso Application Load Balancer.
  * **2 Subnets Privadas para Aplicação (App):** Uma em cada AZ. Aqui residem nossas instâncias EC2 com o WordPress. As mesmas não são acessíveis diretamente pela internet, sendo protegidas pelo Application Load Balancer.
  * **2 Subnets Privadas para Dados (Data):** Uma em cada AZ. Esta é a nossa camada mais segura. Nela, colocamos nosso banco de dados RDS e os pontos de acesso do EFS, garantindo que apenas as EC2 possam se comunicar com eles.
- **Conectividade e Roteamento:**
  * Um **Internet Gateway (IGW)** foi anexado à VPC para funcionar como a porta de entrada e saída para a internet.
  * Um **NAT Gateway** foi posicionado nas duas subnets públicas. A sua função é crucial, ele permite que as instâncias nas sub-redes privadas (como os servidores WordPress) acessem a internet para baixar atualizações ou pacotes, funcionando como um escudo de segurança para o tráfego de saída.
  * **Tabelas de Rotas** foram configuradas para controlar o fluxo de tráfego.

## Etapa 1.2: Passo a passo para criação na AWS
A maneira mais rápida para subir uma VPC na AWS é através do 
 


  
