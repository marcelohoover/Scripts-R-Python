# Modelo preditivo para Netflix.
# 
# Como estamos fazendo uma analise de mercado da Netflix, vemos a Receita como a principal
# variavél de interesse para um investidor/analista.
#
# Nossa metodologia de erro sera a M.A.P.E (MAPE)
#
# Divisão da serie temporal entre treino e teste
#-------------------------------------------------------------

library("forecast")

ts <- ts(dataset_v5$Receita,  
           freq=4, #frequencia
           start=c(2012,01), #menor data possivel
           end = c(2018,04)) #maior data possivel

ts_treino <- ts(dataset_v5$Receita,  
                freq=4,
                start=c(2012,01),
                end = c(2017,04))

ts_teste <- ts(dataset_v5$Receita,  
               freq=4,
               start=c(2018,01), 
               end = c(2018,04))

#-------------------------------------------------------------
# Analise dos componentes de uma serie temporal.
plot(decompose(ts_treino))


# modelo 1 - baseline para Time Series Linear Model
ts_baseline <- tslm(ts_treino ~ season + trend  )
summary(ts_baseline)
hist(ts_baseline$residuals)

# Resultados baseline
# p-value: < 0.00000000000000022
# Adjusted R-squared:  0.9804 
# residuals não atigem a distribicao normal

# É Importante notar que o componente sazonal não esta ajudando.

#-------------------------------------------------------------
# modelo 2 - Serie temporal removendo o componente sazonal 

ts_modelo2 <- tslm(ts_treino ~ trend )

summary(ts_modelo2)
hist(ts_modelo2$residuals)
mean(ts_modelo2$residuals)

resid(ts_modelo2)
qqnorm(resid(ts_modelo2))
qqline(resid(ts_modelo2))

# Resultados modelo 2
# p-value: < 0.00000000000000022
# Adjusted R-squared:  0.9827 ate 1
# residuals estão distantes de uma distribicao normal 

#-------------------------------------------------------------
# modelo 3 - Serie temporal com normalização dos dados de entrada
# e sem componente sazonal

ts_treino <- ts(log(dataset_v5$Receita),  
                freq=4,
                start=c(2012,01), #menor data possivel
                end = c(2017,04))

ts_modelo3 <- tslm(ts_treino ~ trend, lambda = "auto" )

summary(ts_modelo3)
hist(ts_modelo3$residuals)
mean(ts_modelo3$residuals)

qqnorm(resid(ts_modelo3))
qqline(resid(ts_modelo3))

#modelo 3 - Previsão do modelo 3
ts_previsao3 <- forecast(ts_modelo3,  h=4)

autoplot(ts_previsao3)

resultado_modelo3<-exp(ts_previsao3$mean)
teste <- subset(dataset_v5$Receita, dataset_v5$Ano =="2018")

accuracy(resultado_modelo3,teste)


# Resultados modelo 3
# p-value:  0.00000000000000022
# Adjusted R-squared:  0.9986
# residuals quase forma uma distribicao normal
# SCORE MAPE: 2.303659
#-------------------------------------------------------------

#-------------------------------------------------------------
# modelo 4 - Serie temporal multipla e sem componente sazonal. 
# Adicionamos a coluna divida como uma variavél auxiliar.
#
# cor(dataset_v5$Receita, dataset_v5$Divida) ## 0.9501774

ts_treino <- ts(dataset_v5$Receita,  
                freq=4,
                start=c(2012,01), #menor data possivel
                end = c(2017,04))

ts_treino_As <- ts(dataset_v5$Divida,  
                freq=4,
                start=c(2012,01), #menor data possivel
                end = c(2017,04))

ts_teste_As <- ts(dataset_v5$Divida,  
                freq=4,
                start=c(2018,01), #menor data possivel
                end = c(2018,04))

ts_modelo4 <- tslm(ts_treino ~ trend + ts_treino_As, lambda = "auto")


summary(ts_modelo4)
hist(ts_modelo4$residuals)
mean(ts_modelo4$residuals)

qqnorm(resid(ts_modelo4))
qqline(resid(ts_modelo4))

#modelo 4 - Previsão
ts_previsao4 <- forecast(ts_modelo4, newdata = ts_teste_As , h=4)

autoplot(ts_previsao4)

resultado_modelo4<-ts_previsao4$mean

accuracy(resultado_modelo4,teste)
accuracy(resultado_modelo3,teste)

# Resultados modelo 4
# p-value:  0.00000000000000022
# Adjusted R-squared:  0.9986
# residuals quase forma uma distribicao normal
# SCORE MAPE: 7.697567
#-------------------------------------------------------------
#
# Vemos que o modelo 3 teve um resultado MAPE melhor que o modelo 4 em todas as 
# metricas, principalmente a nossa metrica escolhida (MAPE)
#
# Assim vamos estimar a receita da Netflix para 2019 usando esse modelo e 
# posteriormente, comparar com o modelo de regressão.

ts_2019 <- ts(log(dataset_v5$Receita),  
         freq=4, #frequencia
         start=c(2012,01), #menor data possivel
         end = c(2018,04)) #maior data possivel

ts_modelo5 <- tslm(ts_2019 ~ trend, lambda = "auto" )

summary(ts_modelo5)
hist(ts_modelo5$residuals)
mean(ts_modelo5$residuals)

qqnorm(resid(ts_modelo5))
qqline(resid(ts_modelo5))

#Notamos uma redução R-squared: 0.7377. 
#Provavelmente tinhamos poucos dados de treinamento na serie

#modelo 5 - Previsão do modelo 5
ts_previsao5 <- forecast(ts_modelo5,  h=4)

autoplot(ts_previsao3)

resultado_modelo5<-exp(ts_previsao5$mean)

sum(resultado_modelo5)
# Os resultados para os proximos 4 trimestres de receita da netflix são:
#         Qtr1    Qtr2    Qtr3    Qtr4
#   2019 2142540 2249319 2361040 2477914 (in thousands)
#  
#  ou um Total de 9,230,812 (in thousands)