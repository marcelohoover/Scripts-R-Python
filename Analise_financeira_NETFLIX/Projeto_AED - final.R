options(scipen=999)

getwd()

set.seed(123)

library("dplyr")
library("GGally")
library("ggplot2")
library("gridExtra")
library("DataExplorer")

dataset <- read.csv2(file.choose(), sep = ",", header = TRUE)

#---------------------------------------------------------
#Entendendo e transformando os dados
#---------------------------------------------------------
str(dataset)

dataset$Earnings.per.Customer <- as.numeric(as.character(dataset$Earnings.per.Customer))
dataset$Revenue.per.Customer <- as.numeric(as.character(dataset$Revenue.per.Customer))
dataset$Cost.per.Customer..excluding.marketing. <- as.numeric(as.character(dataset$Cost.per.Customer..excluding.marketing.))
dataset$Contribution.Margin <- as.numeric(as.character(dataset$Contribution.Margin))*100
dataset$Time <-as.Date(dataset$Time, "%B %d, %Y")

colnames(dataset) = c("Time","Tot_Assinantes","Assinaturas_pagas","Free_Trails","Receita"
             ,"Custos_Receita","Marketing","Lucro_liquido","Margem_Lucro_liquido"
             ,"Custo_Cliente","Receita_Cliente","Ganhos_Cliente","Segmento")

#A coluna segmento possui valor unico em todas as observações.Ela não terá relevancia nessa analise

#O Total de Assinaturas são todas as Assinaturas vigentes no fim do periodo
#somados com os usuarios de teste(Free Trials). 

#Ja Lucro_liquido pode ser declarada em uma base bruta ou por unidade. Podemos dizer que
#essa variavel representa a somatoria do dinheiro incremental gerado pelas assinaturas  
#vendidas após dedução da parcela variável dos custos da empresa.
#
# ou Lucro_liquido = (Receita - Custos_Receita) - Marketing

dataset$Segmento <-NULL
View(dataset)
#-----------------------------------------------------------
# Verificação dp crescimento Absoluto e relativo por assinaturas
#-----------------------------------------------------------
dataset_v2 <- dataset %>%
  arrange(Time) %>%  #ordenacao do periodo
  #mutate(Diff_dias = Time - lag(Time))%>% #Diferenca do periodo por segurança
  mutate(Dif_Cresc_clientes = Tot_Assinantes - lag(Tot_Assinantes))%>% #Diferenca do total de assinaturas entre os periodos
  mutate(Perc_Cresc = (Dif_Cresc_clientes / Tot_Assinantes) * 100)%>% #Crescimento em %
  mutate(Total_Cresc =(Dif_Cresc_clientes)/ lag(Tot_Assinantes)*100)

#Calculo da receita liquida (Sem custos com Marketing)
dataset_v2$Receita_liquida <- dataset_v2$Receita - dataset_v2$Custos_Receita

#Criação da coluna Ano
dataset_v2$Ano <- as.numeric(format(dataset_v2$Time,"%Y"))

#Criação da coluna Ano-mes
dataset_v2$Mes_Ano <- format(as.Date(dataset_v2$Time), "%Y-%m")

#Criação da coluna Quarter
library(zoo)

dataset_v2$Quarter <-as.yearqtr(dataset_v2$Time, format = "%Y-%m-%d")

summary(dataset_v2)
str(dataset_v2)

#Substituição das NAs do dataset 
dataset_v2[is.na(dataset_v2)] = 0
str(dataset_v2)

#---------------------------------------------------------
#Entendendo a variaveis do dataset
#---------------------------------------------------------
ggpairs(dataset_v2[,1:16],
title="Resumo simplificado",
lower=list(combo=wrap("facethist",binwidth=1)))

#Se nota pelos graficos de scatterpolot que muitas variaveis do dataset
#possuem uma alta correlação entre si. 

#Busca por correlação
plot_correlation(na.omit(dataset_v2[,1:16]), maxcat = 6L)

