-- CÁLCULO DO PONTO DE EQUILÍBRIO CONTÁBIL (CUSTO FIXO / MARGEM DE CONTRIBUIÇÃO %)

-- Apuração dos gastos totais com Pessoas (salários, encargos, benefícios, etc.)

SELECT DISTINCT

    SUM(
    
        (SELECT DISTINCT
            
            SUM(CASE WHEN fin.CODNAT IN (1040000, 1040100, 1040200, 1040300, 1040400, 1040500, 
                                         1040600, 1040700, 1040800, 1040900, 1041000, 1041100,
                                         1041200, 1041300, 1041400, 1041500, 1041600, 1041700, 
                                         1041800, 1041900, 1042000, 1042100, 1042200, 1042300, 
                                         1042400, 1042500, 1042600, 1042700, 1042800, 1049900) 
            
            THEN fin.VLRBAIXA ELSE 0 END) AS PESSOAL
            
            FROM TGFFIN fin
            
            WHERE fin.CODEMP = 1
            
            AND fin.RECDESP = -1
            AND fin.PROVISAO = 'N'
            AND fin.VLRBAIXA <> 0
            AND fin.CODCTABCOINT <> 11
            AND  (fin.DHBAIXA BETWEEN :DHBAIXA.ini AND :DHBAIXA.fin)
        
        )
            
    +
    
    
    -- Apuração dos Gastos Gerais (despesas fixas)

    (SELECT DISTINCT
        
        SUM
        
        (
        
        SUM(CASE WHEN fin.CODNAT IN (1050100, 1050101, 1050102, 1050103, 1050104, 1050105) THEN fin.VLRBAIXA ELSE 0 END) +
        
        SUM(CASE WHEN fin.CODNAT IN (1050201, 1050202, 1050203, 1050299) THEN fin.VLRBAIXA ELSE 0 END) +
        
        SUM(CASE WHEN fin.CODNAT IN (1050301, 1050302, 1050303, 1050304, 1050305, 1050399) THEN fin.VLRBAIXA ELSE 0 END) +
        
        SUM(CASE WHEN fin.CODNAT IN (1050401, 1050402, 1050403, 1050404, 1050405, 1050499) THEN fin.VLRBAIXA ELSE 0 END) +
        
        SUM(CASE WHEN fin.CODNAT IN (1060100, 1060200, 1060300, 1060400, 1060500, 1060600, 
                                     1060700, 1060800, 1060900, 1061000, 1061100, 1061200,
                                     1061300, 1061400, 1061500, 1061600, 1061700, 1061800,
                                     1061900, 1069500, 1069600, 1069700, 1069800, 1069900)
                                        
                                        THEN fin.VLRBAIXA ELSE 0 END)
        ) AS GASTOS_GERAIS
    
    FROM TGFFIN fin
    
    WHERE fin.CODEMP = 1
    AND (fin.DHBAIXA BETWEEN :DHBAIXA.ini AND :DHBAIXA.fin)
    AND fin.RECDESP = -1
    AND fin.PROVISAO = 'N'
    AND fin.VLRBAIXA <> 0
    
    GROUP BY fin.VLRBAIXA
    
    )

) 

/


-- Cálculo da Margem de Contribuição geral no período de apuração


