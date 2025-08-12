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

Caso todos esses requisitos sejam atendidos, siga as seguintes etapas de execução do projeto.

## Etapa 1: Criação e personalização da VPC
A base de toda a arquitetura desta aplicação está na AWS VPC (Virtual Private Cloud). A VPC atua como um perímetro virtual, mantendo o sistema privado e totalmente isolado da internet pública. Essa separação é a primeira e mais importante camada de segurança para que os recursos que serão implantados em seu interior estejam completamente seguros. Para este projeto, foram considerado as seguintes configurações da VPC.

- **Endereçamento IP da VPC:** Foi escolhido o seguinte bloco IP `10.0.0.0/16`, o mesmo fornece mais de 65.000 endereços de IPs. Isso nos dá um espaço extremamente amplo para escalar a aplicação no futuro, adicionando novos serviços sem o risco de esgotar os endereços.

- **Múltiplas Zonas de Disponibilidade (AZs):** A VPC foi alocada em duas zonas de disponibilidade distintas, o que garante alta disponibilidade em caso de falhas. Uma AZ é composta por um ou mais data centers discretos. Caso ocorra uma falha na zona us-east-2a, por exemplo, a us-east-2b continuará operando normalmente, garantindo que a aplicação permaneça no ar e acessível aos usuários.

- **Segmentação em 6 subnets:** Para garantir a segurança em camadas (princípio de "defesa em profundidade"), a VPC será divida em 6 sub-redes, sendo elas:

  * **2 Subnets Públicas:** Uma em cada AZ. Elas servem como a "zona desmilitarizada" (DMZ), abrigando recursos que precisam de acesso direto à internet, como nosso Application Load Balancer.
    
  * **2 Subnets Privadas para Aplicação (App):** Uma em cada AZ. Aqui residem nossas instâncias EC2 com o WordPress. As mesmas não são acessíveis diretamente pela internet, sendo protegidas pelo Application Load Balancer.
  
  * **2 Subnets Privadas para Dados (Data):** Uma em cada AZ. Esta é a camada mais segura, nela irá hospedar o banco de dados RDS e os pontos de acesso do EFS (EFS Mount Target), garantindo que apenas as EC2 possam se comunicar com eles.

- **Conectividade e Roteamento:**
  * Um **Internet Gateway (IGW)** foi anexado à VPC para funcionar como a porta de entrada e saída para a internet.
 
  * Um **NAT Gateway** foi posicionado nas duas subnets públicas. A sua função é crucial, ele permite que as instâncias nas sub-redes privadas (como os servidores WordPress) acessem a internet para baixar atualizações ou pacotes, funcionando como um escudo de segurança para o tráfego de saída.

  * **Tabelas de Rotas** foram configuradas para controlar o fluxo de tráfego.

## Etapa 1.2: Passo a passo para criação da VPC na AWS
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

* **Número de sub-redes privadas:** `4` (Estas serão nossas sub-redes de Aplicação (App) onde irão ficar as duas EC2 da aplicação. Ex: 10.0.3.0/24, 10.0.4.0/24 e também serão usadas para o Data onde ficará o RDS). Após a criação das subnets privadas, o assistente pode acabar deixando o nome delas bem genérico, para seguir a organização da aplicação, é uma boa escolha deixar os nomes `Private subnet(App)1`, `Private subnet(App)2`, `Private subnet(Data)1` e `Private subnet (Data)2` como mostra no diagrama do projeto.

* O **internet Gateway** será gerado automaticamente pelo assistente, logo não é preciso adiciona-lo manualmente.

* **Gateways NAT:** Selecione "Nenhum" (posteriomente iremos adiciona-los manualmente na aplicação).

* **Endpoints da VPC:** Mantenha como "Nenhum".

* Agora clique em **Criar VPC.**

## Etapa 2: Criação do banco de dados Amazon RDS (Relational Database System)
Para que dados como posts, usuários e configuração possam persistir na aplicação, precisamos de um banco de dados para que essa possibilidade seja possível, com isso, vamos usar o **Amazon RDS (Relational Database System).** O RDS é um serviço de banco de dados relacional gerenciado, o que significa que a AWS automatiza tarefas complexas e repetitivas, como provisionamento de hardware, instalação de um sistema operacional, aplicação de patches de segurança e backups. Isso nos permite focar no desenvolvimento da aplicação em si, ao invés de gerenciar o banco de dados.