#Analise por histogramas - sem distribuição normal
plot_histogram(dataset_v2,geom_histogram_args = list(bins = 40L), nrow = 5)

#---------------------------------------------------------
#Desempenho dos kpis da netflix atraves do tempo
#---------------------------------------------------------
plot1 <- ggplot(data=dataset_v2) +
          geom_line(aes(x=Time, y=Receita, colour = "Receita"))+
          geom_line(aes(x=Time, y=Lucro_liquido, colour = "Lucro Liquido"))+
          ggtitle("Receitas (in thousands US dollars) x Periodo (Trimestre)")+
          theme_minimal()

plot2 <- ggplot(data=dataset_v2) +
          geom_line(aes(x=Time, y=Marketing, colour = "Gastos com Marketing"))+
          geom_line(aes(x=Time, y=Lucro_liquido, colour = "Lucro Liquido"))+
          ggtitle("Relação Marketing e Lucro Liquido (in thousands US dollars) x Periodo (Trimestre)")+
          theme_minimal()
        #Relação de dependencia do Marketing no lucro liquido da Netflix
                
plot3 <- ggplot(data=dataset_v2) +
          geom_line(aes(x=Time, y=Receita_Cliente, colour = "Receita por cliente"))+
          geom_line(aes(x=Time, y=Custo_Cliente, colour = "Custo por cliente"))+
          geom_line(aes(x=Time, y=Ganhos_Cliente, colour = "Lucro por cliente"))+
          ggtitle("Relação Breakeven x Periodo (Trimestre)")+
          theme_minimal()
        #Analise de performance da Netflix - A Netflix vem melhorando a sua operação com
        #o decorrer do tempo

plot4 <- ggplot(data=dataset_v2) +
          geom_line(aes(x=Time, y=Marketing, colour = "Gastos com Marketing"))+
          geom_line(aes(x=Time, y=Tot_Assinantes, colour = "Total assinantes"))+
          geom_line(aes(x=Time, y=Assinaturas_pagas, colour = "Assinaturas pagas"))+
          ggtitle("Total de Assinantes e Pagantes x Gastos com Marketing")+
          theme_minimal()
        # Acompanhamento da convesão dos clientes

plot5 <- ggplot(data=dataset_v2, aes(x=Time, y=Dif_Cresc_clientes)) +
          geom_line()+
          geom_point()+
          ggtitle("Crescimento de assinantes em numeros absolutos")+
          theme_minimal()

plot6 <- ggplot(data=dataset_v2) +
          geom_line(aes(x=Time, y=Perc_Cresc, colour = "%Cresc. Assinantes"))+
          geom_line(aes(x=Time, y=Margem_Lucro_liquido, colour = "%Margem Lucro Liquido"))+
          ggtitle("%Margen de Lucro liquido x Cresc. Clientes")+
          theme_minimal()
        # Teria a netflix antingido o seu limiar ?

grid.arrange(plot1, plot2, plot3, plot4, plot5, plot6, ncol=2)

# Netflix registra no periodo uma receita de $31,424,995(in thousand US) 
sum(dataset_v2$Receita, na.rm = TRUE)

# Em 2018 o valor somando no mesmo periodo foi $7,646,647(in thousand US). 
sum(subset(dataset_v2$Receita,dataset_v2$Ano == 2018) ,  na.rm = TRUE)

# O Cresccimento medio da netflix nos ultimos 28 trimestres foi de 3.34%. Um bom numero.
mean(dataset_v2$Total_Cresc, na.rm = TRUE)

