-- clean_mpr.sql (script exclusivo para SqLite3)
-- Eliminar filas en la tabla Unit donde el UnitID esté corrupto (longitud diferente a 16 bytes)
DELETE FROM Unit WHERE length(UnitID) != 16;

-- Limpiar referencias en ContainerID que no tengan 16 bytes (si no son NULL)
UPDATE Unit SET ContainerID = NULL WHERE ContainerID IS NOT NULL AND length(ContainerID) != 16;

-- Verificar que todo haya quedado limpio
SELECT count(*) AS registros_validos FROM Unit WHERE length(UnitID) = 16;
.exit
