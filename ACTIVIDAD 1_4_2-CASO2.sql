--CASO 2

DECLARE
V_ID_EMP           USUARIO_CLAVE.ID_EMP%TYPE := 100;
V_NUMRUN_EMP       USUARIO_CLAVE.NUMRUN_EMP%TYPE;
V_DVRUN_EMP        USUARIO_CLAVE.DVRUN_EMP%TYPE;
V_NOMBRE_EMPLEADO  USUARIO_CLAVE.NOMBRE_EMPLEADO%TYPE;
V_NOMBRE_USUARIO   USUARIO_CLAVE.NOMBRE_USUARIO%TYPE;
V_CLAVE_USUARIO    VUSUARIO_CLAVE.CLAVE_USUARIO%TYPE;

V_ESTADO_CIVIL     ESTADO_CIVIL.NOMBRE_ESTADO_CIVIL%TYPE;
V_SUELDO_BASE      EMPLEADO.SUELDO_BASE%TYPE;
V_FECHA_NAC        EMPLEADO.FECHA_NAC%TYPE;
V_FECHA_CONTRATO   EMPLEADO.FECHA_CONTRATO%TYPE;
V_PRIMER_NOMBRE    EMPLEADO.PNOMBRE_EMP%TYPE;
V_APPATERNO_EMP    EMPLEADO.APPATERNO_EMP%TYPE;

BEGIN
FOR i IN 1..23 LOOP
    SELECT
            
            E.NUMRUN_EMP,
            E.DVRUN_EMP,
            E.PNOMBRE_EMP||' '||E.SNOMBRE_EMP||' '||E.APPATERNO_EMP||' '||E.APMATERNO_EMP,
            EC.NOMBRE_ESTADO_CIVIL,
            E.SUELDO_BASE,
            E.FECHA_CONTRATO,
            E.FECHA_NAC,
            E.PNOMBRE_EMP,
            E.APPATERNO_EMP
            
    
    INTO  V_NUMRUN_EMP,V_DVRUN_EMP,V_NOMBRE_EMPLEADO,V_ESTADO_CIVIL,V_SUELDO_BASE,V_FECHA_CONTRATO,V_FECHA_NAC,V_PRIMER_NOMBRE,V_APPATERNO_EMP        
    FROM EMPLEADO E
                    JOIN ESTADO_CIVIL EC ON E.ID_ESTADO_CIVIL = EC.ID_ESTADO_CIVIL
    WHERE ID_EMP = V_ID_EMP
    ;
    
    V_NOMBRE_USUARIO := V_NOMBRE_USUARIO||LOWER(SUBSTR(V_ESTADO_CIVIL,1,1))||SUBSTR(V_PRIMER_NOMBRE,1,3)||LENGTH(V_PRIMER_NOMBRE)||'*'||SUBSTR(V_SUELDO_BASE,-1,1)||V_DVRUN_EMP||((EXTRACT(YEAR FROM SYSDATE)-EXTRACT(YEAR FROM V_FECHA_CONTRATO)));
                        
    IF (EXTRACT(YEAR FROM SYSDATE)-EXTRACT(YEAR FROM V_FECHA_CONTRATO))<10 THEN
        V_NOMBRE_USUARIO := V_NOMBRE_USUARIO||'X';
    
    END IF
    ;
    
    
    V_CLAVE_USUARIO := V_CLAVE_USUARIO||SUBSTR(V_NUMRUN_EMP,3,1)||(EXTRACT(YEAR FROM V_FECHA_NAC)+2)||(SUBSTR(V_SUELDO_BASE,-3,3)-1);
    
    IF (V_ESTADO_CIVIL = 'CASADO' OR V_ESTADO_CIVIL = 'ACUERDO DE UNION CIVIL') THEN
        V_CLAVE_USUARIO := V_CLAVE_USUARIO||LOWER(SUBSTR(V_APPATERNO_EMP,1,2));
    ELSIF (V_ESTADO_CIVIL = 'DIVORCIADO' OR V_ESTADO_CIVIL = 'SOLTERO') THEN
        V_CLAVE_USUARIO := V_CLAVE_USUARIO||LOWER(SUBSTR(V_APPATERNO_EMP,1,1))||LOWER(SUBSTR(V_APPATERNO_EMP,-1,1));
    ELSIF (V_ESTADO_CIVIL = 'VIUDO') THEN
        V_CLAVE_USUARIO := V_CLAVE_USUARIO||LOWER(SUBSTR(V_APPATERNO_EMP,-3,1))||LOWER(SUBSTR(V_APPATERNO_EMP,-2,1));
    ELSE
         V_CLAVE_USUARIO := V_CLAVE_USUARIO||LOWER(SUBSTR(V_APPATERNO_EMP,-2,2));
    END IF
    ;
    
    V_CLAVE_USUARIO := V_CLAVE_USUARIO||V_ID_EMP||EXTRACT(MONTH FROM SYSDATE)||EXTRACT(YEAR FROM SYSDATE);
    
    
    
    INSERT INTO USUARIO_CLAVE VALUES(V_ID_EMP,V_NUMRUN_EMP,V_DVRUN_EMP,V_NOMBRE_EMPLEADO,V_NOMBRE_USUARIO,V_CLAVE_USUARIO);
    COMMIT;
    V_ID_EMP := V_ID_EMP + 10;
END LOOP;
END
;

/
SELECT  (SUBSTR(SUELDO_BASE,-3,3)-1)
FROM EMPLEADO
WHERE ID_EMP = 100;