# Por uma breve analise dos numeros da Netflix, vemos que a empresa vem performando melhor
# a cada Quarter, aumentando o seu lucro liquido por cliente, além de ter aumentado 
# sua receita.
#
# Aparentemente, a Netflix se mostra uma empresa com potencial de alavancagem
# de mercado porém não vemos suas dividas no dataset original.
#
# Não podemos nos basear somente nos ativos e performance da empresa sem ver seus passivos.
# Aparentemente vemos um custo do operacional, porém não temos ideia da sua saúde financeira
#
# Com isso em mente, vou buscar algumas variaveis novas para agregar a essa
# analise. Essas variaveis devem ser um complemento em relação ao dataset
# original e facilitará o entendimento da empresa e como ela performa no mercado.
#
# As variaveis pesquisadas foram:
#
# Divida liquida da empresa no fim do periodo (Quarterly Long Term Debt in Millions of US $)
# disponivel em https://www.macrotrends.net/stocks/charts/NFLX/netflix/long-term-debt 
#
# A taxa de Juros aplicada no periodo. (Extremamente importante para entender a sua divida)
# disponivel em https://fred.stlouisfed.org/series/FEDFUNDS
#
# O valor de mercado da empresa (Market Cap in Millions of US $).
# disponivel em https://www.macrotrends.net/stocks/charts/NFLX/netflix/market-cap
# Indicador geral de como
# o mercado vê os resultados da empresa.
#
# Como o dataset Original trabalha na escala de Thousands US dollars, iremos trasnformar as 
# variavies pesquisadas de Millions of US para Thousands of US
#
#---------------------------------------------------------
# Divida liquida in Millions of US $ (Quarterly Long Term Debt) 
#---------------------------------------------------------
library(rvest)
library(stringr)

webpage <- read_html("https://www.macrotrends.net/stocks/charts/NFLX/netflix/long-term-debt")

Debt_netflix_list <- webpage %>% 
                    html_nodes(xpath='/html/body/div[2]/div[4]/div[7]/div[2]/table') %>%
                    html_table()

Periodo <- as.data.frame(Debt_netflix_list[[1]][1]) 
Debito <- as.data.frame(Debt_netflix_list[[1]][2])

Debt_netflix <- cbind(Periodo,Debito)
colnames(Debt_netflix)<-c("Time","Divida")

str(Debt_netflix)

# Tratamento do dataset para extrair a coluna divida
Debt_netflix$Divida <- str_replace(Debt_netflix$Divida,"[$]","")
Debt_netflix$Divida <- str_replace(Debt_netflix$Divida,",","")
Debt_netflix[is.na(Debt_netflix)] = 0
Debt_netflix$Divida <- as.numeric(Debt_netflix$Divida)*1000 #De Millions to Thousandsof US $
Debt_netflix$Time <- as.Date(Debt_netflix$Time, format = "%Y-%m-%d")

str(Debt_netflix)

#Subset da divida Q1-2012(March 31,2012) ate Q4-2018(December 31,2018)
Debt_netflix <- subset(Debt_netflix,Debt_netflix$Time >"2011-12-31" & Debt_netflix$Time < "2019-01-01")

dataset_v3 <- merge(dataset_v2, Debt_netflix, by = "Time")

View(dataset_v3)

rm(webpage)
rm(Debt_netflix_list) 

ggplot(data=dataset_v3) +
  geom_line(aes(x=Time, y=Receita, colour = "Receita"))+
  geom_line(aes(x=Time, y=Divida, colour = "Divida da netflix"))+
  ggtitle("Receitas (in thousands US dollars) x Periodo (Trimestre)")+
  theme_minimal()

# Notamos uma divida assustadora da Netflix. Em uma rapida pesquisa, vemos que empresa usa
# como estrategia, a emissão de dívidas de longo prazo e outras 
# obrigações financeiras por direitos de distribuição de conteúdo.

# Fontes:
# https://canaltech.com.br/entretenimento/netflix-levanta-mais-de-us-2-bi-para-cobrir-gastos-com-conteudos-originais-137743/
# https://www.bbc.com/portuguese/geral-40833885 

#---------------------------------------------------------
# Taxa de juros
#---------------------------------------------------------
#Fonte: https://fred.stlouisfed.org/series/FEDFUNDS
#
# A fonte pesquisada disponibiliza a opções de filtro, download e vizualização do dataset
# Para este exemplo, selecionamos os valores dos anos de 2012 ate 2019.

