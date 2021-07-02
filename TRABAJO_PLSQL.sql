/*TRABAJO PROGRAMACI�N DE BASE DE DATOS 001V
- WILLIAMS CABALLERO
- ALBANIA MUSABELI

*/

--SECUENCIA
CREATE SEQUENCE SQ_ERROR;
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE PKG_PORC_DESCUENTO IS

V_PORC_DESCTO NUMBER := 25;
PROCEDURE SP_ASIGNAR_PORC_DESCT(P_CORREO_PAS VARCHAR2,P_MES_ANNO VARCHAR2);
END PKG_PORC_DESCUENTO;
/
CREATE OR REPLACE PACKAGE BODY PKG_PORC_DESCUENTO IS

PROCEDURE SP_ASIGNAR_PORC_DESCT(P_CORREO_PAS VARCHAR2,P_MES_ANNO VARCHAR2)
IS
    V_NUM_VIAJES NUMBER(3);
    V_NOMBRE_PASAJERO VARCHAR(100);
    
BEGIN
        SELECT COUNT(V.NUM_VIAJE),P.NOM_PAS||' '||P.APE_PAS
        INTO V_NUM_VIAJES,V_NOMBRE_PASAJERO
        FROM VIAJES V
        JOIN PASAJERO P ON V.CORREO_PAS = P.CORREO_PAS
        WHERE TO_CHAR(FECHA_VIAJE,'MMYYYY') = P_MES_ANNO AND P.CORREO_PAS = P_CORREO_PAS
        GROUP BY P.CORREO_PAS,P.NOM_PAS||' '||P.APE_PAS
        HAVING COUNT(V.NUM_VIAJE) > (SELECT ROUND(AVG(COUNT(V.NUM_VIAJE)))
                            FROM VIAJES V
                            JOIN PASAJERO P ON V.CORREO_PAS = P.CORREO_PAS
                            WHERE TO_CHAR(FECHA_VIAJE,'MMYYYY') = P_MES_ANNO
                            GROUP BY P.CORREO_PAS);
        
        IF V_NUM_VIAJES > 0 THEN
            INSERT INTO DESCUENTO VALUES(P_CORREO_PAS,P_MES_ANNO,V_NOMBRE_PASAJERO,V_PORC_DESCTO);
            COMMIT;
        END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        INSERT INTO ERRORES VALUES(SQ_ERROR.NEXTVAL,'ERROR SP ASIGNAR PORC DE DESCUENTO AL PASAJERO CON CORREO: '||P_CORREO_PAS);
        COMMIT;
END SP_ASIGNAR_PORC_DESCT;

END PKG_PORC_DESCUENTO;
--------------------------------------------------------------------------------

/
CREATE OR REPLACE FUNCTION FN_NOMBRE_CONDUCTOR(P_PATENTE VARCHAR2) RETURN VARCHAR2
IS
    V_NOM_CONDUCTOR VARCHAR(100);
BEGIN
    EXECUTE IMMEDIATE 
    'SELECT C.NOM_CON||'' ''||C.APE_CON
    FROM CONDUCTOR C
                    JOIN VEHICULO V ON C.CORREO_CON = V.CORREO_CON
    WHERE V.PATENTE = :B_PATENTE'
    INTO V_NOM_CONDUCTOR USING P_PATENTE;
    RETURN V_NOM_CONDUCTOR;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    INSERT INTO ERRORES VALUES(SQ_ERROR.NEXTVAL,'ERROR FN OBTENER NOMBRE CONDUCTOR CON PATENTE: '||P_PATENTE);
    