As configurações escolhidas para o RDS foram:
* **Mecanismo (Engine):** Foi escolhido o MySQL Community, versão 8.0.42, ele é um dos sistemas de gerenciamento de banco de dados de código aberto mais populares do mundo e totalmente compatível com os requisitos do WordPress.
  
* **Tipo de Instância:** Para esse projeto bem simples e didático e para reduzir os custos, foi selecionada a instância `db.t3.micro`. Ela faz parte da família de instâncias "burstable", oferecendo um desempenho de linha de base com a capacidade de "burst" (picos de performance) para lidar com cargas de trabalho variáveis, ideal para um site com tráfego de baixo a moderado.
  
* **Posicionamento na Rede:** O banco de dados foi estrategicamente posicionado na camada mais segura da rede: as sub-redes privadas de dados. Essa configuração garante que ele não tenha nenhuma exposição à internet e só possa ser acessado pela nossa camada de aplicação (as instâncias EC2), conforme definido pelas regras do Security Group do RDS.
  
* **Disponibilidade (Multi-AZ):** Visando o controle de custos para este ambiente de aprendizado, a funcionalidade de Multi-AZ foi desativada. Em um ambiente de produção real, ativar o Multi-AZ é uma melhor prática crucial, pois cria uma réplica de standby do banco de dados em outra Zona de Disponibilidade, garantindo a recuperação automática e rápida em caso de falha da instância primária.

## Etapa 2.1: Security Groups
Os Security Groups (SGs) atuam como firewalls virtuais para nossos recursos na nuvem. Eles são o principal mecanismo de controle de tráfego, funcionando como porteiros que decidem exatamente quem pode entrar e em qual porta. Para este projeto, criei uma "cadeia de confiança" entre os SGs, garantindo o princípio do menor privilégio, onde cada camada só confia na camada imediatamente anterior a ela.

## Etapa 2.2: Criação do Security group Application Load Balancer
Este primeiro Security Group irá atuar como uma **porta de entrada principal** da aplicação, controlando todo o tráfego que chega da internet ao **Application Load Balancer (ALB)**. Ele define as regras que determinam quais conexões externas podem acessar a camada de balanceamento, garantindo segurança e filtragem antes que os dados da internet sejam encaminhado para as instâncias EC2.

- Na barra de pesquisa do console, digite por **"EC2"**. 

- No painel da EC2 vá em **"Rede e segurança"** depois em **"Security groups"**.

- Depois clique em **"Criar Grupo de Segurança"**

<img width="1883" height="583" alt="image" src="https://github.com/user-attachments/assets/def89828-e8b7-40d6-bc3a-d967123f8a06" />


- Insira o nome do grupo de segurança.

- Adicione alguma descrição para não se perder.

- Selecione a VPC que você criou.

<img width="1893" height="603" alt="image" src="https://github.com/user-attachments/assets/af4fdc39-83d0-42fa-a02d-bf25310ab176" />

- Regras de entrada:
  * **Tipo:** HTTP
  * **Protocolo:** TCP
  * **Intervalos de portas:** 80
  * **Origem:** Qualquer lugar-IPv4 (0.0.0.0/0).
 
justificativa: A origem 0.0.0.0/0 é utilizada para que o Application Load Balancer é o ponto de acesso público do WordPress e precisa aceitar conexões de qualquer usuário da internet.

- Regras de saída:
Você pode manter a regra padrão (Todo o tráfego para 0.0.0.0/0). O Load Balancer precisa dessa regra para encaminhar o tráfego para as instâncias EC2.

- Clique em **"Criar grupo de segurança"**. 

## Etapa 2.3: Criação do Security Group EC2
Este Security Group tem o propósito de proteger as instâncias EC2 que rodam os **contêineres Docker com o WordPress.** As regras a seguir foram configuradas para garantir que apenas tráfego autorizado e proveniente de fontes confiáveis chegue até os servidores da aplicação.

- Repita o mesmo processo descrito na criação do security group do ALB.

- Regras de entradas:
<img width="1865" height="314" alt="image" src="https://github.com/user-attachments/assets/a9f30326-dc33-410f-9676-1fc376f34951" />

