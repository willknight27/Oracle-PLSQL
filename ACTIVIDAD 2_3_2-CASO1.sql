--BIND
VAR B_TRAMO1 NUMBER;
EXEC :B_TRAMO1 := 500000;
VAR B_TRAMO2 NUMBER;
EXEC :B_TRAMO2 := 700000;
VAR B_TRAMO3 NUMBER;
EXEC :B_TRAMO3 := 700001;
VAR B_TRAMO4 NUMBER;
EXEC :B_TRAMO4 := 900000;


DECLARE

    R_DETALLE_PUNTOS DETALLE_PUNTOS_TARJETA_CATB%ROWTYPE;
    R_RESUMEN_PUNTOS RESUMEN_PUNTOS_TARJETA_CATB%ROWTYPE;
    
    TYPE TIPO_R_PESOS IS RECORD
    (PESO_NORMAL NUMBER(3) := 250,
     PESO_EXTRA1 NUMBER(3) := 300,
     PESO_EXTRA2 NUMBER(3) := 550,
     PESO_EXTRA3 NUMBER(3) := 700);
    R_PESOS TIPO_R_PESOS;
    
    --CURSOR PRINCIPAL -> DETALLE DE LOS PUNTOS
    CURSOR C_PUNTOS IS
        SELECT 
            C.NUMRUN AS NUMRUN,
            C.DVRUN AS DVRUN,
            TC.NRO_TARJETA AS NRO_TARJETA,
            TTC.NRO_TRANSACCION AS NRO_TRANSACCION,
            TTC.FECHA_TRANSACCION AS FECHA_TRANSACCION,
            TTT.NOMBRE_TPTRAN_TARJETA AS NOMBRE_TPTRAN_TARJETA,
            SUM(TTC.MONTO_TRANSACCION) AS MONTO_TRANSACCION,
            TIC.NOMBRE_TIPO_CLIENTE AS TIPO_CLIENTE
        FROM CLIENTE C
                JOIN TIPO_CLIENTE TIC ON C.COD_TIPO_CLIENTE = TIC.COD_TIPO_CLIENTE
                JOIN TARJETA_CLIENTE TC ON C.NUMRUN = TC.NUMRUN
                JOIN TRANSACCION_TARJETA_CLIENTE TTC ON TC.NRO_TARJETA = TTC.NRO_TARJETA
                JOIN TIPO_TRANSACCION_TARJETA TTT ON TTC.COD_TPTRAN_TARJETA = TTT.COD_TPTRAN_TARJETA
        WHERE EXTRACT(YEAR FROM TTC.FECHA_TRANSACCION) = EXTRACT(YEAR FROM SYSDATE)-1
        GROUP BY C.NUMRUN, C.DVRUN, TC.NRO_TARJETA, TTC.NRO_TRANSACCION, TTC.FECHA_TRANSACCION, 
        TTT.NOMBRE_TPTRAN_TARJETA,TIC.NOMBRE_TIPO_CLIENTE
        ORDER BY 5,1,4;
        
        --CURSOR GRAL -> RESUMEN DE PUNTOS: ME MUESTRA LOS 7 MESES DONDE SE HICIERON LAS TRANSACCIONES
        -- HACIENDO SELECT A LA TABLA QUE SE ACABA DE RELLENAR (DETALLE_PUNTOS_TARJETA_CATB) DESDE EL CURSOR DE DETALLES
        CURSOR C_RESUMEN_GRAL IS
        SELECT TO_CHAR(FECHA_TRANSACCION,'MMYYYY') AS FECHA_MES_TRANSACCION
        FROM DETALLE_PUNTOS_TARJETA_CATB
        GROUP BY TO_CHAR(FECHA_TRANSACCION,'MMYYYY')
        ORDER BY 1
        ;
        
        --CURSOR INTERNO -> VA A RETORNAR FILAS DEPENDIENDO DEL MES QUE ESTA EN EL PARAMETRO
        --QUE VIENE DE LA FECHA DEL CURSOR GRAL
        CURSOR C_RESUMEN(P_FECHA_MES VARCHAR2) IS
        SELECT TO_CHAR(FECHA_TRANSACCION,'MMYYYY') MES_ANNO,
               TIPO_TRANSACCION,
               SUM(MONTO_TRANSACCION) MONTO,
               SUM(PUNTOS_ALLTHEBEST) PUNTOS
        FROM DETALLE_PUNTOS_TARJETA_CATB
        WHERE TO_CHAR(FECHA_TRANSACCION,'MMYYYY') = P_FECHA_MES
        GROUP BY TO_CHAR(FECHA_TRANSACCION,'MMYYYY'),TIPO_TRANSACCION
        ;
        
        
        
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_PUNTOS_TARJETA_CATB';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_PUNTOS_TARJETA_CATB';
    
