#!/usr/bin/env bash

# Configuración de rutas (Ruta en WSL correspondiente a C:\Users\pc\Mendix\LarpWare)
MENDIX_PROJECT_PATH="/mnt/c/Users/pc/Mendix/LarpWare"

echo "=================================================="
echo "  Iniciando configurador de Dark Kitchen (Mendix) "
echo "=================================================="

# Verificar si el directorio del proyecto existe
if [ ! -d "$MENDIX_PROJECT_PATH" ]; then
  echo "[ERROR] No se encuentra el proyecto en: $MENDIX_PROJECT_PATH"
  echo "Asegúrate de que la ruta sea correcta y que el proyecto esté creado."
  exit 1
fi

cd "$MENDIX_PROJECT_PATH" || exit
echo "[INFO] Directorio de proyecto localizado: $(pwd)"

# 1. Crear estructura de directorios para modelos/recursos personalizados de la Dark Kitchen
echo "[STEP 1] Creando estructura de carpetas para lógica y datos..."
mkdir -p deployment/data
mkdir -p resources/darkkitchen
mkdir -p userlib

# 2. Generar un archivo de esquema de datos de referencia (JSON) para las entidades del CRUD
echo "[STEP 2] Generando esquemas de datos CRUD para la Dark Kitchen..."
cat << 'EOF' > resources/darkkitchen/domain_model_schema.json
{
  "module": "DarkKitchenCore",
  "entities": [
    {
      "name": "Dish",
      "attributes": [
        {"name": "Name", "type": "String", "length": 100},
        {"name": "Price", "type": "Decimal"},
        {"name": "Category", "type": "Enum", "values": ["FastFood", "Sushi", "Gourmet", "Beverages"]},
        {"name": "IsAvailable", "type": "Boolean"}
      ]
    },
    {
      "name": "Order",
      "attributes": [
        {"name": "OrderNumber", "type": "AutoNumber"},
        {"name": "Status", "type": "Enum", "values": ["Pending", "Preparing", "Dispatched", "Completed"]},
        {"name": "TotalAmount", "type": "Decimal"},
        {"name": "OrderDate", "type": "DateTime"}
      ]
    },
    {
      "name": "Customer",
      "attributes": [
        {"name": "FullName", "type": "String", "length": 150},
        {"name": "Phone", "type": "String", "length": 20},
        {"name": "DeliveryAddress", "type": "String", "length": 250}
      ]
    },
    {
      "name": "InventoryItem",
      "attributes": [
        {"name": "ItemName", "type": "String", "length": 100},
        {"name": "StockQuantity", "type": "Integer"},
        {"name": "Unit", "type": "String", "length": 20}
      ]
    }
  ]
}
EOF

# 3. Crear script auxiliar para compilar o empaquetar si se usa con herramientas de CI/CD de Mendix
cat << 'EOF' > run_local_validation.sh
#!/usr/bin/env bash
echo "Verificando consistencia del proyecto Dark Kitchen..."
# Aquí puedes agregar comandos de Maven o gradle si tu proyecto usa módulos externos personalizados
echo "Estructura lista para ser abierta en Mendix Studio Pro."
EOF

chmod +x run_local_validation.sh

echo "=================================================="
echo "  ¡Estructura de Dark Kitchen generada con éxito!"
echo "=================================================="
echo "Siguientes pasos en Mendix Studio Pro (Windows):"
echo "1. Abre tu proyecto en C:\Users\pc\Mendix\LarpWare con Mendix Studio Pro."
echo "2. Crea un módulo llamado 'DarkKitchenCore'."
echo "3. Añade las entidades basándote en el archivo de esquema: resources/darkkitchen/domain_model_schema.json"
echo "4. Usa el 'Data Grid' y 'Form Viewer' integrados de Mendix para generar las vistas CRUD automáticamente de forma visual."
