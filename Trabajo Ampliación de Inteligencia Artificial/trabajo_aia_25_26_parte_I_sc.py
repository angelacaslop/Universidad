#!/usr/bin/env python3
# -*- coding: utf-8 -*-
 
# ===================================================================
# Ampliación de Inteligencia Artificial, 2025-26
# PARTE I del trabajo práctico: Implementación de árboles de decisión 
#                               y random forests
# Dpto. de CC. de la Computación e I.A. (Univ. de Sevilla)
# ===================================================================


# --------------------------------------------------------------------------
# Autor(a) del trabajo:
#
# APELLIDOS: García Muñoz
# NOMBRE: Adrián
#
# Segundo(a) componente (si se trata de un grupo):
#
# APELLIDOS: Castilla López
# NOMBRE: Ángela
# ----------------------------------------------------------------------------


import math
import random
import numpy as np


from carga_datos import *    



def particion_entr_prueba(X, y, test=0.20):

    clases_unicas = np.unique(y)
    indices_train = []
    indices_test = []
    
    for clase in clases_unicas:    
        indices = np.where(y == clase)[0]
        
        sel = random.sample(list(indices), len(indices)) 

        n_test = int(len(indices) * test)
        n_train = len(indices) - n_test
        
        indices_train.extend(sel[:n_train])  
        indices_test.extend(sel[n_train:])
    
    indices_train.sort()  
    indices_test.sort()
    
    X_train, y_train = X[indices_train], y[indices_train]      
    X_test, y_test = X[indices_test], y[indices_test]
    
    return X_train, X_test, y_train, y_test



class Nodo:
    def __init__(self, atributo=None, umbral=None, izq=None, der=None,distr=None,clase=None):
        self.atributo = atributo
        self.umbral = umbral
        self.izq = izq
        self.der = der
        self.distr= distr
        self.clase = clase
        
    def es_hoja(self):
        return self.clase is not None

class ClasificadorNoEntrenado(Exception): pass

        
    
def rendimiento(clasif,X,y):
    return sum(clasif.clasifica(X)==y)/X.shape[0]
    


def entropy(y): 
    _, counts = np.unique(y, return_counts=True)
    probs = counts / counts.sum()
    return -np.sum([p * math.log2(p) for p in probs if p > 0])
    
def sel_best_atributo_umbral(X,y,atributos, prop_umbral):
    H = entropy(y)
    atrib_val_ig_list=[]
    best_atrib, best_umbral = None, None
    for i in atributos:
        ig_dict = {}
        prop = random.sample(range(0, X.shape[0]), k = math.floor(X.shape[0]*prop_umbral))
        X_aux = X[prop]
        y_aux = y[prop]
        indices = np.argsort(X_aux[:,i]) 
        atrib_column = X_aux[:, i][indices]
        y_sorted = y_aux[indices]
        values = []
        for t in range(0, X_aux.shape[0]-1): 
            if not(atrib_column[t] == atrib_column[t+1]): 
                if not(y_sorted[t] == y_sorted[t+1]): 
                    v = (atrib_column[t] + atrib_column[t+1])/2
                    values.append(v)
        for val in values:

            yleft = y[X[:, i]<=val]
            Hleft = entropy(yleft)
            yright = y[X[:, i]>val]
            Hright = entropy(yright)

            n = len(y)
            nleft = len(yleft)
            nright = len(yright)

            if nleft == 0 or nright == 0:
                continue

            ig = H - (nleft / n) * Hleft - (nright / n) * Hright

            ig_dict[val] = ig  
        if not ig_dict: 
            continue
        umbral, info_gain = max(ig_dict.items(), key=lambda kv: kv[1])
        atrib_val_ig_list.append((i, umbral, info_gain)) 

    if not atrib_val_ig_list: 
        return None, None
    
    best_atrib, best_umbral, _ = max(atrib_val_ig_list, key=lambda x:x[2])  

    return best_atrib, best_umbral


