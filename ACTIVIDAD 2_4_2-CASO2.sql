
VAR B_5UF NUMBER;
EXEC :B_5UF :=101299;

VAR B_20UF NUMBER;
EXEC :B_20UF := 405.196;

VAR B_IPC NUMBER;
EXEC :B_IPC := 2.73;

DECLARE
    
    V_MONTO_REAJUSTADO NUMBER(9);
    V_REAJUSTE NUMBER(9);
    V_NRO_PRODUCTOS NUMBER(2);
    
    CURSOR C_PRODUCTO_INV IS
    SELECT * FROM PRODUCTO_INVERSION_SOCIO
    ORDER BY 2,1;
    
    TOPE_AJUSTE EXCEPTION;
    

BEGIN
    
    FOR R_PRODUCTO_INV IN C_PRODUCTO_INV LOOP
    
        V_MONTO_REAJUSTADO := R_PRODUCTO_INV.MONTO_TOTAL_AHORRADO*(1+:B_IPC/100);
        
        SELECT COUNT(NRO_SOCIO)
        INTO V_NRO_PRODUCTOS
        FROM PRODUCTO_INVERSION_SOCIO
        WHERE NRO_SOCIO = R_PRODUCTO_INV.NRO_SOCIO;
         
       
        IF V_NRO_PRODUCTOS = 1 THEN
            IF R_PRODUCTO_INV.MONTO_TOTAL_AHORRADO > 1000000 AND EXTRACT(YEAR FROM R_PRODUCTO_INV.FECHA_SOLIC_PROD) = EXTRACT(YEAR FROM SYSDATE) THEN
                V_MONTO_REAJUSTADO := V_MONTO_REAJUSTADO*(1.01);
            END IF;
        ELSIF V_NRO_PRODUCTOS > 1 THEN
             V_MONTO_REAJUSTADO := V_MONTO_REAJUSTADO*(1+V_NRO_PRODUCTOS/100); 
        END IF;
        
        
        BEGIN
            V_REAJUSTE := V_MONTO_REAJUSTADO - R_PRODUCTO_INV.MONTO_TOTAL_AHORRADO;
            IF V_REAJUSTE > :B_20UF THEN
                RAISE TOPE_AJUSTE;
            END IF;
        EXCEPTION WHEN TOPE_AJUSTE THEN
            V_MONTO_REAJUSTADO := R_PRODUCTO_INV.MONTO_TOTAL_AHORRADO + 101299;
            V_REAJUSTE := V_MONTO_REAJUSTADO - R_PRODUCTO_INV.MONTO_TOTAL_AHORRADO;
            INSERT INTO ERROR_PROCESO VALUES(SQ_COD_ERROR.NEXTVAL,'Tope De Reajuste De 5 Uf','SOLICITUD DEL PRODUCTO N� '||R_PRODUCTO_INV.NRO_SOLIC_PROD||'. VALOR REAJUSTE CALCULADO: '||V_REAJUSTE);
        END;        
            
        
        UPDATE PRODUCTO_INVERSION_SOCIO
        SET MONTO_TOTAL_AHORRADO = V_MONTO_REAJUSTADO
        WHERE NRO_SOLIC_PROD = R_PRODUCTO_INV.NRO_SOLIC_PROD; 
    END LOOP;
END;
/
SELECT * FROM ERROR_PROCESO;
SELECT * FROM PRODUCTO_INVERSION_SOCIO;