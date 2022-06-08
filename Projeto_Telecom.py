# -*- coding: utf-8 -*-
"""
Created on Thu Apr 21 17:36:28 2022

@author: marcelo
"""
#########################################################################
# Carga dos pacotes
import os
import numpy as np
import pandas as pd
# Import label encoder
from sklearn import preprocessing

# Import Random Forest
from sklearn.ensemble import ExtraTreesClassifier

# Import modelo regressão logistica
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score

# Import ferramentas de preprocessamento
from sklearn.preprocessing import MinMaxScaler
from sklearn.preprocessing import StandardScaler

# Import feature sellections
from sklearn.decomposition import PCA
from sklearn.feature_selection import RFE
from sklearn.feature_selection import SelectKBest
from sklearn.feature_selection import chi2

# Import metricas de desempenho
from sklearn import metrics

# Import analise exploratoria
import seaborn as sns
import matplotlib.pyplot as plt

import warnings
warnings.filterwarnings("ignore")

#########################################################################

os.getcwd()
os.chdir('C:\\Users\\marcelo\\Desktop\\Python\\Big-Data-Real-Time-Analytics-com-Python-e-Spark\\Projeto 4')

arq_treino = pd.read_csv('projeto4_telecom_treino.csv',index_col=0) #ignora a primeira coluna

# Analise dataset

print(arq_treino.shape)

arq_treino.head(5)
arq_treino.info()
arq_treino.describe()

# tipo de dados
arq_treino.dtypes

# Valores distintos para columnas do tipo string
print(arq_treino['area_code'].unique())
print(arq_treino['international_plan'].unique())
print(arq_treino['voice_mail_plan'].unique())
print(arq_treino['churn'].unique())
print(arq_treino['state'].unique())

# Cria função para ajustar o dataframe
def ajuste_df (df):
    # Limpa e comverte columnas do tipo string para float
    df['area_code'] = df['area_code'].str.replace('area_code_','').astype(float)
    df['international_plan'] = df['international_plan'].str.replace('no','0').str.replace('yes','1').astype(float)
    df['voice_mail_plan'] = df['voice_mail_plan'].str.replace('no','0').str.replace('yes','1').astype(float)
    df['churn'] = df['churn'].str.replace('no','0').str.replace('yes','1').astype(float)
    
    # label encoding da coluna state
    # label_encoder object knows how to understand word labels.
    label_encoder = preprocessing.LabelEncoder()
    df['state'] = label_encoder.fit_transform(df['state'])
    return  df

# Aplica a função ajuste_df ao arquivo
treino = ajuste_df(arq_treino)
treino.dtypes

# Separando o dataset de treino e teste em componentes de input e output
X_treino = treino.iloc[:,0:19]
X_treino.head(10)
X_treino.info()

Y_treino = treino.iloc[:,19:]
Y_treino.head(10)

arq_teste = pd.read_csv('projeto4_telecom_treino.csv',index_col=0) #ignora a primeira coluna
arq_teste.dtypes

# ajusto o dataset de teste
teste = ajuste_df(arq_teste)

# Separando o dataset de teste e teste em componentes de input e output
X_teste = teste.iloc[:,0:19]
X_teste.head(5)

Y_teste = teste.iloc[:,19:]
Y_teste.head(5)

#########################################################################
# Analise exploratoria 
#########################################################################
#
# Busca por outliers
#-------------------------------------
#
# Removendo area_code, state, voice_mail_plan por representarem dados categoricos
# Removendo number_vmail_messages - não há outlier  

features = ["account_length","total_day_minutes","total_day_calls"
            ,"total_day_charge","total_eve_minutes","total_eve_calls","total_eve_charge"
            ,"total_night_minutes","total_night_calls","total_night_charge","total_intl_minutes"
            ,"total_intl_calls","total_intl_charge","number_customer_service_calls"]

# Parâmetros de configuração dos gráficos
from matplotlib import rcParams

rcParams['figure.figsize'] = 32, 8
rcParams['lines.linewidth'] = 3
rcParams['xtick.labelsize'] = 'xx-large'
rcParams['ytick.labelsize'] = 'xx-large'

for i in range(0, len(features)):
    plt.subplot(1, len(features), i + 1)
    sns.boxplot(y = X_treino[features[i]], color = 'magenta', orient = 'v')
    plt.tight_layout()