class ArbolDecision:
    def __init__(self, min_ejemplos_nodo_interior=5, max_prof=10,n_atrs=10,prop_umbral=1.0):
        self.min_ejemplos_nodo_interior = min_ejemplos_nodo_interior
        self.max_prof = max_prof
        self.n_atrs = n_atrs
        self.prop_umbral = prop_umbral
        self.atributos = None  
        self.raiz = None      
    

    def construye_arbol(self, X, y, min_ejemplos_nodo_interior, max_prof, prof=0):
        distr = {c: (y == c).sum() for c in np.unique(y)}  
        clase_mayoritaria=max(distr, key=distr.get)   
        if prof >= max_prof or len(X) < min_ejemplos_nodo_interior or len(np.unique(y)) == 1: 
            return Nodo(None, None, None, None, distr, clase_mayoritaria)
        else:
            best_atrib, best_umbral = sel_best_atributo_umbral(X,y, self.atributos, self.prop_umbral)  
            if best_atrib is None or best_umbral is None: 
                return Nodo(None, None, None, None, distr, clase_mayoritaria)
            mask = X[:, best_atrib] <= best_umbral
            X_izq, y_izq = X[mask], y[mask] 
            X_der, y_der = X[~mask], y[~mask]
            if len(y_izq) == 0 or len(y_der) == 0: 
                return Nodo(None, None, None, None, distr, clase_mayoritaria)  
            A_izq = self.construye_arbol(X_izq, y_izq, min_ejemplos_nodo_interior, max_prof, prof+1) 
            A_der = self.construye_arbol(X_der, y_der, min_ejemplos_nodo_interior, max_prof, prof+1) 
            return Nodo(best_atrib, best_umbral, A_izq, A_der, distr, None)     

               
    def entrena(self, X, y):    # Entrena el árbol
        self.atributos = random.sample(range(0, X.shape[1]), self.n_atrs)
        self.raiz = self.construye_arbol(X,y,self.min_ejemplos_nodo_interior, self.max_prof)  


    def clasifica(self, X):
        if self.raiz == None:  
            raise ClasificadorNoEntrenado("El árbol no ha sido entrenado aún.")
        return [self.clasifica_aux(x, self.raiz).clase for x in X]
    

    def clasifica_prob(self, x):    
        if self.raiz == None:
            raise ClasificadorNoEntrenado("El árbol no ha sido entrenado aún.")
        distr = self.clasifica_aux(x, self.raiz).distr
        total = sum(distr.values())
        return {k : v / total for k, v in distr.items()}
    
    def clasifica_aux(self, x, nodo): 
        atributo = nodo.atributo
        umbral = nodo.umbral
        if nodo.clase == None:    
            if x[atributo] <= umbral:
                return self.clasifica_aux(x, nodo.izq)
            else:
                return self.clasifica_aux(x, nodo.der)
        else:
            return nodo



    def imprime_arbol(self,nombre_atrs,nombre_clase):
        if self.raiz == None:
            raise ClasificadorNoEntrenado("El árbol no ha sido entrenado aún.")
        return self.imprime_arbol_aux(nombre_atrs, nombre_clase, self.raiz, 0)
    
    def imprime_arbol_aux(self, nombre_atrs, nombre_clase, nodo, prof):
        espacio = "     "
        if not(nodo.atributo == None):
            print(espacio*prof + nombre_atrs[nodo.atributo] + " <= " + str(nodo.umbral))
            self.imprime_arbol_aux(nombre_atrs, nombre_clase, nodo.izq, prof+1)
            print(espacio*prof + nombre_atrs[nodo.atributo] + " > " + str(nodo.umbral))
            self.imprime_arbol_aux(nombre_atrs, nombre_clase, nodo.der, prof+1)
        else:
            distr_str = {str(k): str(v) for k, v in nodo.distr.items()}
            print(espacio*(prof+1) + nombre_clase + ": " + str(nodo.clase) + " -- " + str(distr_str))
        