--CURSOR_INSERT TABLA DETALLES
    FOR R_PUNTOS IN C_PUNTOS LOOP
        R_DETALLE_PUNTOS.NUMRUN:= R_PUNTOS.NUMRUN;
        R_DETALLE_PUNTOS.DVRUN := R_PUNTOS.DVRUN;
        R_DETALLE_PUNTOS.NRO_TARJETA := R_PUNTOS.NRO_TARJETA;
        R_DETALLE_PUNTOS.NRO_TRANSACCION := R_PUNTOS.NRO_TRANSACCION;
        R_DETALLE_PUNTOS.FECHA_TRANSACCION := R_PUNTOS.FECHA_TRANSACCION;
        R_DETALLE_PUNTOS.TIPO_TRANSACCION := R_PUNTOS.NOMBRE_TPTRAN_TARJETA;
        R_DETALLE_PUNTOS.MONTO_TRANSACCION := R_PUNTOS.MONTO_TRANSACCION;
        
      
        IF R_PUNTOS.TIPO_CLIENTE = 'Due�a(o) de Casa' OR  R_PUNTOS.TIPO_CLIENTE = 'Pensionados y Tercera Edad' THEN
            R_DETALLE_PUNTOS.PUNTOS_ALLTHEBEST :=
            CASE
                WHEN R_PUNTOS.MONTO_TRANSACCION BETWEEN :B_TRAMO1 AND :B_TRAMO2 THEN TRUNC(R_PUNTOS.MONTO_TRANSACCION/100000)*(R_PESOS.PESO_NORMAL + R_PESOS.PESO_EXTRA1)
                WHEN R_PUNTOS.MONTO_TRANSACCION BETWEEN :B_TRAMO3 AND :B_TRAMO4 THEN TRUNC(R_PUNTOS.MONTO_TRANSACCION/100000)*(R_PESOS.PESO_NORMAL + R_PESOS.PESO_EXTRA2)
                WHEN R_PUNTOS.MONTO_TRANSACCION > :B_TRAMO4 THEN TRUNC(R_PUNTOS.MONTO_TRANSACCION/100000)*(R_PESOS.PESO_NORMAL + R_PESOS.PESO_EXTRA3)
                ELSE TRUNC(R_PUNTOS.MONTO_TRANSACCION/100000)*(R_PESOS.PESO_NORMAL)
            END;
        ELSE
            R_DETALLE_PUNTOS.PUNTOS_ALLTHEBEST := TRUNC(R_PUNTOS.MONTO_TRANSACCION/100000)*(R_PESOS.PESO_NORMAL);
        END IF;
            
        INSERT INTO DETALLE_PUNTOS_TARJETA_CATB VALUES  R_DETALLE_PUNTOS;
        COMMIT;       
    END LOOP;
    
--CURSOR_INSERT TABLA RESUMEN
    --CURSOR GRAL
    FOR R_RESUMEN_GRAL IN C_RESUMEN_GRAL LOOP
    
        --INICIALIZADOS EN CERO
        R_RESUMEN_PUNTOS.MONTO_TOTAL_COMPRAS  := 0;
        R_RESUMEN_PUNTOS.TOTAL_PUNTOS_COMPRAS := 0;
        R_RESUMEN_PUNTOS.MONTO_TOTAL_AVANCES := 0;
        R_RESUMEN_PUNTOS.TOTAL_PUNTOS_AVANCES := 0;
        R_RESUMEN_PUNTOS.MONTO_TOTAL_SAVANCES := 0;
        R_RESUMEN_PUNTOS.TOTAL_PUNTOS_AVANACES := 0;
        
    
        --CURSOR INTERNO
        FOR R_RESUMEN IN  C_RESUMEN(R_RESUMEN_GRAL.FECHA_MES_TRANSACCION) LOOP
            
            R_RESUMEN_PUNTOS.MES_ANNO := R_RESUMEN.MES_ANNO;
            
            IF R_RESUMEN.TIPO_TRANSACCION = 'Compras Tiendas Retail o Asociadas' THEN
                R_RESUMEN_PUNTOS.MONTO_TOTAL_COMPRAS := R_RESUMEN.MONTO;
                R_RESUMEN_PUNTOS.TOTAL_PUNTOS_COMPRAS := R_RESUMEN.PUNTOS;
            ELSIF R_RESUMEN.TIPO_TRANSACCION = 'Avance en Efectivo' THEN
                R_RESUMEN_PUNTOS.MONTO_TOTAL_AVANCES := R_RESUMEN.MONTO;
                R_RESUMEN_PUNTOS.TOTAL_PUNTOS_AVANCES := R_RESUMEN.PUNTOS;
            ELSIF R_RESUMEN.TIPO_TRANSACCION = 'S�per Avance en Efectivo' THEN
                R_RESUMEN_PUNTOS.MONTO_TOTAL_SAVANCES := R_RESUMEN.MONTO;
                R_RESUMEN_PUNTOS.TOTAL_PUNTOS_AVANACES := R_RESUMEN.PUNTOS;
            END IF;
            
        END LOOP;
        
        INSERT INTO RESUMEN_PUNTOS_TARJETA_CATB VALUES R_RESUMEN_PUNTOS;
        COMMIT;
    END LOOP;
END
;

/
SELECT * FROM DETALLE_PUNTOS_TARJETA_CATB;
/
SELECT * FROM RESUMEN_PUNTOS_TARJETA_CATB;
/
SELECT TO_CHAR(FECHA_TRANSACCION,'MMYYYY') FROM DETALLE_PUNTOS_TARJETA_CATB
GROUP BY TO_CHAR(FECHA_TRANSACCION,'MMYYYY')
ORDER BY 1
;

--2:50:00