END FN_NOMBRE_CONDUCTOR;
/
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE SP_PRINCIPAL_STREETRAIL(P_MES_ANNO VARCHAR2)
IS
    R_HISTORIAL_VIAJE HISTORIAL_VIAJE%ROWTYPE;
    
    CURSOR C_VIAJES IS
    SELECT V.NUM_VIAJE,
           P.CORREO_PAS,
           NOM_PAS||' '||APE_PAS AS NOMBRE_PASAJERO,
           C.NOM_COM AS NOMBRE_COMUNA,
           VE.PATENTE,
           VE.CORREO_CON AS CORREO_CONDUCTOR,
           V.FECHA_VIAJE,
           V.TOTAL AS MONTO_VIAJE
    FROM VIAJES V
               JOIN PASAJERO P ON V.CORREO_PAS = P.CORREO_PAS
               JOIN COMUNA C ON V.ID_COM = C.ID_COM
               JOIN VEHICULO VE ON V.PATENTE = VE.PATENTE
    WHERE TO_CHAR(FECHA_VIAJE,'MMYYYY') = P_MES_ANNO
    ORDER BY 1;
    
    V_DESCUENTO NUMBER(2);
    
    
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE HISTORIAL_VIAJE';
    FOR R_VIAJES IN C_VIAJES LOOP
        
        R_HISTORIAL_VIAJE.NUM_VIAJE := R_VIAJES.NUM_VIAJE;
        R_HISTORIAL_VIAJE.CORREO_PASAJERO := R_VIAJES.CORREO_PAS;
        R_HISTORIAL_VIAJE.NOM_PASAJERO := R_VIAJES.NOMBRE_PASAJERO;
        R_HISTORIAL_VIAJE.COMUNA := R_VIAJES.NOMBRE_COMUNA;
        R_HISTORIAL_VIAJE.PATENTE := R_VIAJES.PATENTE;
        R_HISTORIAL_VIAJE.CORREO_CONDUCTOR := R_VIAJES.CORREO_CONDUCTOR;
        R_HISTORIAL_VIAJE.CONDUCTOR := FN_NOMBRE_CONDUCTOR(R_VIAJES.PATENTE);
        R_HISTORIAL_VIAJE.FECHA_VIAJE := R_VIAJES.FECHA_VIAJE;
        R_HISTORIAL_VIAJE.MONTO_VIAJE := R_VIAJES.MONTO_VIAJE;
        
        IF R_VIAJES.NOMBRE_COMUNA IN ('QUILPUÉ','VALPARA�?SO','SANTIAGO','QUILLOTA','LA CRUZ','LLAYLLAY') THEN
             R_HISTORIAL_VIAJE.MONTO_FINAL := R_VIAJES.MONTO_VIAJE - TRUNC((R_VIAJES.MONTO_VIAJE*40/100));
        ELSE
            R_HISTORIAL_VIAJE.MONTO_FINAL := 0;
        END IF;
        
        INSERT INTO HISTORIAL_VIAJE VALUES R_HISTORIAL_VIAJE;
        COMMIT;
        
        PKG_PORC_DESCUENTO.SP_ASIGNAR_PORC_DESCT(R_VIAJES.CORREO_PAS,P_MES_ANNO);
        
    END LOOP;

    
EXCEPTION
    WHEN OTHERS THEN
    INSERT INTO ERRORES VALUES(SQ_ERROR.NEXTVAL,'ERROR SP PRINCIPAL');

END SP_PRINCIPAL_STREETRAIL;
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TGR_ACTUALIZAR_CANT_VIAJES
AFTER INSERT ON HISTORIAL_VIAJE
FOR EACH ROW

BEGIN
    
    UPDATE PASAJERO
    SET CANT_VIAJES = CANT_VIAJES+1
    WHERE CORREO_PAS = :NEW.CORREO_PASAJERO;
    
    UPDATE CONDUCTOR
    SET CANT_VIAJES = CANT_VIAJES+1
    WHERE CORREO_CON = :NEW.CORREO_CONDUCTOR;

END TGR_ACTUALIZAR_CANT_VIAJES;

/


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
EXEC SP_PRINCIPAL_STREETRAIL('062019');
SELECT FN_NOMBRE_CONDUCTOR('0338-1452') FROM DUAL;
SELECT * FROM HISTORIAL_VIAJE;
SELECT * FROM PASAJERO;
SELECT * FROM CONDUCTOR;
SELECT * FROM ERRORES;
SELECT * FROM DESCUENTO;