class RandomForest:
    def __init__(self, n_arboles=5, min_ejemplos_nodo_interior=5, max_prof=10,n_atrs=10,prop_umbral=1.0):
        self.n_arboles = n_arboles
        self.min_ejemplos_nodo_interior = min_ejemplos_nodo_interior
        self.max_prof = max_prof
        self.n_atrs = n_atrs
        self.prop_umbral = prop_umbral
        self.arboles = [] 

    
    def entrena(self, X, y):
        for _ in range(0, self.n_arboles): 
            arbol = ArbolDecision(self.min_ejemplos_nodo_interior, self.max_prof, self.n_atrs, self.prop_umbral)
            indices = random.choices(range(0, X.shape[0]), k = math.floor(X.shape[0]*self.prop_umbral)) 
            X_muestra = X[indices]
            y_muestra = y[indices]
            arbol.entrena(X_muestra,y_muestra)
            self.arboles.append(arbol) 
    
    def clasifica(self, X):
        res = []
        for x in X:
            predicciones = {} 
            for arbol in self.arboles:
                clase = arbol.clasifica([x])[0]
                if clase not in predicciones:
                    predicciones[clase] = 1
                else:
                    predicciones[clase] += 1
            res.append(max(predicciones, key=predicciones.get))
        return res


from sklearn.preprocessing import OrdinalEncoder
import pandas as pd

encoder_X_credito = OrdinalEncoder(handle_unknown="use_encoded_value", unknown_value=-1)  

X_train_raw_credito, X_test_raw_credito, y_train_credito, y_test_credito = particion_entr_prueba(X_credito, y_credito, 1/3) 

X_train_credito = encoder_X_credito.fit_transform(X_train_raw_credito)
X_test_credito = encoder_X_credito.transform(X_test_raw_credito)



df = pd.read_csv("datos/adultDataset.csv")
encoder_X_adult = OrdinalEncoder(handle_unknown="use_encoded_value", unknown_value=-1) 

y_adult = df.iloc[:, -1].values 
X_adult = df.iloc[:, :-1].values  

X_train_raw_adult,  X_test_raw_adult, y_train_adult, y_test_adult = particion_entr_prueba(X_adult, y_adult, 1/3) 

X_train_adult_encoded = encoder_X_adult.fit_transform(X_train_raw_adult[:, range(4, X_adult.shape[1])]) 
X_train_raw_adult[:, range(4, X_adult.shape[1])] = X_train_adult_encoded

X_test_adult_encoded = encoder_X_adult.transform(X_test_raw_adult[:, range(4, X_adult.shape[1])])
X_test_raw_adult[:, range(4, X_adult.shape[1])] = X_test_adult_encoded

X_train_adult = X_train_raw_adult
X_test_adult = X_test_raw_adult



def leer_imagenes(fichero): 
    lineas = []
    with open(fichero) as f:
        lineas = f.readlines()
    imagenes = []
    imagen = []
    counter = 0
    for linea in lineas:
        for caracter in linea:
            if caracter == " ":
                imagen.append(0)
                counter += 1
            elif caracter == "+" or caracter == "#":
                imagen.append(1)
                counter += 1
        if counter == 784:
            imagenes.append(imagen)
            imagen = []
            counter = 0
    return np.array(imagenes)


def leer_etiquetas(fichero): 
    lineas = []
    with open(fichero) as f:
        lineas = f.readlines()
    etiquetas = []
    for linea in lineas:
        etiquetas.append(int(linea))
    return np.array(etiquetas)

X_train_dg = leer_imagenes("datos/digitdata/trainingimages")
y_train_dg = leer_etiquetas("datos/digitdata/traininglabels")
X_valid_dg = leer_imagenes("datos/digitdata/validationimages")
y_valid_dg = leer_etiquetas("datos/digitdata/validationlabels")
X_test_dg = leer_imagenes("datos/digitdata/testimages")
y_test_dg = leer_etiquetas("datos/digitdata/testlabels")