Aqui foram adicionadas duas regras de entrada:
- 1° Regra:

  * **Tipo:** HTTP
  * **Intervalos de portas:** 80 
  * **Origem:** Exclusivamente do Security Group do Application Load Balancer (`alb-security group`).

 Esta regra assegura que todo acesso ao WordPress passe primeiro pelo Load Balancer, impedindo conexões diretas vindas da internet para as instâncias EC2. Dessa forma, aplicamos o princípio do menor privilégio e mantemos a arquitetura em camadas (layered security).

- 2° Regra:

  * **Tipo:** TCP Personalizado
  * **Intervalos de portas:** 8080
  * **Origem:** Exclusivamente do seu endereço IP, por motivos de segurança, não irei mostrar aqui, mas quando você clicar em **"Meu IP"** irá mostrar seu endereço IP.

 Esta regra permite que o administrador acesse a interface do phpMyAdmin pela porta `8080`. Ao restringir a origem a um IP específico, garantimos que esta ferramenta administrativa não fique exposta à internet pública, uma medida de segurança crucial nesta aplicação.


## Etapa 2.4: Criação do Security Group RDS

O Security Group RDS foi configurado para proteger o banco de dados relacional utilizado pelo WordPress. Seu objetivo é restringir ao máximo o acesso, permitindo conexões apenas das instâncias EC2 autorizadas.

Vamos novamente criar um novo grupo de segurança, adicionando o nome, selecionando a VPC que foi criada, porém vamos adicionar a seguinte regra de entrada.

<img width="1905" height="631" alt="image" src="https://github.com/user-attachments/assets/d665c394-bb9c-4fb0-9c50-88a36e73ffb6" />

* **Tipo:** MYSQL/Aurora

* **Protocolo:** TCP

* **Intervalo de portas:** 3306

* **Origem:** Personalizado

* Adicione o security group da EC2

* As regras de saída serão mantidas padrão

Essa configuração permite que somente as EC2 que executam o WordPress possam se conectar ao banco de dados RDS, impedindo qualquer acesso direto da internet ou de outros serviços não autorizados. Logo após as configurações, clique em "Criar grupo de Segurança.



## Etapa 2.5: Criação do Security Group para o EFS

O Security Group EFS foi criado para proteger o sistema de arquivos compartilhado utilizado pelas instâncias EC2 para armazenar conteúdos persistentes do WordPress. Sua função é garantir que apenas instâncias autorizadas possam montar e acessar os arquivos do EFS.

Criaremos novamente outro grupo de segurança, adicionando o nome, selecionando a VPC já criada e adicionando as seguintes regras de entrada.


<img width="1905" height="504" alt="image" src="https://github.com/user-attachments/assets/6ed92812-c6f3-4cf3-bfad-74940ea06197" />

* **Tipo:** NFS

* **Protocolo:** TCP

* **Intervalo de portas: **2049

* Origem: Exclusivamente do Security Group das instâncias EC2 (seu grupo de segurança da EC2).

* As regras de saída serão mantidas como padrão

Essa configuração adicionada permite que apenas as EC2 do projeto acessem os arquivos do EFS e impedem que qualquer outro recurso (interno ou externo) consiga montar ou ler o sistema de arquivos. Logo após adicionar essas configurações, clique em "Criar grupo de segurança.

## Etapa 3: Criação do Amazon EFS (Elastic File System)
 **Amazon EFS (Elastic File System)** é um serviço da AWS que atua como um sistema de arquivos centralizado e compartilhado, semelhante a um “HD de rede” na nuvem da AWS. Ele fornece armazenamento escalável e de alta disponibilidade, permitindo que múltiplas instâncias EC2 acessem os mesmos arquivos simultaneamente. Sua implementação é essencial para garantir a **persistência e consistência dos dados** em arquiteturas com mais de uma instância. Por exemplo, se um usuário fizer upload de uma imagem para a instância **A**, a instância **B** não terá acesso a esse arquivo caso utilize apenas armazenamento local, o que pode gerar falhas e inconsistências na aplicação. Com o EFS, todos os arquivos ficam centralizados, garantindo que qualquer instância conectada tenha acesso imediato às alterações realizadas por outra, eliminando problemas de sincronização e preservando a integridade dos dados.

