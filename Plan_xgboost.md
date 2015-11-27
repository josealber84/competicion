## Xgboost óptimo

### Parámetros a optimizar

**Eta** Factor de regularización/learning rate  
1 = sin regularización   
0 = regularización infinita  
Ajustar usando cross validation. Empieza con 0.1

**Number of Rounds** Número de árboles  
Ajustar usando cross validation. Empieza con unos 100 árboles.  

**Depth** Profundidad de los árboles.  
Rangos razonables: de 2 a 15. Empieza con un valor de 6.  

**Min child weight** ???  
Empieza con 1/sqrt(event rate)  

**colsample_bytree** ???  
De 0.3 a 0.5  

**subsampling** ???  
Déjalo a 1.0  

**gamma** ???  
Normalmente está bien dejarlo a 0  

---

**Predictors** features a considerar.  
Prueba a eliminar las features menos significativas o a cambiar el formato de algunas, o aplica PCA  

---

### Consejos

**Ejecuta varias veces el modelo con distintas semillas y haz la media de los resultados**

Si el modelo es muy simple (undefitting):
- Aumenta eta (menos regularización)
- Aumenta depth (más parámetros)
- Disminuye min_child_weight (???)

Si el modelo es muy complejo (overfitting):
- Disminuye eta (más regularización)
- Disminuye depth (menos parámetros)
- Aumenta min_child_weight (???)

http://www.slideshare.net/odsc/owen-zhangopen-sourcetoolsanddscompetitions1
http://www.slideshare.net/ShangxuanZhang/kaggle-winning-solution-xgboost-algorithm-let-us-learn-from-its-author


### Pruebas

*config1*: todas las features no-constantes, con fecha separada por año, mes, día y día de la semana. Todas las features escaladas y centradas.
 
0.9619 >> **eta = 0.01 eliminada**   
eta = 0.01, depth = 15, nrounds = 300, pred : config1  

0.958155+0.001192  ¡En 5 iteraciones!  
eta = 1, depth = 9, nround = 200, pred: config1  

0.961778+0.001039  ¡En 16 iteraciones!  
eta = 0.5, depth = 9, nround = 200, pred: config1  

0.964157+0.000872  ¡En 57 iteraciones!  
eta = 0.2, depth = 9, nround = 200, pred: config1  

0.965341+0.000813  
eta = 0.1, depth = 9, nround = 200, pred: config1  

0.965403+0.000948  
eta = 0.09, depth = 9, nround = 200, pred: config1  

> 0.965425+0.000814  
> eta = 0.08, depth = 9, nround = 200, pred: config1  

0.965310+0.000939  
eta = 0.06, depth = 9, nround = 200, pred: config1  

0.960880+0.001151  
eta = 0.02, depth = 9, nround = 200, pred: config1  

0.958547+0.001230  
eta = 0.02, depth = 7, nround = 200, pred: config1  

0.954671+0.001327  
eta = 0.02, depth = 5, nround = 200, pred: config1  