# Analise para distribuições - histogramas
#-------------------------------------

for i in range(0, len(features)):
    plt.subplot(4, len(features) , i+1)
    sns.histplot(x = X_treino[features[i]], kde = True, color = 'green')
    plt.xlabel(features[i])
    plt.tight_layout()

# Busca por correlações
#-------------------------------------

correlations = X_treino.corr()

sns.heatmap(correlations, annot=True)

#########################################################################
# Machine Learning - 
#########################################################################

# Criação do modelo com Regressão Logistica multiclass 

#  multi_class{‘auto’, ‘ovr’, ‘multinomial’}, default=’auto’
#  If the option chosen is ‘ovr’, then a binary problem is fit for each label. 
#  For ‘multinomial’ the loss minimised is the multinomial loss fit across the entire probability distribution,
#  even when the data is binary. ‘multinomial’ is unavailable when solver=’liblinear’. ‘auto’ selects ‘ovr’
#  if the data is binary, or if solver=’liblinear’, and otherwise selects ‘multinomial’.


#----------------------------------------------------------------------------
# Baseline modelo Regresão Logistica
#----------------------------------------------------------------------------

# Criação do modelo baseline
baseline = LogisticRegression( multi_class='ovr')

# Treinamento do modelo baseline
baseline.fit(X_treino, Y_treino)

# Predição nos dados de teste usando a função .predict
#?baseline.predict_proba
Y_pred = baseline.predict_proba(X_teste)

# Score do modelo nos dados de teste usando a função .score
resultado_baseline = baseline.score(X_teste, Y_teste)
print("Acurácia nos Dados de Teste - baseline: %.3f%%" % (resultado_baseline * 100.0))

# Matriz de confusão
#
#Y_pred = baseline.predict(X_teste) # Para o calculo da matriz de confusão
#
#cnf_matrix = metrics.confusion_matrix(Y_pred, Y_teste)
#cnf_matrix

#-----------------------------------------------
# Versão 1 Regresão Logistica - Dados normalizados
#-----------------------------------------------
# normalizando os dados de treino
# Gerando a nova escala (normalizando os dados)

scaler = MinMaxScaler(feature_range = (0, 1))
rescaledX = scaler.fit_transform(X_treino)
#rescaledX[0:5,:]

# Criação do modelo normalizado
modelo_Normalizado = LogisticRegression( multi_class='ovr')

# Treinamento do modelo
modelo_Normalizado.fit(rescaledX, Y_treino)

# Normalização dos dados de teste
rescaledX_test = scaler.fit_transform(X_teste)
#rescaledX_test[0:5,:]

# predict a multinomial probability distribution
pred_Normalizado = modelo_Normalizado.predict_proba(rescaledX_test)

# summarize the predicted probabilities PARA CADA ELEMENTO DA LISTA
#print('Predicted Probabilities: %s' % pred_Normalizado[0])

# Score do modelo nos dados de teste usando a função .score
result_Scaled = modelo_Normalizado.score(rescaledX_test, Y_teste)
print("Acurácia nos Dados de Teste com a mesma escala (normalizados): %.3f%%" % (result_Scaled * 100.0))

#-----------------------------------------------
# Versão 2 Regresão Logistica - Dados padronizados
#-----------------------------------------------
# padroniza os dados de treino
scaler = StandardScaler().fit(X_treino)
standardX_treino = scaler.transform(X_treino)
#standardX_treino[0:5,:]

modelo_Padronizado = LogisticRegression( multi_class='ovr')

# Treinamento do modelo padronizado
modelo_Padronizado.fit(standardX_treino, Y_treino)

# Padronização dos dados de teste
standardX_teste = scaler.transform(X_teste)

# predict a multinomial probability distribution
pred_Padronizado = modelo_Padronizado.predict_proba(standardX_teste)

# summarize the predicted probabilities PARA CADA ELEMENTO DA LISTA
#print('Predicted Probabilities: %s' % pred_Padronizado[0])

# Score do modelo nos dados de teste usando a função .score
result_Standard = modelo_Padronizado.score(standardX_teste, Y_teste)
print("Acurácia nos Dados de Teste Padronizados: %.3f%%" % (result_Standard * 100.0))

#-----------------------------------------------
# Versão 3 Regresão Logistica - Feature Selection + Dados normalizados
#-----------------------------------------------
# Criação do Modelo - Feature Selection (Random Forest)
ranking_score = ExtraTreesClassifier()

