/*EJEMPLO PRUEBA 2 - CASO 2*/

--BIND
VAR B_UF NUMBER;
EXEC :B_UF := 28300;
DECLARE
    
    V_ITERADOR NUMBER(5);
    
    V_SQLCODE NUMBER(6);
    V_SQLERRM VARCHAR2(250);
    
    R_RESULTADO RESULTADO_SUBSIDIO%ROWTYPE;
    
    CURSOR C_POSTULANTES IS
    SELECT
        C.IDCIUDADANO,
        C.NOMCIUDADANO||' '||C.APACIUDADANO NOMBRE,
        TRUNC(MONTHS_BETWEEN(SYSDATE,C.NACIMIENTO)/12) EDAD,
        TRUNC(C.SUELDOBRUTO*0.8) SUELDO_LIQUIDO, --> SUELDO LIQUIDO = 80% DEL BRUTO APROX,
        C.CAE,
        C.CANTHIJO CANTIDAD_HIJOS,
        RE.NOMBRE NOMBRE_REGION,
        P.PROFESION NOMBRE_PROFESION,
        CA.PUNTOS PUNTOS_PROFESION,
        E.NOMBRE NOMBRE_ECIVIL,
        E.PUNTOS PUNTOS_ECIVIL
    FROM CIUDADANO C
    JOIN COMUNA CO ON C.IDCOMUNA = CO.IDCOMUNA
    JOIN REGION RE ON CO.IDREGION = RE.IDREGION
    JOIN PROFESION P ON C.IDPROFESION = P.IDPROFESION
    JOIN CATEGORIA CA ON P.IDCATEGORIA = CA.IDCATEGORIA
    JOIN ECIVIL E ON C.IDECIVIL = E.IDECIVIL;
    
    --CURSOR CON PARAMETROS
    CURSOR C_AHORRO(P_IDCIUDADANO VARCHAR2) IS 
    SELECT
            C.IDCIUDADANO,
            D.MONTO
    FROM CIUDADANO C
                    JOIN CUENTAHORRO CA ON C.IDCIUDADANO = CA.IDCIUDADANO
                    JOIN DEPOSITOS D ON CA.NUMCUENTA = D.NUMCUENTA
    WHERE C.IDCIUDADANO = P_IDCIUDADANO;


