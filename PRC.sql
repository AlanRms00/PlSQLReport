--DESC EX_PEDIDOS_PRC

CREATE OR REPLACE PROCEDURE EX_PEDIDOS_PRC (P_HORAS IN NUMBER) IS
    LN_HORAS       NUMBER;
    LN_PED_EXIS    NUMBER;
    LD_COLOCADO    DATE := SYSDATE;
    LD_ESTIMADO    DATE := NULL;
    LN_DESC_EXIS   NUMBER;
    LN_TIEMPO_DESC NUMBER;
    LN_ULTIMO_PED  NUMBER;
    LD_EST_ULT_PED DATE;
    LN_NO_PED_NUEV NUMBER;
BEGIN
    LN_HORAS := P_HORAS/24;    

    BEGIN
        SELECT COUNT(1)
        INTO   LN_PED_EXIS
        FROM   EX_PEDIDOS;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        LN_PED_EXIS :=0;
    END;
    
    IF LN_PED_EXIS = 0 THEN
        LN_NO_PED_NUEV := 1;
        LD_ESTIMADO    := LD_COLOCADO+LN_HORAS;
        
        INSERT INTO EX_PEDIDOS VALUES(LN_NO_PED_NUEV, LD_COLOCADO, P_HORAS, 0, LD_ESTIMADO);
        COMMIT;
        
        BEGIN
            SELECT COUNT(1)
            INTO   LN_DESC_EXIS
            FROM   EX_DESCANSOS D
            WHERE  1=1
--            AND    D.INICIO > LD_COLOCADO 
--            AND    D.INICIO < LD_ESTIMADO
            AND    D.INICIO BETWEEN LD_COLOCADO AND LD_ESTIMADO
            OR     LD_COLOCADO BETWEEN D.INICIO AND D.FIN
            ;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            LN_DESC_EXIS := 0;
        END;
        
        IF LN_DESC_EXIS > 0 THEN
            SELECT FIN - INICIO
            INTO   LN_TIEMPO_DESC
            FROM   EX_DESCANSOS D
            WHERE  1=1
--            AND    D.INICIO > LD_COLOCADO 
--            AND    D.INICIO < LD_ESTIMADO
            AND    D.INICIO BETWEEN LD_COLOCADO AND LD_ESTIMADO
            OR     LD_COLOCADO BETWEEN D.INICIO AND D.FIN
            ;
            
            UPDATE EX_PEDIDOS
            SET    FECHA_ESTIMADO = FECHA_ESTIMADO + LN_TIEMPO_DESC
            WHERE  1=1
            AND    NO_PEDIDO = LN_NO_PED_NUEV;
            COMMIT;
        END IF;
    ELSE
        SELECT MAX(NO_PEDIDO)
        INTO   LN_ULTIMO_PED
        FROM   EX_PEDIDOS
        WHERE  1=1
        AND    ESTATUS = 0;    
        
        SELECT FECHA_ESTIMADO
        INTO   LD_EST_ULT_PED 
        FROM   EX_PEDIDOS
        WHERE  1=1
        AND    NO_PEDIDO = LN_ULTIMO_PED;
        
        LN_NO_PED_NUEV := LN_ULTIMO_PED+1;
        LD_ESTIMADO    := LD_EST_ULT_PED+LN_HORAS;
        
        INSERT INTO EX_PEDIDOS VALUES(LN_NO_PED_NUEV, LD_COLOCADO, P_HORAS, 0, LD_ESTIMADO);
        COMMIT;
        
        BEGIN
            SELECT COUNT(1)
            INTO   LN_DESC_EXIS
            FROM   EX_DESCANSOS D
            WHERE  1=1
            AND    D.INICIO > LD_EST_ULT_PED 
            AND    D.INICIO < LD_ESTIMADO
            ;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            LN_DESC_EXIS := 0;
        END;
        
        IF LN_DESC_EXIS > 0 THEN
            SELECT FIN - INICIO
            INTO   LN_TIEMPO_DESC
            FROM   EX_DESCANSOS D
            WHERE  1=1
            AND    D.INICIO > LD_EST_ULT_PED 
            AND    D.INICIO < LD_ESTIMADO;
            
            UPDATE EX_PEDIDOS
            SET    FECHA_ESTIMADO = FECHA_ESTIMADO + LN_TIEMPO_DESC
            WHERE  1=1
            AND    NO_PEDIDO = LN_NO_PED_NUEV;
            
            COMMIT;
        END IF;        
                
    END IF; 
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ocurrio un error al estimar los tiempos del pedido '||LN_NO_PED_NUEV||' -> '||SUBSTR(SQLERRM,1,500));
END EX_PEDIDOS_PRC;