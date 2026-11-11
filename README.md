# LarpWare: Motor de Sincronización y Bypass para Mendix (WSL)

**LarpWare** es una herramienta de alto rendimiento diseñada en entornos Linux/WSL para gestionar, respaldar y sincronizar proyectos de Mendix (`.mpr`) directamente a nivel de base de datos SQLite mediante **LuaJIT FFI**, evitando la sobrecarga y la interfaz gráfica de Mendix Studio Pro.

---

## 🚀 Características Principales

* **Sincronización Nativa por Kernel (`inotify`):** Monitoreo de cambios en tiempo real en el árbol de directorios con consumo de CPU cercano a cero, utilizando llamadas directas a las APIs del kernel de Linux mediante FFI.
* **Manipulación Directa del `.mpr` (SQLite):** Operaciones CRUD avanzadas e inteligentes (`UPSERT`) ejecutadas directamente sobre el archivo de proyecto SQLite subyacente.
* **Gestión Segura de Tipos Binarios (`BLOB`):** Conversión estricta y validación defensiva de identificadores `UnitID` y `ContainerID` en formato binario de 16 bytes (`X'...'`), previniendo corrupción de modelos y el error de formato `.NET` (*Unrecognized Guid format*).
* **Control de Asincronía y Concurrencia:** Procesamiento ligero basado en corutinas, caché de marcas de tiempo (`mtime`) y control de *debounce* para evitar ráfagas de escritura durante la edición local.

---

## 📦 Dependencias y Prerrequisitos

Para compilar el entorno y ejecutar los scripts basados en LuaJIT FFI en WSL (Ubuntu/Debian), necesitas instalar los siguientes paquetes del sistema:

`bash
sudo apt update
sudo apt install -y build-essential luajit libluajit-5.1-dev libsqlite3-dev sqlite3
`

---

## 🛠️ Estructura del Proyecto

* **`bypass`**: Script principal de control CLI para realizar `status`, `dump` (volcado estructural a JSON) y `sync` inteligente hacia la base de datos `.mpr`.
* **`sqlite.lua`**: Envoltorio nativo de SQLite escrito con LuaJIT FFI, optimizado para leer y escribir tipos de datos relacionales y bloques binarios (`BLOB`).
* **`server.lua`**: Demonio de monitoreo asíncrono en tiempo real para disparar la sincronización automática ante cambios en el proyecto.
* **`clean_mpr.sql`**: Rutina de mantenimiento y purga defensiva para depurar registros huérfanos o malformados en el archivo `.mpr`.

---

## ⚙️ Uso y Comandos

### 1. Comprobar el estado del proyecto
Analiza y lista las tablas internas del archivo `.mpr` de Mendix:
```bash
./bypass status
```

### 2. Extraer volcado estructural (`Dump`)
Exporta el esquema y el contenido de las tablas de Mendix a un archivo JSON legible:
```bash
./bypass dump mpr_full_dump.json
```

### 3. Sincronizar cambios (`Sync`)
Aplica de forma inteligente las modificaciones desde el archivo de modelo hacia el `.mpr` con validación estricta de GUIDs/BLOBs:
```bash
./bypass sync mpr_full_dump.json
```

### 4. Iniciar el monitor de cambios en tiempo real
Ejecuta el demonio asíncrono para escuchar modificaciones en el entorno de desarrollo:
```bash
luajit server.lua
```