trainX = [X_train_imdb, X_train_credito, X_train_adult, X_train_dg]
trainy = [y_train_imdb, y_train_credito, y_train_adult, y_train_dg]
testX = [X_test_imdb, X_test_credito, X_test_adult, X_test_dg]
testy = [y_test_imdb, y_test_credito, y_test_adult, y_test_dg]

mejores_params_list = []   # Lista con los mejores parámetros
accs = []   # Lista con los rendimientos de los parámetros anteriores

def buscar_params():    # Entrena varios bosques y se queda con el que mejor rendimiento tenga
    for o in range(len(trainX)):

        param_grid = {
            "n_arboles": [5, 10, 20],
            "min_ejemplos_nodo_interior": [2, 5, 10],
            "max_prof": [10, 20, 30],
            "n_atrs": [
                int(np.sqrt(trainX[o].shape[1])),
                trainX[o].shape[1] // 2,
                trainX[o].shape[1]
            ],
            "prop_umbral": [0.5, 0.7, 1.0]
        }

        mejor_acc = 0
        mejores_params = None

        for _ in range(10):
            params = {
                "n_arboles": random.choice(param_grid["n_arboles"]),
                "min_ejemplos_nodo_interior": random.choice(param_grid["min_ejemplos_nodo_interior"]),
                "max_prof": random.choice(param_grid["max_prof"]),
                "n_atrs": random.choice(param_grid["n_atrs"]),
                "prop_umbral": random.choice(param_grid["prop_umbral"])
            }
            bosque = RandomForest(
                n_arboles=params["n_arboles"],
                min_ejemplos_nodo_interior=params["min_ejemplos_nodo_interior"],
                max_prof=params["max_prof"],
                n_atrs=params["n_atrs"],
                prop_umbral=params["prop_umbral"])           
            bosque.entrena(trainX[o], trainy[o])
            acc = rendimiento(bosque, testX[o], testy[o])

            if acc > mejor_acc:
                mejor_acc = acc
                mejores_params = params

        mejores_params_list.append(mejores_params)
        accs.append(acc)


strs = ["IMDB:", "Crédito:", "Adult:", "DG:"]

def imprimir_params():
    for s in range(len(mejores_params_list)):
        print(strs[s], mejores_params_list[s], accs[s])
        print("----------------------------")



# El ARCHIVO trabajo_aia_23_24_parte_I_sc.py SERÁ CARGADO POR EL PROFESOR, 
# TENIENDO EN LA MISMA CARPETA LOS ARCHIVOS OBTENIDOS
# DESCOMPRIMIENDO datos_trabajo_aia.zip.
# ES IMPORTANTE QUE LO QUE SE ENTREGA SE PUEDA CARGAR SIN ERRORES Y QUE SE EJECUTEN LOS 
# EJEMPLOS QUE VIENEN A CONTINUACIÓN. SI ALGUNO DE LOS EJERCICIOS NO SE HA REALIZADO 
# O DEVUELVE ALGÚN ERROR, DEJAR COMENTADOS LOS CORRESPONDIENTES EJEMPLOS, 
# PARA EViTAR LOS ERRORES EN LA CARGA Y EJECUCIÓN.   



# *********** DESCOMENTAR A PARTIR DE AQUÍ

print("************ PRUEBAS EJERCICIO 1:")
print("**********************************\n")
Xe_votos,Xp_votos,ye_votos,yp_votos=particion_entr_prueba(X_votos,y_votos,test=1/3)
print("Partición votos: ",y_votos.shape[0],ye_votos.shape[0],yp_votos.shape[0])
print("Proporción original en votos: ",np.unique(y_votos,return_counts=True))
print("Estratificación entrenamiento en votos: ",np.unique(ye_votos,return_counts=True))
print("Estratificación prueba en votos: ",np.unique(yp_votos,return_counts=True))
print("\n")

