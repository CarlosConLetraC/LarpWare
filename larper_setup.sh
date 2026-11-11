#!/usr/bin/env bash
set -e

MENDIX_PROJECT_PATH="/mnt/c/Users/pc/Mendix/LarpWare"

echo "========================================================"
echo " [LARP_SETUP] Desplegando arquitectura Dark Kitchen"
echo " Proyecto Mendix: $MENDIX_PROJECT_PATH"
echo "========================================================"

if [ ! -d "$MENDIX_PROJECT_PATH" ]; then
  echo "[ERROR] No se encuentra la ruta del proyecto en: $MENDIX_PROJECT_PATH"
  exit 1
fi

cd "$MENDIX_PROJECT_PATH"

# 1. Crear estructura de directorios para código Java y recursos de configuración
echo "[STEP 1] Creando estructura de directorios..."
mkdir -p javasource/darkkitchen/actions
mkdir -p resources/darkkitchen
mkdir -p theme/web/custom

# 2. Hardcodear el Domain Model en formato XML (Eequivalente a tu DDL relacional)
echo "[STEP 2] Escribiendo DomainModel.xml..."
cat << 'EOF' > resources/darkkitchen/DomainModel.xml
<?xml version="1.0" encoding="utf-8"?>
<domainModel xmlns="http://www.mendix.com/domainmodel/1.0" name="DarkKitchen">
    <entities>
        <entity name="Brand">
            <attributes>
                <attribute name="Name" type="String" length="100" required="true"/>
                <attribute name="IsActive" type="Boolean" defaultValue="true"/>
            </attributes>
        </entity>
        <entity name="Category">
            <attributes>
                <attribute name="Name" type="String" length="80" required="true"/>
            </attributes>
        </entity>
        <entity name="Product">
            <attributes>
                <attribute name="Name" type="String" length="120" required="true"/>
                <attribute name="SalePrice" type="Decimal" precision="2" required="true"/>
            </attributes>
        </entity>
        <entity name="Ingredient">
            <attributes>
                <attribute name="Name" type="String" length="100" required="true"/>
                <attribute name="Unit" type="Enum" values="kg,gr,pieza"/>
                <attribute name="CurrentStock" type="Decimal" precision="3" defaultValue="0.000"/>
                <attribute name="MinStock" type="Decimal" precision="3" defaultValue="1.000"/>
            </attributes>
        </entity>
        <entity name="Customer">
            <attributes>
                <attribute name="FullName" type="String" length="100" required="true"/>
                <attribute name="Phone" type="String" length="20"/>
                <attribute name="DeliveryAddress" type="String" length="255"/>
            </attributes>
        </entity>
        <entity name="Order">
            <attributes>
                <attribute name="OrderNumber" type="AutoNumber"/>
                <attribute name="OriginPlatform" type="Enum" values="UberEats,Rappi,DidiFood,WebPropia"/>
                <attribute name="OrderDateTime" type="DateTime"/>
                <attribute name="Status" type="Enum" values="Pendiente,EnPreparacion,EnCamino,Entregado,Cancelado" defaultValue="Pendiente"/>
                <attribute name="Total" type="Decimal" precision="2"/>
            </attributes>
        </entity>
    </entities>
</domainModel>
EOF

# 3. Hardcodear los datos semilla (JSON) - Equivalente a tus DML seeds
echo "[STEP 3] Escribiendo datos semilla (initial_dishes.json)..."
cat << 'EOF' > resources/darkkitchen/initial_dishes.json
[
  {"Name": "Burger Deluxe", "SalePrice": 12.50, "Category": "Hamburguesas", "IsAvailable": true},
  {"Name": "Roll Salmón Acevichado", "SalePrice": 15.00, "Category": "Comida Asiática", "IsAvailable": true},
  {"Name": "Costillas BBQ", "SalePrice": 22.00, "Category": "Gourmet", "IsAvailable": true}
]
EOF

# 4. Hardcodear controladores Java (Sustitutos de tus controladores en C/Lua)
echo "[STEP 4] Escribiendo controladores nativos en Java (DarkKitchenController.java)..."
cat << 'EOF' > javasource/darkkitchen/actions/DarkKitchenController.java
package darkkitchen.actions;

import com.mendix.systemwideinterfaces.core.IContext;
import com.mendix.core.Core;
import com.mendix.systemwideinterfaces.core.IMendixObject;

public class DarkKitchenController {

    public static void registrarPlatillo(IContext context, String nombre, double precio) throws Exception {
        IMendixObject product = Core.instantiate(context, "DarkKitchen.Product");
        product.setValue(context, "Name", nombre);
        product.setValue(context, "SalePrice", precio);
        
        Core.commit(context, product);
        System.out.println("[JAVA BACKEND] Platillo registrado exitosamente: " + nombre);
    }
}
EOF

echo "========================================================"
echo " [SUCCESS] ¡Todo el entorno de Dark Kitchen fue desplegado!"
echo " Archivos generados correctamente en WSL y sincronizados."
echo "========================================================"