(SELECT DISTINCT

    (SELECT DISTINCT
    
    SUM
    
    (
        SUM(CASE 
    
            WHEN cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', 
    					            '1128', '1130', '1131', '1706', '1708', 
       					            '1709', '1710', '1711', '1714', '1720') 
            
            THEN 
                
                CASE 
                    WHEN cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', 
    							            '1128', '1130', '1131', '1706', '1708', 
    							            '1709', '1710', '1711', '1714', '1720')
                    THEN cab.VLRNOTA
                
                    WHEN cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', 
    							            '1128', '1130', '1131', '1706', '1708', 
    							            '1709', '1710', '1711', '1714', '1720')
                    AND cab.STATUSNOTA = 'L'                
                    THEN cab.VLRNOTA 
                
                ELSE 0 END
                
            ELSE 0 END
        ) -
    
        SUM(CASE WHEN cab.TIPMOV = 'V' THEN cab.VLRICMS ELSE 0 END) -
    
        SUM(CASE WHEN cab.TIPMOV = 'V' THEN cab.VLRIPI ELSE 0 END) -
        
        SUM(CASE WHEN cab.TIPMOV = 'V' AND cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', '1128', '1131', '1709', '1710', '1711', '1720') THEN cab.VLRNOTA * 0.0065 ELSE 0 END) - 
    
        SUM(CASE WHEN cab.TIPMOV = 'V' AND cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', '1128', '1131', '1709', '1710', '1711', '1720') THEN cab.VLRNOTA * 0.03 ELSE 0 END) -
    
        SUM(CASE WHEN cab.TIPMOV = 'V' AND cab.CODTIPOPER IN ('1710', '1711', '1714') THEN cab.VLRNOTA * 0.03 ELSE 0 END) -
    
        (SELECT
            SUM(CASE WHEN cab.TIPMOV = 'C' AND cab.CODTIPOPER <> 203 THEN ite.VLRTOT ELSE ite.VLRTOT - ite.VLRICMS END)
            FROM TGFCAB cab, TGFITE ite
            WHERE cab.CODEMP = 1
            AND cab.TIPMOV = 'C'
            AND cab.NUNOTA = ite.NUNOTA
            AND	(ite.AD_CODNAT IN (1020101, 1020102, 1020103, 1020104, 1020199, 1030100, 1030200, 1039900) OR cab.CODNAT = 1020201)
            AND (cab.DTFATUR BETWEEN :DTFATUR.ini AND :DTFATUR.fin)
            GROUP BY cab.TIPMOV)
    )
    
    
    FROM TGFCAB cab
    
    WHERE cab.CODEMP = 1
    
    AND cab.TIPMOV = 'V'
    AND cab.STATUSNOTA = 'L'
    
    AND (cab.DTFATUR BETWEEN :DTFATUR.ini AND :DTFATUR.fin)
    
    GROUP BY cab.TIPMOV
    
    )

    /
    
    (SELECT
    
    SUM(CASE 
    
            WHEN cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', 
    					            '1128', '1130', '1131', '1706', '1708', 
       					            '1709', '1710', '1711', '1714', '1720') 
            
            THEN 
                
                CASE 
                    WHEN cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', 
    							            '1128', '1130', '1131', '1706', '1708', 
    							            '1709', '1710', '1711', '1714', '1720')
                    THEN cab.VLRNOTA  
                
                    WHEN cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', 
    							            '1128', '1130', '1131', '1706', '1708', 
    							            '1709', '1710', '1711', '1714', '1720')
                    AND cab.STATUSNOTA = 'L'
    		     THEN cab.VLRNOTA 
                
                ELSE 0 END
                
            ELSE 0 END
        )
    
    FROM TGFCAB cab
    
    WHERE (cab.DTFATUR BETWEEN :DTFATUR.ini AND :DTFATUR.fin)
    
    )
    
    FROM TGFCAB cab
    
    WHERE cab.CODEMP = 1
    
    AND cab.TIPMOV = 'V'
    AND cab.STATUSNOTA = 'L'
    
    AND (cab.DTFATUR BETWEEN :DTFATUR.ini AND :DTFATUR.fin)
    AND cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', '1128', '1130', '1131', '1706', '1708', '1709', '1710', '1711', '1714', '1720')
    
    GROUP BY cab.VLRNOTA
    )
    
FROM TGFCAB cab
INNER JOIN TGFFIN fin ON cab.NUNOTA = fin.NUNOTA

WHERE cab.CODEMP = 1

