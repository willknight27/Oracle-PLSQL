

DECLARE
V_IDCLI         CLIENTE.IDCLI%TYPE;
V_RUTCLI        CLIENTE.RUTCLI%TYPE; 
V_APA           CLIENTE.APA%TYPE;
V_NOM           CLIENTE.NOM%TYPE;
V_CORREO        CLIENTE.CORREO%TYPE;
V_PREMIUM       CLIENTE.PREMIUM%TYPE;   
V_CANT_VIAJES   CLIENTE.CANT_VIAJES%TYPE;    

V_MIN_ID NUMBER(2);
V_MAX_ID NUMBER(2);


BEGIN 
    
    
    SELECT MAX(IDCLI),MIN(IDCLI)
    INTO V_MAX_ID, V_MIN_ID
    FROM CLIENTE;
    
    FOR i IN V_MIN_ID..V_MAX_ID LOOP
        
        SELECT IDCLI, RUTCLI, NOM, APA
        INTO V_IDCLI,V_RUTCLI,V_NOM,V_APA
        FROM CLIENTE
        WHERE IDCLI = i;
        
        V_CORREO := SUBSTR(V_NOM,1,1)||SUBSTR(V_APA,-2,2)||SUBSTR(V_RUTCLI,1,4)||'@AIRVIP.LINE';
        
        SELECT COUNT(B.NUMBOLETO)
        INTO V_CANT_VIAJES
        FROM CLIENTE C
                    JOIN BOLETO B ON C.IDCLI = B.IDCLI
        WHERE C.IDCLI = i;
        
        IF V_CANT_VIAJES >3 THEN
            V_PREMIUM := 'S';
        ELSE
            V_PREMIUM := 'N';
        END IF;
            
        UPDATE CLIENTE 
        SET
            IDCLI = V_IDCLI,
            RUTCLI = V_RUTCLI,
            NOM = V_NOM,
            APA = V_APA,
            CORREO = V_CORREO,
            PREMIUM = V_PREMIUM,
            CANT_VIAJES = V_CANT_VIAJES
        WHERE IDCLI=i;
     
     END LOOP;   
END
;
IDCLIENTE
/
SELECT * FROM CLIENTE;