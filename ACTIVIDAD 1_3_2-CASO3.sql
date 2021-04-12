--CASO 3

/*----------------------------------------------------------------------------------------------------------
                |NOMBRE|               |NUMERO DE SOLICITUD DE CREDITO|   |CANTIDAD CUOTAS A POSTERGAR|

SEBASTIAN PATRICIO QUINTANA BERRIOS                  2001                                 2
KAREN SOFIA PRADENAS MANDIOLA                        3004                                 1
JULIAN PAUL ARRIAGADA LUJAN                          2004                                 1
-----------------------------------------------------------------------------------------------------------*/


--BIND
VAR B_NRO_CLIENTE NUMBER;
EXEC :B_NRO_CLIENTE := 5;

VAR B_NRO_SOLIC_CRED NUMBER;
EXEC :B_NRO_SOLIC_CRED := 2001;

VAR B_CANT_CUOTAS_POST NUMBER;
EXEC :B_CANT_CUOTAS_POST := 2;

DECLARE
V_NRO_CUOTA       CUOTA_CREDITO_CLIENTE.NRO_CUOTA%TYPE;
V_FECHA_VENC      CUOTA_CREDITO_CLIENTE.FECHA_VENC_CUOTA%TYPE;
V_VALOR_CUOTA     CUOTA_CREDITO_CLIENTE.VALOR_CUOTA%TYPE;
V_FECHA_PAGO      CUOTA_CREDITO_CLIENTE.FECHA_PAGO_CUOTA%TYPE;
V_MONTO_PAGADO    CUOTA_CREDITO_CLIENTE.MONTO_PAGADO%TYPE;
V_SALDO_POR_PAGAR CUOTA_CREDITO_CLIENTE.SALDO_POR_PAGAR%TYPE;
V_COD_FORMA_PAGO  CUOTA_CREDITO_CLIENTE.COD_FORMA_PAGO%TYPE;
V_TIPO_CREDITO    CREDITO.NOMBRE_CREDITO%TYPE;

BEGIN

    SELECT 
            CR.NOMBRE_CREDITO
            
    FROM CLIENTE C
                JOIN CREDITO_CLIENTE CC ON C.NRO_CLIENTE = CC.NRO_CLIENTE
                JOIN CREDITO CR ON CC.COD_CREDITO = CR.COD_CREDITO
    WHERE NRO_SOLIC_CREDITO = 2001 AND C.NRO_CLIENTE = 5;



INSERT INTO CUOTA_CREDITO_CLEINTE
VALUES (:B_NRO_SOLIC_CRED,V_NRO_CUOTA,V_FECHA_VENC,V_VALOR_CUOTA,V_FECHA_PAGO,V_MONTO_PAGADO,V_SALDO_POR_PAGAR,V_COD_FORMA_PAGO);


EXCEPTION

END;