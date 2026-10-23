# Proteger el webhook de NutriLife

El backend y el workflow comparten una clave para que una llamada directa al webhook no pueda ejecutar el chat sin pasar por la API.

1. Genera una clave larga y aleatoria y guárdala como `N8N_WEBHOOK_SECRET` en el entorno del backend (local y producción). No la dejes vacía ni reutilices una clave de ejemplo.
2. En n8n, crea una credencial **Webhook Auth** de tipo **Header Auth**. Configura el nombre del header como `X-NutriLife-Key` y el valor con la misma clave.
3. Importa `NutriLife - Chat de Recetas.json`, abre el nodo **Webhook: Mensaje de Chat**, selecciona esa credencial y guarda el workflow.
4. Activa el workflow y confirma que el backend tenga configurada la URL de producción correspondiente.

El archivo JSON define el nodo como autenticado por header, pero n8n guarda las credenciales en la instancia y no las exporta con el workflow. Por eso, seleccionar la credencial en la instancia es necesario para completar el cambio.