BEGIN
    V_ITERADOR := 0;
    
    FOR R_POSTULANTES IN C_POSTULANTES LOOP
    
        V_ITERADOR := V_ITERADOR+1;
        
        R_RESULTADO.IDRESULTADO := TO_CHAR(SYSDATE,'MMYYYY')||V_ITERADOR;
        R_RESULTADO.NOMBRE_COMPLETO := R_POSTULANTES.NOMBRE;
        R_RESULTADO.EDAD :=  R_POSTULANTES.EDAD;
        R_RESULTADO.SUELDO_LIQUIDO := TRUNC(R_POSTULANTES.SUELDO_LIQUIDO/:B_UF);
        
        R_RESULTADO.PUNTOSUELDO :=
        CASE
            WHEN R_POSTULANTES.SUELDO_LIQUIDO BETWEEN 400000 AND 600000 THEN 7
            WHEN R_POSTULANTES.SUELDO_LIQUIDO BETWEEN 600001 AND 700000 THEN 7
            WHEN R_POSTULANTES.SUELDO_LIQUIDO BETWEEN 700001 AND 800000 THEN 5
            WHEN R_POSTULANTES.SUELDO_LIQUIDO BETWEEN 800001 AND 900000 THEN 7
            ELSE 3
        END;
        
        R_RESULTADO.CAE := R_POSTULANTES.CAE;
        
        R_RESULTADO.PUNTOCAE :=
        CASE
            WHEN R_POSTULANTES.CAE = 'S' THEN 3
            ELSE 0
        END;
        
        R_RESULTADO.CANTHIJO := R_POSTULANTES.CANTIDAD_HIJOS;
        
        BEGIN
            SELECT PUNTOS
            INTO R_RESULTADO.PUNTOHIJO
            FROM RANGOHIJO
            WHERE R_POSTULANTES.CANTIDAD_HIJOS BETWEEN CANTMIN AND CANTMAX;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            R_RESULTADO.PUNTOHIJO := 0;
            INSERT INTO REGISTRO_ERROR VALUES(SQ_IDERROR.NEXTVAL,'ERROR EN RANGO HIJOS POSTULANTE: '||R_POSTULANTES.IDCIUDADANO,NULL,NULL);
        END;
        
        R_RESULTADO.PUNTOAHORRO := 0;
        R_RESULTADO.MONTOAHORRO := 0;
        FOR R_AHORRO IN C_AHORRO(R_POSTULANTES.IDCIUDADANO) LOOP
        
            R_RESULTADO.MONTOAHORRO := R_RESULTADO.MONTOAHORRO + R_AHORRO.MONTO;
            
            R_RESULTADO.PUNTOAHORRO := 
            CASE
                WHEN R_AHORRO.MONTO BETWEEN 50000 AND 200000 THEN R_RESULTADO.PUNTOAHORRO+1
                WHEN R_AHORRO.MONTO BETWEEN 200001 AND 400000 THEN R_RESULTADO.PUNTOAHORRO+2
                WHEN R_AHORRO.MONTO BETWEEN 400001 AND 700000 THEN R_RESULTADO.PUNTOAHORRO+3
                ELSE R_RESULTADO.PUNTOAHORRO+4
            END;
        END LOOP;
        
        R_RESULTADO.MONTOAHORRO := TRUNC(R_RESULTADO.MONTOAHORRO/:B_UF);
        R_RESULTADO.REGION := R_POSTULANTES.NOMBRE_REGION;
        
        IF R_POSTULANTES.NOMBRE_REGION = 'AYSEN' OR
           R_POSTULANTES.NOMBRE_REGION = 'ATACAMA' OR
           R_POSTULANTES.NOMBRE_REGION = 'MAGALLANES Y ANT�?RTICA' THEN
            R_RESULTADO.PUNTOREGION := 3;
        ELSE
            R_RESULTADO.PUNTOREGION := 1;
        END IF;
        
        R_RESULTADO.PROFESION := R_POSTULANTES.NOMBRE_PROFESION;
        R_RESULTADO.PUNTOPROF := R_POSTULANTES.PUNTOS_PROFESION;
        R_RESULTADO.ECIVIL := R_POSTULANTES.NOMBRE_ECIVIL;
        R_RESULTADO.PUNTOCIVIL := R_POSTULANTES.PUNTOS_ECIVIL;
        
        R_RESULTADO.TOTALPUNTOS := R_RESULTADO.PUNTOSUELDO +
                                   R_RESULTADO.PUNTOCAE +
                                   R_RESULTADO.PUNTOHIJO +
                                   R_RESULTADO.PUNTOAHORRO +
                                   R_RESULTADO.PUNTOREGION + 
                                   R_RESULTADO.PUNTOPROF + 
                                   R_RESULTADO.PUNTOCIVIL;
        
        SELECT APOYOUF,NOMSUB
        INTO R_RESULTADO.APOYOSUBUF,R_RESULTADO.NOMSUBSIDIO
        FROM SUBSIDIO
        WHERE R_RESULTADO.TOTALPUNTOS BETWEEN PUNTOMIN AND PUNTOMAX;
            
        
        
        BEGIN
        INSERT INTO RESULTADO_SUBSIDIO VALUES R_RESULTADO;
        EXCEPTION WHEN OTHERS THEN  
            V_SQLCODE := SQLCODE;
            V_SQLERRM := SQLERRM;
            INSERT INTO REGISTRO_ERROR VALUES (SQ_IDERROR.NEXTVAL,'PROCESO DE CALCULO SUBSIDIO POSTULANTE: '||R_POSTULANTES.IDCIUDADANO||' YA FUE REALIZADO',V_SQLCODE,V_SQLERRM);       
        END;
        COMMIT;
        
    END LOOP;
END;
/

SELECT * FROM RESULTADO_SUBSIDIO;
DESCRIBE RESULTADO_SUBSIDIO;
SELECT * FROM CIUDADANO;
SELECT * FROM REGION;
SELECT * FROM REGISTRO_ERROR;