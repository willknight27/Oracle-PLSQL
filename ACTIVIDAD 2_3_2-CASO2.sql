
DECLARE
    
    R_DETALLE DETALLE_APORTE_SBIF%ROWTYPE;
    R_RESUMEN RESUMEN_APORTE_SBIF%ROWTYPE;
    V_PORCENTAJE NUMBER(1);
    
    --1. CURSOR PRINCIPAL
    CURSOR C_DETALLE_APORTE IS
    SELECT
        C.NUMRUN, C.DVRUN,
        TC.NRO_TARJETA,
        TTC.NRO_TRANSACCION,
        TTC.FECHA_TRANSACCION,
        TTT.NOMBRE_TPTRAN_TARJETA,
        TTC.MONTO_TOTAL_TRANSACCION
    FROM CLIENTE C
                JOIN TARJETA_CLIENTE TC ON C.NUMRUN = TC.NUMRUN
                JOIN TRANSACCION_TARJETA_CLIENTE TTC ON TC.NRO_TARJETA = TTC.NRO_TARJETA
                JOIN TIPO_TRANSACCION_TARJETA TTT ON TTC.COD_TPTRAN_TARJETA = TTT.COD_TPTRAN_TARJETA
    WHERE EXTRACT(YEAR FROM TTC.FECHA_TRANSACCION) = EXTRACT(YEAR FROM SYSDATE) AND TTT.NOMBRE_TPTRAN_TARJETA <> 'Compras Tiendas Retail o Asociadas'
    ORDER BY 5,1
    ;
    --2. CURSOR GRAL
    CURSOR C_RESUMEN_GRAL IS
    SELECT TO_CHAR(FECHA_TRANSACCION,'MMYYYY') FECHA_MES_TRANSACCION
    FROM DETALLE_APORTE_SBIF
    GROUP BY TO_CHAR(FECHA_TRANSACCION,'MMYYYY')
    ORDER BY 1;
    
    --3. CURSOR INTERNO
    CURSOR C_RESUMEN_INTERNO(P_FECHA VARCHAR2) IS
    SELECT TO_CHAR(FECHA_TRANSACCION,'MMYYYY') MES_ANNO,
           TIPO_TRANSACCION,
           SUM(MONTO_TRANSACCION) MONTO_TOTAL,
           SUM(APORTE_SBIF) APORTE_SBIF
    FROM DETALLE_APORTE_SBIF
    WHERE TO_CHAR(FECHA_TRANSACCION,'MMYYYY') = P_FECHA
    GROUP BY TO_CHAR(FECHA_TRANSACCION,'MMYYYY'), TIPO_TRANSACCION;
    
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_APORTE_SBIF';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_APORTE_SBIF';
    
    FOR R_DETALLE_APORTE IN C_DETALLE_APORTE LOOP
        
        R_DETALLE.NUMRUN := R_DETALLE_APORTE.NUMRUN;
        R_DETALLE.DVRUN := R_DETALLE_APORTE.DVRUN;
        R_DETALLE.NRO_TARJETA := R_DETALLE_APORTE.NRO_TARJETA;
        R_DETALLE.NRO_TRANSACCION := R_DETALLE_APORTE.NRO_TRANSACCION;
        R_DETALLE.FECHA_TRANSACCION := R_DETALLE_APORTE.FECHA_TRANSACCION;
        R_DETALLE.TIPO_TRANSACCION := R_DETALLE_APORTE.NOMBRE_TPTRAN_TARJETA;
        R_DETALLE.MONTO_TRANSACCION := R_DETALLE_APORTE.MONTO_TOTAL_TRANSACCION;
        
        
        SELECT PORC_APORTE_SBIF
        INTO V_PORCENTAJE
        FROM TRAMO_APORTE_SBIF
        WHERE R_DETALLE_APORTE.MONTO_TOTAL_TRANSACCION BETWEEN TRAMO_INF_AV_SAV AND TRAMO_SUP_AV_SAV
        ;
        
        R_DETALLE.APORTE_SBIF := TRUNC(R_DETALLE_APORTE.MONTO_TOTAL_TRANSACCION*(V_PORCENTAJE/100));
        
        INSERT INTO DETALLE_APORTE_SBIF VALUES R_DETALLE;
        COMMIT;
    END LOOP;
    
    
    FOR R_RESUMEN_GRAL IN C_RESUMEN_GRAL LOOP
        
        FOR R_RESUMEN_INTERNO IN C_RESUMEN_INTERNO(R_RESUMEN_GRAL.FECHA_MES_TRANSACCION) LOOP
            
            R_RESUMEN.MES_ANNO :=  R_RESUMEN_INTERNO.MES_ANNO;
            R_RESUMEN.TIPO_TRANSACCION := R_RESUMEN_INTERNO.TIPO_TRANSACCION;
            R_RESUMEN.MONTO_TOTAL_TRANSACCIONES := R_RESUMEN_INTERNO.MONTO_TOTAL;
            R_RESUMEN.APORTE_TOTAL_ABIF := R_RESUMEN_INTERNO.APORTE_SBIF;
            
            INSERT INTO RESUMEN_APORTE_SBIF VALUES R_RESUMEN;
        END LOOP;
    END LOOP;
END;
/
SELECT * FROM DETALLE_APORTE_SBIF;
SELECT * FROM RESUMEN_APORTE_SBIF;