As seguintes configurações serão usadas no EFS:

**Classe de Armazenamento (Regional):** Utilizei a classe de armazenamento "Regional", que cópia os dados automaticamente em múltiplas Zonas de Disponibilidade. Isso garante que o sistema de arquivos seja tão resiliente e disponível quanto o resto da nossa aplicação, sobrevivendo até mesmo à falha completa de um data center.

**Pontos de Acesso (Mount Targets):** Para permitir que as instâncias na VPC se conectem ao EFS, os Mount Targets são criados automaticamente na criação do EFS. Cada Mount Target é uma "tomada de rede" com um endereço de IP, posicionada estrategicamente em nossas sub-redes privadas onde estão as EC2. Essa configuração garante o acesso seguro e de alta performance a partir da camada de aplicação.

**Segurança de Acesso:** O acesso aos Mount Targets é rigorosamente controlado pelo security group do efs, que só permite conexões na porta 2049 (protocolo NFS) vindas exclusivamente do security group da EC2.

## Etapa 3.1: Passo a passo para criação do EFS na AWS

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
- ID da sub-rede: `subnet-private3`, `subnet-private4`
- Grupos de segurança: `security-group efs`
- Clique em **"próximo"**
- Após revisar seu EFS, clique em **"Criar"**

<img width="1911" height="837" alt="image" src="https://github.com/user-attachments/assets/879c3475-b2b0-404a-9c42-ffd2d5fd82b9" />

Após a criação do seu EFS, anote o ID do Sistema de arquivos (ex: fs-0123...) ou o endereço de IP de um dos Mount Targets. Essa informação será útil para o script user-data que irá montar o EFS automaticamente nas instâncias EC2.

## Etapa 4:  Automação com Launch Template e User Data
Para que a arquitetura desse projeto seja completamente escalável e resiliente, precisamos de uma forma de lançar novas instâncias EC2 de forma totalmente automática, sem intervenção manual. O Auto Scaling Group precisa de uma "receita" para saber exatamente como configurar um novo servidor. Essa receita é composta por duas peças principais: o Launch Template e o script User Data.

### Etapa 4.1: O Launch Template (O Molde)
O Launch Template funciona como o **"molde" ou a "planta baixa"** para nossas instâncias EC2. Ele é um recurso da AWS onde salvamos todas as configurações base de uma instância, garantindo que cada novo servidor criado pelo Auto Scaling seja idêntico e consistente.

As configurações salvas em nosso template (`wordpress-launch-template`) incluem:
* **AMI (Amazon Machine Image):** A imagem do sistema operacional base (Ubuntu 24.04 LTS).
* **Tipo de Instância:** O poder computacional da máquina (`t2.micro`).
* **Par de Chaves:** Para permitir o acesso SSH seguro.
* **Configurações de Rede:** A VPC e as sub-redes onde a instância deve ser criada.
* **Security Group:** O `ec2-sg` para aplicar nosso firewall da camada de aplicação.
* **Script User Data:** O conjunto de comandos a serem executados na primeira inicialização.

### Etapa 4.2: O Script User Data (O automatizador da configuração)
Se o Launch Template é o molde, o script `user-data` é o **"robô construtor"** que entra em ação na primeira vez que a instância é ligada. Ele executa uma sequência de passos para transformar uma instância Ubuntu "limpa" em um servidor WordPress totalmente funcional e conteinerizado.

O script criado realiza as seguintes tarefas:

1.  **Atualiza o Sistema:** Garante que o Ubuntu esteja com os pacotes mais recentes.
2.  **Instala o Docker e o Docker Compose:** Prepara o ambiente para rodar os contêineres.
3.  **Monta o Sistema de Arquivos (EFS):** Conecta a instância ao EFS para garantir que os arquivos do WordPress sejam persistentes e compartilhados.
4.  **Cria o `docker-compose.yml`:** Gera dinamicamente o arquivo de orquestração dos contêineres, inserindo as credenciais do banco de dados RDS.
5.  **Inicia os Serviços:** Executa o `docker compose up -d` para baixar as imagens e iniciar os contêineres do WordPress e do phpMyAdmin.
























 


  
