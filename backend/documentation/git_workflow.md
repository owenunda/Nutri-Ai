# Flujo de Trabajo con Git - NutriAI Backend

Este documento define el flujo de trabajo con Git para el backend de NutriAI.
El objetivo es mantener un código limpio, evitar conflictos y facilitar el trabajo en equipo.

---

## Estrategia de Ramas

Usamos un flujo basado en features con las siguientes ramas:

### `main`

* Código listo para producción
* Siempre debe estar estable
* Solo se actualiza mediante Pull Requests desde `dev`

---

### `dev`

* Rama de integración
* Aquí se unen todas las funcionalidades terminadas
* Se usa para pruebas antes de pasar a producción

---

### `feature/*`

* Ramas individuales por funcionalidad
* Se crean desde `dev`
* Una rama por cada card de Trello

Ejemplos:

```
feature/auth-register
feature/auth-login
feature/foods-crud
feature/fridge-module
feature/recipes-calories
```

---

## Flujo de Trabajo

### 1. Crear una rama nueva

Desde `dev`:

```bash
git checkout dev
git pull origin dev
git checkout -b feature/nombre-de-la-feature
```

---

### 2. Trabajar en la funcionalidad

* Hacer commits frecuentes
* Mantener cambios enfocados en una sola tarea

Ejemplo:

```bash
git commit -m "feat: implementar registro de usuario"
```

---

### 3. Subir la rama

```bash
git push origin feature/nombre-de-la-feature
```

---

### 4. Crear Pull Request (PR)

* Base: `dev`
* Describir qué se hizo
* Asignar a un compañero para revisión (oween) 

---

### 5. Revisión de código

Antes de hacer merge:

* El código debe funcionar
* Sin errores
* Respetar la arquitectura del proyecto
* Cumplir validaciones y reglas de negocio

---

### 6. Merge a `dev`

Una vez aprobado:

* Hacer merge a `dev`
* Eliminar la rama (recomendado)

---

### 7. Paso a producción (`main`)

Cuando `dev` esté estable:

```bash
git checkout main
git pull origin main
git merge dev
git push origin main
```

---

## Convención de Commits

Usar mensajes claros y consistentes:

```
feat: nueva funcionalidad
fix: corrección de error
refactor: mejora interna del código
docs: documentación
```

Ejemplos:

```
feat: login con JWT
fix: validación de calorías
refactor: optimizar servicio de alimentos
```

---

## Reglas Importantes

* No hacer push directo a `main`
* No trabajar directamente en `dev`
* Siempre usar ramas `feature/*`
* Siempre crear Pull Request
* Actualizar `dev` antes de empezar

---

## Sincronización diaria

Antes de empezar a trabajar:

```bash
git checkout dev
git pull origin dev
```

---

## Organización del equipo

* Cada desarrollador trabaja sus cards de Trello
* Una feature = una rama
* Comunicación constante
* Evitar trabajar en los mismos archivos sin coordinación

---

## Objetivo

* Código limpio
* Trabajo organizado
* Menos conflictos
* Proyecto escalable

---
