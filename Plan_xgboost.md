## Xgboost óptimo

### Parámetros a optimizar

**Eta** factor de regularización.  
1 = sin regularización 
0 = regularización infinita

**Depth** número de árboles.
Rangos razonables: de 2 a 15

**Rounds** ???

**Predictors** features a considerar.
Prueba a eliminar las features menos significativas o a cambiar el formato de algunas, o aplica PCA

### Pruebas
config1: todas las features no-constantes, con fecha separada por año, mes, día y día de la semana.
 
0.9619 >> **eta = 0.01 eliminada** 
eta = 0.01, depth = 15, nrounds = 300, pred : config1

0.958155+0.001192  ¡En 5 iteraciones!
eta = 1, depth = 9, nround = 200, pred: config1

0.961778+0.001039  ¡En 16 iteraciones!
eta = 0.5, depth = 9, nround = 200, pred: config1

0.965341+0.000813
eta = 0.1, depth = 9, nround = 200, pred: config1

0.960880+0.001151
eta = 0.02, depth = 9, nround = 200, pred: config1

0.958547+0.001230
eta = 0.02, depth = 7, nround = 200, pred: config1

0.954671+0.001327
eta = 0.02, depth = 5, nround = 200, pred: config1

