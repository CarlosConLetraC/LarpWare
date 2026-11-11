#!/usr/bin/env bash
# Script para generar metadatos y estructura CRUD de Dark Kitchen en Mendix (vía WSL)

MENDIX_PROJECT_PATH="/mnt/c/Users/pc/Mendix/LarpWare"
MODULE_NAME="DarkKitchen"

echo "======================================================="
echo " Generador de Metadatos CRUD para Dark Kitchen (Mendix)"
echo "======================================================="

if [ ! -d "$MENDIX_PROJECT_PATH" ]; then
  echo "[ERROR] No se encuentra la ruta del proyecto en: $MENDIX_PROJECT_PATH"
  exit 1
fi

cd "$MENDIX_PROJECT_PATH" || exit

# 1. Crear la estructura de directorios del módulo en Mendix
# Mendix organiza los módulos en carpetas con nombres específicos y archivos de metadatos de dominio
echo "[PASO 1] Creando estructura de directorios para el módulo '$MODULE_NAME'..."
mkdir -p "resources/$MODULE_NAME"
mkdir -p "javascriptsource/$MODULE_NAME/actions"
mkdir -p "theme/web/custom"

# 2. Generar el archivo de metadatos del dominio en formato XML estructurado (simulando el modelo de Mendix)
echo "[PASO 2] Generando el archivo de metadatos del Dominio (DomainModel.xml)..."
cat << 'EOF' > "resources/$MODULE_NAME/DomainModel.xml"
<?xml version="1.0" encoding="utf-8"?>
<domainModel xmlns="http://www.mendix.com/domainmodel/1.0" name="DarkKitchen">
    <entities>
        <entity name="Dish" generalization="">
            <attributes>
                <attribute name="Name" type="String" length="100" required="true"/>
                <attribute name="Price" type="Decimal" precision="2" required="true"/>
                <attribute name="Category" type="Enum" values="FastFood,Sushi,Gourmet,Beverages"/>
                <attribute name="IsAvailable" type="Boolean" defaultValue="true"/>
            </attributes>
        </entity>
        <entity name="Order" generalization="">
            <attributes>
                <attribute name="OrderNumber" type="AutoNumber" required="true"/>
                <attribute name="Status" type="Enum" values="Pending,Preparing,Dispatched,Completed" defaultValue="Pending"/>
                <attribute name="TotalAmount" type="Decimal" precision="2"/>
                <attribute name="OrderDate" type="DateTime"/>
            </attributes>
        </entity>
        <entity name="Customer" generalization="">
            <attributes>
                <attribute name="FullName" type="String" length="150" required="true"/>
                <attribute name="Phone" type="String" length="20"/>
                <attribute name="DeliveryAddress" type="String" length="250"/>
            </attributes>
        </entity>
        <entity name="InventoryItem" generalization="">
            <attributes>
                <attribute name="ItemName" type="String" length="100" required="true"/>
                <attribute name="StockQuantity" type="Integer" defaultValue="0"/>
                <attribute name="Unit" type="String" length="20"/>
            </attributes>
        </entity>
    </entities>
</domainModel>
EOF

# 3. Generar un archivo de configuración JSON complementario para seed data (datos iniciales del CRUD)
echo "[PASO 3] Generando datos iniciales (Seed Data) para el CRUD en formato JSON..."
cat << 'EOF' > "resources/$MODULE_NAME/initial_dishes.json"
[
  {"Name": "Burger Deluxe", "Price": 12.50, "Category": "FastFood", "IsAvailable": true},
  {"Name": "Roll Salmón Acevichado", "Price": 15.00, "Category": "Sushi", "IsAvailable": true},
  {"Name": "Costillas BBQ a la Cerveza", "Price": 22.00, "Category": "Gourmet", "IsAvailable": true},
  {"Name": "Limonada de Hierbabuena", "Price": 4.50, "Category": "Beverages", "IsAvailable": true}
]
EOF

echo "======================================================="
echo " ¡Metadatos generados con éxito en la ruta del proyecto!"
echo "======================================================="
echo " Archivo de modelo XML creado en: resources/$MODULE_NAME/DomainModel.xml"
echo " Archivo de datos semilla en: resources/$MODULE_NAME/initial_dishes.json"