juros_fed <- read.csv("FEDFUNDS.csv", sep = ",", header = TRUE) 

str(juros_fed)

# Para facilitar a adição ao dataset principal, faço um join do valor da taxa usando 
# a o periodo Ano-mês

juros_fed$DATE <- as.Date(juros_fed$DATE,format = "%Y-%m-%d")
#juros_fed$Quarter <- as.yearqtr(as.Date(juros_fed$DATE,format = "%Y-%m-%d"))
juros_fed$Mes_Ano <- format(as.Date(juros_fed$DATE), "%Y-%m")

juros_fed$DATE <- NULL

dataset_v4 <- merge(dataset_v3,juros_fed, by="Mes_Ano")

View(dataset_v4)

ggplot(data=dataset_v4, aes(x=Time, y=FEDFUNDS)) +
  geom_line()+
  geom_point()+
  ggtitle("FED - Taxa de Juros")+
  theme_minimal()

ggplot(data=dataset_v4) +
  geom_line(aes(x=Time, y=FEDFUNDS, colour = "%Cresc. Juros"))+
  geom_line(aes(x=Time, y=Total_Cresc, colour = "%Cresc. Assinaturas"))+
  ggtitle("Comparativo - %Taxa de Juros x Cresc. Clientes")+
  theme_minimal()

# Notamos uma taxa de Juros crescente no periodo. O aumento dessa taxa poderia 
# explicar o aumento da divida da Netflix

#---------------------------------------------------------
# Marketcap (in billions of us dolares)
#---------------------------------------------------------
# Fonte: https://www.macrotrends.net/stocks/charts/NFLX/netflix/market-cap
marketcap <- read.csv(file = "Marketcap.csv", sep = "," ,header = TRUE)

str(marketcap)

marketcap$Time <-as.Date(dataset$Time, "%B %d, %Y")

str(marketcap)

dataset_v5 <- merge(dataset_v4, marketcap, by="Time")

ggplot(data=dataset_v5, aes(x=Time, y=Marketcap)) +
  geom_line()+
  geom_point()+
  ggtitle("Marketcap - in billions of us dolares")+
  theme_minimal()

ggplot(data=dataset_v5) +
  geom_line(aes(x=Time, y=(Marketcap), colour = "MarketCap in Bilhões"))+
  geom_line(aes(x=Time, y=(Divida/1000000), colour = "Divida "))+
  ggtitle("Conclusões")+
  theme_minimal()
#-------------------------------------------------------------------------------------
# CONSIDERAÇÕES
#-------------------------------------------------------------------------------------
# Ao fim, vemos que o valor de mercado da Netflix no fim do Q4 de 2018 é de 130.02 Bi 
# e sua divida são 10,3 Bi. No mesmo periodo, sua receita é de 1,996,092K ou
# aproximadamente 2 Bi, onde grande parte dessa receita é reinvestido no Marketing.
# Seu lucro liquido de 29.6% da sua receita (590,843K) ou 0.6 Bi 
#
# A empresa inovou o segmento de streaming e pelo que foi possivél notar através de
# pesquisas, se beneficiou das baixas taxas de juros do mercado para atingir o tamanho e
# relevancia que possui hoje.
#
# Porém como a Netflix se sustentará a longo prazo? 
#
# Como analista de mercado levanto algumas observações importantes:
#
# O crescimento do Juros poderia inviabilizar o negocio da Netflix?
#
# Notamos também um gasto cada vez maior no marketing para uma taxa de crescimento cada
# vez menor na conversão de clientes. 
# Isso poderia ser sinais de perda de marketshare para a concorência.
#
# Mesmo com uma melhor performance operacional, a Netflix poderá lidar e melhorar 
# esses numeros no futuro? 
#
# Se endividar ate 16 vezes o valor da sua receita liquida, é a unica forma de se manter
# na liderança no segmento de streaming?
#
# Vejo com preocupação todo esse cenário, mesmo sabendo do potêncial da Netflix.

