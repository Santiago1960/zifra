# Problema: Endpoint categories not found

## Error
```
flutter: Error getting categories: 404
flutter: Response body: Endpoint categories not found
```

## Causa
El servidor Serverpod no tiene el endpoint `category` o `categories` registrado.

## Solución en el Servidor

1. Verificar que el archivo `category_endpoint.dart` existe en `server/lib/src/endpoints/`
2. Verificar que la clase se llama `CategoryEndpoint` y extiende `Endpoint`
3. Ejecutar `serverpod generate` en la carpeta del servidor
4. Reiniciar el servidor Serverpod

## URLs del Cliente (correctas)
- GET: `http://127.0.0.1:8080/categories/getCategories`
- POST: `http://127.0.0.1:8080/categories/addCategory`
- POST: `http://127.0.0.1:8080/categories/updateCategory`
- POST: `http://127.0.0.1:8080/categories/deleteCategory`

## Nota
El código del cliente está correcto. El problema es que el servidor no reconoce el endpoint.
