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

???
eta = 1, depth = ?, nround = 200, pred: config1

???
eta = 0.5, depth = ?, nround = 200, pred: config1

???
eta = 0.1, depth = ?, nround = 200, pred: config1

???
eta = 0.02, depth = 9, nround = 200, pred: config1

???
eta = 0.02, depth = 7, nround = 200, pred: config1

0.962424+0.001257
eta = 0.02, depth = 5, nround = 200, pred: config1

0.961861+0.001497
eta = 0.02, depth = 4, nround = 200, pred: config1

0.960971+0.001642
eta = 0.02, depth = 3, nround = 200, pred: config1

0.959789+0.001169 
eta = 0.02, depth = 2, nround = 200, pred: config1

