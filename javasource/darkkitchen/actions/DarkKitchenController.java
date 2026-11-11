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
