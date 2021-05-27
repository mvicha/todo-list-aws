Este pipeline se utiliza para integrar los pipelines de dev, staging y prod. Desde aquí hacemos una llamada a los distintos pipelines, y al terminar la ejecución de manera correcta los cambios se mergean y pushean al repositorio siguiente.

De esta manera el funcionamiento sería el siguiente:

1) Build de Dev
  - En caso de fallo el pipeline se interrumpe

* En caso de que el pipeline de Dev haya finalizado correctamente se continúa

2) Merge de Dev en Staging
3) Push de Staging
4) Build de Staging
  - En caso de fallo el pipeline se interrumpe

* En caso de que el pipeline de Staging haya finalizado correctamente se continúa

5) Merge de Staging en Producción
6) Push de Producción
7) Build de Producción
  - En caso de fallo el pipeline se interrumpe

8) Limpieza del entorno
