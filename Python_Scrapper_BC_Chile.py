# -*- coding: utf-8 -*-
"""
Created on Mon Mar  8 14:38:26 2021

@author: mpimentel
"""
import os
import sys
import pyodbc
import pandas as pd
import numpy as np
import requests
from bs4 import BeautifulSoup
import time
from time import sleep

from selenium import webdriver
from selenium.webdriver.common.keys import Keys

from selenium.webdriver.firefox.options import Options

from selenium.webdriver.common.by import By

import io
from io import StringIO 

#pd.__version__
#np.__version__
#pd.show_versions()

# Descarga Tasa de IPC - Mensual
def descarga_IPC_bySellenium():

    # Sellenium - Emulating the Webpage    
    # Start WebDriver
    global driver
    
    # Start firefox webdriver
    options = Options()
    options.add_argument("--disable-infobars")
    driver = webdriver.Firefox(options=options)

    try:
        #Execute the WebDriver
        driver.get("https://si3.bcentral.cl/Bdemovil/BDE/Series/MOV_SC_PR1?nombreItem=IPC%2C%20variaci%C3%B3n%20mensual&nombrePadre=Series%20m%C3%A1s%20consultadas&idPadre=x&parametroMenu=Index&idMenuTree=MS2")
        time.sleep(7)
        element = driver.find_element_by_xpath('//*[@id="viewAllData"]')
        element.click()
        time.sleep(3)
    except:
       return print("Problemas con la descarga de la la data de Inflacion")

    # Extracting datatable from website
    container = driver.find_element(By.ID,'datosSeries').text
    
    # Converting to a pandas dataframe
    data = io.StringIO(container)
    df = pd.read_csv(data, header=None, sep="\n")
    
    #Dataframe transformation
    df['Periodo'] = df[0].str.split(' ').str[0]
    df['Inflacion'] = df[0].str.split(' ').str[1]
    df.columns = ['Original','Periodo', 'Inflacion']
    df.drop(columns='Original', inplace=True, axis=1)

    try:
        #connect to database
        connection = pyodbc.connect(driver='{SQL Server Native Client 11.0}', 
                                server='Hostname', database='db', 
                                trusted_connection='yes', autocommit=True)
        cursor = connection.cursor()
        
        #clear table
        cursor.execute("TRUNCATE TABLE [db].[dbo].[Tasa_Inflacion]")   
    
        # Insert Dataframe into Salcobrand Stage:
        for index, row in df.iterrows():
            cursor.execute("INSERT INTO [db].[dbo].[Tasa_Inflacion] (Periodo,Tasa_Inflacion) values(?,?)", row.Periodo, row.Inflacion)
        connection.commit()
        
        cursor.close()
    except:
       return print("Problemas con la connecion con la base de datos")
    # Release the drive
    driver.quit()
    
    return print("Carga de Datos IPC concluida")

# Descarga Tasa de Desocupación - Mensual
def descarga_Desocupacion_bySellenium():
    
    # Start WebDriver
    global driver
    
    # Start firefox webdriver
    options = Options()
    options.add_argument("--disable-infobars")
    driver = webdriver.Firefox(options=options)

    try:
        #Execute the WebDriver
        driver.get("https://si3.bcentral.cl/Bdemovil/BDE/Series/MOV_SC_ML3")
        time.sleep(7)
        element = driver.find_element_by_xpath('//*[@id="viewAllData"]')
        element.click()
        time.sleep(3)
    except:
       return print("Problemas con la descarga de la la data de Desocupación")

    # Extracting datatable from website
    container = driver.find_element(By.ID,'datosSeries').text
    
    # Converting to a pandas dataframe
    data = io.StringIO(container)
    df = pd.read_csv(data, header=None, sep="\n")
    
    #Dataframe transformation
    df['Periodo'] = df[0].str.split(' ').str[0]
    df['Desocupacion'] = df[0].str.split(' ').str[1]
    df.columns = ['Original','Periodo', 'Desocupacion']
    df.drop(columns='Original', inplace=True, axis=1)

    try:
        #connect to database
        connection = pyodbc.connect(driver='{SQL Server Native Client 11.0}', 
                                server='Hostname', database='db', 
                                trusted_connection='yes', autocommit=True)
        cursor = connection.cursor()
        
        #clear table
        cursor.execute("TRUNCATE TABLE [db].[dbo].[Tasa_Desocupacion]")   
    
        # Insert Dataframe into Salcobrand Stage:
        for index, row in df.iterrows():
            cursor.execute("INSERT INTO [db].[dbo].[Tasa_Desocupacion] (Periodo,Tasa_Desocupacion) values(?,?)", row.Periodo, row.Desocupacion)
        connection.commit()
        
        cursor.close()
    except:
       return print("Problemas con la connecion con la base de datos")
    # Release the drive
    driver.quit()
    
    return print("Carga de Datos Tasa de Desocupación concluida")


# Descarga Tasa de Desocupación - Mensual
def UF_bySellenium():
    
    # Start WebDriver
    global driver
    
    # Start firefox webdriver
    options = Options()
    options.add_argument("--disable-infobars")
    driver = webdriver.Firefox(options=options)

    try:
        #Execute the WebDriver
        driver.get("https://si3.bcentral.cl/Bdemovil/BDE/Series/MOV_SC_PR11")
        time.sleep(7)
        element = driver.find_element_by_xpath('//*[@id="viewAllData"]')
        element.click()
        time.sleep(3)
    except:
       return print("Problemas con la descarga de la la data de UF")

    # Extracting datatable from website
    container = driver.find_element(By.ID,'datosSeries').text
    
    # Converting to a pandas dataframe
    data = io.StringIO(container)
    df = pd.read_csv(data, header=None, sep="\n")
    
    #Dataframe transformation
    df['Periodo'] = df[0].str.split(' ').str[0]
    df['UF'] = df[0].str.split(' ').str[1]
    df.columns = ['Original','Periodo', 'UF']
    df.drop(columns='Original', inplace=True, axis=1)

    try:
        #connect to database
        connection = pyodbc.connect(driver='{SQL Server Native Client 11.0}', 
                                server='Hostname', database='db', 
                                trusted_connection='yes', autocommit=True)
        cursor = connection.cursor()
        
        #clear table
        cursor.execute("TRUNCATE TABLE [db].[dbo].[UF]")   
    
        # Insert Dataframe into Salcobrand Stage:
        for index, row in df.iterrows():
            cursor.execute("INSERT INTO [db].[dbo].[UF] (Periodo,UF) values(?,?)", row.Periodo, row.UF)
        connection.commit()
        
        cursor.close()
    except:
       return print("Problemas con la connecion con la base de datos")
    # Release the drive
    driver.quit()
    
    return print("Carga de Datos UF concluida")



if __name__ == "__main__":

    #Ejecuta el proceso de descarga

    #Descarga IPC
    descarga_IPC_bySellenium()

    #Descarga Desocupacion
    descarga_Desocupacion_bySellenium()

    #Descarga UF
    UF_bySellenium()
 