GROUP BY (SELECT DISTINCT

    (SELECT DISTINCT
    
    SUM
    
    (
        SUM(CASE 
    
            WHEN cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', 
    					    '1128', '1130', '1131', '1706', '1708', 
       					    '1709', '1710', '1711', '1714', '1720') 
            
            THEN 
                
                CASE 
                    WHEN cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', 
    							 '1128', '1130', '1131', '1706', '1708', 
    							 '1709', '1710', '1711', '1714', '1720')
                    AND cab.CODPARC = 1689 
                    THEN cab.VLRNOTA  
                
                    WHEN cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', 
    							 '1128', '1130', '1131', '1706', '1708', 
    							 '1709', '1710', '1711', '1714', '1720')
                    AND cab.STATUSNOTA = 'L'                
                    THEN cab.VLRNOTA 
                
                ELSE 0 END
                
            ELSE 0 END
        ) -
    
        SUM(CASE WHEN cab.TIPMOV = 'V' THEN cab.VLRICMS ELSE 0 END) -
    
        SUM(CASE WHEN cab.TIPMOV = 'V' THEN cab.VLRIPI ELSE 0 END) -
        
        SUM(CASE WHEN cab.TIPMOV = 'V' AND cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', '1128', '1131', '1709', '1710', '1711', '1720') THEN cab.VLRNOTA * 0.0065 ELSE 0 END) - 
    
        SUM(CASE WHEN cab.TIPMOV = 'V' AND cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', '1128', '1131', '1709', '1710', '1711', '1720') THEN cab.VLRNOTA * 0.03 ELSE 0 END) -
    
        SUM(CASE WHEN cab.TIPMOV = 'V' AND cab.CODTIPOPER IN ('1710', '1711', '1714') THEN cab.VLRNOTA * 0.03 ELSE 0 END) -
    
        (SELECT
            SUM(CASE WHEN cab.TIPMOV = 'C' AND cab.CODTIPOPER <> 203 THEN ite.VLRTOT ELSE ite.VLRTOT - ite.VLRICMS END)
            FROM TGFCAB cab, TGFITE ite
            WHERE cab.CODEMP = 1
            AND cab.TIPMOV = 'C'
            AND cab.NUNOTA = ite.NUNOTA
            AND	(ite.AD_CODNAT IN (1020101, 1020102, 1020103, 1020104, 1020199, 1030100, 1030200, 1039900) OR cab.CODNAT = 1020201)
            AND (cab.DTFATUR BETWEEN :DTFATUR.ini AND :DTFATUR.fin)
            GROUP BY cab.TIPMOV)
    )
    
    
    FROM TGFCAB cab
    
    WHERE cab.CODEMP = 1
    
    AND cab.TIPMOV = 'V'
    AND cab.STATUSNOTA = 'L'
    
    AND AND (cab.DTFATUR BETWEEN :DTFATUR.ini AND :DTFATUR.fin)
    
    GROUP BY cab.TIPMOV
    
    )

    /
    
    (SELECT
    
    SUM(CASE 
    
            WHEN cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', 
    					            '1128', '1130', '1131', '1706', '1708', 
       					            '1709', '1710', '1711', '1714', '1720') 
            
            THEN 
                
                CASE 
                    WHEN cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', 
    							            '1128', '1130', '1131', '1706', '1708', 
    							            '1709', '1710', '1711', '1714', '1720')
                    AND cab.CODPARC = 1689 
                    THEN cab.VLRNOTA  
                
                    WHEN cab.CODTIPOPER IN ('1100', '1111', '1120', '1125', '1126', 
    							            '1128', '1130', '1131', '1706', '1708', 
    							            '1709', '1710', '1711', '1714', '1720')
                    AND cab.STATUSNOTA = 'L'
    		     THEN cab.VLRNOTA 
                
                ELSE 0 END
                
            ELSE 0 END
        )
    
    FROM TGFCAB cab
    
    WHERE (cab.DTFATUR BETWEEN :DTFATUR.ini AND :DTFATUR.fin)
    
    ));