# Aplicação do modelo para os dados Normalizados
ranking_score.fit(rescaledX, Y_treino)

# Print dos Resultados
print(X_treino.columns[0:19])
print(ranking_score.feature_importances_)

# Top 8 melhores variaveis
# total_day_charge, total_day_minutes, number_customer_service_calls, 
# international_plan, total_eve_charge, total_eve_minutes, total_intl_calls
# total_night_charge

ranking_select = ['total_day_charge', 'total_day_minutes', 'number_customer_service_calls',
                  'international_plan', 'total_eve_charge', 'total_eve_minutes', 'total_intl_calls'
                  'total_night_charge']

X_treino_selected = scaler.fit_transform(X_treino[['total_day_charge', 'total_day_minutes', 'number_customer_service_calls',
                  'international_plan', 'total_eve_charge', 'total_eve_minutes', 'total_intl_calls',
                  'total_night_charge']])

# Criação do modelo Feature Selection + dados normalizados
modelo_Feature_Selc = LogisticRegression( multi_class='ovr')

# Treinamento do modelo
modelo_Feature_Selc.fit(X_treino_selected, Y_treino)


# Aplico a normalização + Feature Selection nos dados de testes
X_teste_selected = scaler.fit_transform(X_teste[['total_day_charge', 'total_day_minutes', 'number_customer_service_calls',
                  'international_plan', 'total_eve_charge', 'total_eve_minutes', 'total_intl_calls',
                  'total_night_charge']])

X_teste_selected[0:5,:]

# predict a multinomial probability distribution
pred_Feature_Selc = modelo_Feature_Selc.predict_proba(X_teste_selected)

# Score do modelo nos dados de teste usando a função .score
result_Feature = modelo_Feature_Selc.score(X_teste_selected, Y_teste)
print("Acurácia nos Dados de Teste com a mesma escala (Após feature Selection): %.3f%%" % (result_Scaled * 100.0))

#-----------------------------------------------
# Versão 4 Regresão Logistica - PCA + dados normalizados
#-----------------------------------------------

# Seleção de atributos
pca = PCA(n_components = 3)

fit_pca = pca.fit(rescaledX)

print("Variância: %s" % fit_pca.explained_variance_ratio_)
print(fit_pca.components_)

df_pca  = pd.DataFrame(fit_pca.transform(rescaledX)  )
df_pca.head()

# Criação do Modelo - PCA com dados normalizados
modelo_PCA = LogisticRegression( multi_class='ovr')

# Aplicação do modelo para os dados Normalizados
modelo_PCA.fit(df_pca, Y_treino)

# Aplico o PCA nos dados de teste
df_pca_test = pd.DataFrame(fit_pca.transform(rescaledX_test))
df_pca.head()

# predict a multinomial probability distribution
pred_PCA = modelo_PCA.predict_proba(df_pca_test)

# Score do modelo nos dados de teste usando a função .score
result_PCA = modelo_PCA.score(df_pca_test, Y_teste)
print("Acurácia nos Dados de Teste com a mesma escala (Após a redução de dimensionalidade): %.3f%%" % (result_PCA * 100.0))

#-----------------------------------------------
# Versão 5 Regresão Logistica - Grid Search Parameter + modelo normalizado
#-----------------------------------------------
#
# Este método realiza metodicamente combinações
# entre todos os parâmetros do algoritmo, criando um grid.
# Definindo os valores que serão testados
from sklearn.model_selection import GridSearchCV

valores_grid = {'penalty': ['l1','l2'], 'C': [0.001,0.01,0.1,1,10,100,1000], 
                'max_iter':[5,10,12,15,25,30,45,50,75,100,200,500]}

# Criando o grid
grid = GridSearchCV(estimator = modelo_Normalizado, param_grid = valores_grid)
grid.fit(rescaledX_test, Y_teste)

# Print do resultado
print("Acurácia: %.3f" % (grid.best_score_ * 100))
print("Melhores Parâmetros do Modelo:\n", grid.best_estimator_)

# Resultados

# 0.855985598559856 - baseline
# 0.8637863786378638 - dados normalizados
# 0.8628862886288629 - dados padronizados
# 0.8550855085508551 - modelo com redução da dimensionalidade (PCA) + dados normalizados
# 0.8577857785778578 - Feature selection + dados normalizados