Xev_cancer,Xp_cancer,yev_cancer,yp_cancer=particion_entr_prueba(X_cancer,y_cancer,test=0.2)
print("Proporción original en cáncer: ", np.unique(y_cancer,return_counts=True))
print("Estratificación entr-val en cáncer: ",np.unique(yev_cancer,return_counts=True))
print("Estratificación prueba en cáncer: ",np.unique(yp_cancer,return_counts=True))
Xe_cancer,Xv_cancer,ye_cancer,yv_cancer=particion_entr_prueba(Xev_cancer,yev_cancer,test=0.2)
print("Estratificación entrenamiento cáncer: ", np.unique(ye_cancer,return_counts=True))
print("Estratificación validación cáncer: ",np.unique(yv_cancer,return_counts=True))
print("\n")

Xe_credito,Xp_credito,ye_credito,yp_credito=particion_entr_prueba(X_credito,y_credito,test=0.4)
print("Estratificación entrenamiento crédito: ",np.unique(ye_credito,return_counts=True))
print("Estratificación prueba crédito: ",np.unique(yp_credito,return_counts=True))
print("\n\n\n")





print("************ PRUEBAS EJERCICIO 2:")
print("**********************************\n")

clf_titanic = ArbolDecision(max_prof=3,min_ejemplos_nodo_interior=5,n_atrs=3)
clf_titanic.entrena(X_train_titanic, y_train_titanic)
clf_titanic.imprime_arbol(["Pclass", "Mujer", "Edad"],"Partido")
rend_train_titanic = rendimiento(clf_titanic,X_train_titanic,y_train_titanic)
rend_test_titanic = rendimiento(clf_titanic,X_test_titanic,y_test_titanic)
print(f"****** Rendimiento DT titanic train: {rend_train_titanic}")
print(f"****** Rendimiento DT titanic test: {rend_test_titanic}\n\n\n\n ")




clf_votos = ArbolDecision(min_ejemplos_nodo_interior=3,max_prof=5,n_atrs=16)
clf_votos.entrena(Xe_votos, ye_votos)
nombre_atrs_votos=[f"Votación {i}" for i in range(1,17)]
clf_votos.imprime_arbol(nombre_atrs_votos,"Partido")
rend_train_votos = rendimiento(clf_votos,Xe_votos,ye_votos)
rend_test_votos = rendimiento(clf_votos,Xp_votos,yp_votos)
print(f"****** Rendimiento DT votos en train: {rend_train_votos}")
print(f"****** Rendimiento DT votos en test:  {rend_test_votos}\n\n\n\n")



X_train_iris,X_test_iris,y_train_iris,y_test_iris=particion_entr_prueba(X_iris,y_iris,test=1/3)
clf_iris = ArbolDecision(max_prof=3,n_atrs=4)
clf_iris.entrena(X_train_iris, y_train_iris)
clf_iris.imprime_arbol(["Long. Sépalo", "Anch. Sépalo", "Long. Pétalo", "Anch. Pétalo"],"Clase")
rend_train_iris = rendimiento(clf_iris,X_train_iris,y_train_iris)
rend_test_iris = rendimiento(clf_iris,X_test_iris,y_test_iris)
print(f"********************* Rendimiento DT iris train: {rend_train_iris}")
print(f"********************* Rendimiento DT iris test: {rend_test_iris}\n\n\n\n ")





clf_cancer = ArbolDecision(min_ejemplos_nodo_interior=3,max_prof=10,n_atrs=15)
clf_cancer.entrena(Xev_cancer, yev_cancer)
nombre_atrs_cancer=['mean radius', 'mean texture', 'mean perimeter', 'mean area',
        'mean smoothness', 'mean compactness', 'mean concavity',
        'mean concave points', 'mean symmetry', 'mean fractal dimension',
        'radius error', 'texture error', 'perimeter error', 'area error',
        'smoothness error', 'compactness error', 'concavity error',
        'concave points error', 'symmetry error',
        'fractal dimension error', 'worst radius', 'worst texture',
        'worst perimeter', 'worst area', 'worst smoothness',
        'worst compactness', 'worst concavity', 'worst concave points',
        'worst symmetry', 'worst fractal dimension']
clf_cancer.imprime_arbol(nombre_atrs_cancer,"Es benigno")
rend_train_cancer = rendimiento(clf_cancer,Xev_cancer,yev_cancer)
rend_test_cancer = rendimiento(clf_cancer,Xp_cancer,yp_cancer)
print(f"***** Rendimiento DT cancer en train: {rend_train_cancer}")
print(f"***** Rendimiento DT cancer en test: {rend_test_cancer}\n\n\n")



print("************ RENDIMIENTOS FINALES RANDOM FOREST")
print("************************************************\n")


# ATENCIÓN: EN CADA CASO, INCORPORAR LA MEJOR COMBINACIÓN DE HIPERPARÁMETROS 
# QUE SE HA OBTENIDO EN EL PROCESO DE AJUSTE



print("==== MEJOR RENDIMIENTO RANDOM FOREST SOBRE IMDB:")
RF_IMDB=RandomForest(n_arboles=10, min_ejemplos_nodo_interior=2, max_prof=30,n_atrs=316,prop_umbral=1.0) # ATENCIÓN: incorporar aquí los mejores valoeres de los parámetros tras el ajuste
RF_IMDB.entrena(X_train_imdb,y_train_imdb) 
print("Rendimiento RF entrenamiento sobre imdb: ",rendimiento(RF_IMDB,X_train_imdb,y_train_imdb))
print("Rendimiento RF test sobre imdb: ",rendimiento(RF_IMDB,X_test_imdb,y_test_imdb))
print("\n")




print("==== MEJOR RENDIMIENTO RANDOM FOREST SOBRE CRÉDITO:")

RF_CREDITO=RandomForest(n_arboles=5, min_ejemplos_nodo_interior=5, max_prof=10,n_atrs=6,prop_umbral=0.5) # ATENCIÓN: incorporar aquí los mejores valores de los parámetros tras el ajuste
RF_CREDITO.entrena(X_train_credito,y_train_credito) 
print("Rendimiento RF entrenamiento sobre crédito: ",rendimiento(RF_CREDITO,X_train_credito,y_train_credito))
print("Rendimiento RF  test sobre crédito: ",rendimiento(RF_CREDITO,X_test_credito,y_test_credito))
print("\n")


print("==== MEJOR RENDIMIENTO RF SOBRE ADULT:")

RF_ADULT=RandomForest(n_arboles=20, min_ejemplos_nodo_interior=2, max_prof=20,n_atrs=6,prop_umbral=0.5) # ATENCIÓN: incorporar aquí los mejores valores de los parámetros tras el ajuste
RF_ADULT.entrena(X_train_adult,y_train_adult) 
print("Rendimiento RF  entrenamiento sobre adult: ",rendimiento(RF_ADULT,X_train_adult,y_train_adult))
print("Rendimiento RF  test sobre adult: ",rendimiento(RF_ADULT,X_test_adult,y_test_adult))
print("\n")


print("==== MEJOR RENDIMIENTO RL SOBRE DIGITOS:")
RF_DG=RandomForest(n_arboles=10, min_ejemplos_nodo_interior=2, max_prof=30,n_atrs=784,prop_umbral=1.0) # ATENCIÓN: incorporar aquí los mejores valors de losparámetros tras el ajuste
RF_DG.entrena(X_train_dg,y_train_dg)
print("Rendimiento RF entrenamiento sobre dígitos: ",rendimiento(RF_DG,X_train_dg,y_train_dg))
print("Rendimiento RF validación sobre dígitos: ",rendimiento(RF_DG,X_valid_dg,y_valid_dg))
print("Rendimiento RF test sobre dígitos: ",rendimiento(RF_DG,X_test_dg,y_test_dg))

