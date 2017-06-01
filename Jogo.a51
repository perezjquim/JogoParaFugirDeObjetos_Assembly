;*******************************************************************************
; Projeto 3 de Arquitetura de Computadores
; Jogo para fugir de objetos (Assembly)
; Manuel Joaquim Andrade Sousa Perez, 2029015
; Cláudio Ascenso Sardinha, 2030215
;*******************************************************************************

;*******************************************************************************
;	Portas
INPUT EQU P3
;*******************************************************************************
; Constantes auxiliares (microcontrolador)
STACK_POINTER_INICIAL EQU 100						; Posição inicial da stack pointer
TEMPO_T0_HIGH EQU 0x3C	 								; Byte mais significativo do timer 0 - 50 ms (12MHz)
TEMPO_T0_LOW EQU 0xAF	 									; Byte menos significativo do timer 0 - 50 ms (12MHz)
TEMPO_T1 EQU 0x70	   											; 0x70 Tempo do timer 1 - 112 us (12MHz)
VAZIO EQU 0xFF															; Porta vazia (tudo desligado)
INTERRUPCOES_SETUP EQU 143						; Estado das interrupções ao ser corrido o programa
;*******************************************************************************
;	Constantes auxiliares (jogo)
IMAGEM_GAMEOVER EQU 5									; ID da imagem do gameover
IMAGEM_VICTORY EQU 6											; ID da imagem da vitória
NR_IMAGENS EQU 7													; Número de imagens
NR_LINHAS EQU 7														; Número total de linhas
POS_JOGADOR EQU 6												; Linha do jogador (última linha)
POS_JOGADOR_INICIAL EQU 4								; Posição inicial do jogador (no meio da linha)
LINHAATIVA_INICIAL EQU 11111110b					; Seleção da primeira linha
NIVEL_INICIAL EQU 1												; Nível inicial (nível 1)
VIDAS_INICIAL EQU 4												; Nº de vidas para o jogador (3 vidas)
DIFICULDADE1 EQU 20											; Velocidade a que descem os obstáculos (dificuldade)
DIFICULDADE2 EQU 18											; Velocidade a que descem os obstáculos (dificuldade)
DIFICULDADE3 EQU 15 											; Velocidade a que descem os obstáculos (dificuldade)
DIFICULDADE4 EQU 10 											; Velocidade a que descem os obstáculos (dificuldade)
DIFICULDADE5 EQU 7  											; Velocidade a que descem os obstáculos (dificuldade)
LIMITE_X_DIREITA EQU 1											;  Limite direito do display em relação ao X
LIMITE_X_ESQUERDA EQU 16								; Limite esquerdo do display em relação ao X
LINHA_VAZIA EQU 0													; Representa uma linha vazia (imagem com os LEDs todos desligados)
;*******************************************************************************
;	Variáveis do jogo
LinhaAtual EQU 40														; Variável para guardar o número de linha
VidasRestantes EQU 41  											; Vidas restantes do jogador
TempoObstaculos EQU 42	 									; Tempo (restante) antes de descerem (novamente) os obstáculos
DificuldadeAtual EQU 43											; Dificuldade atual do jogo (tempo estipulado para a frequência com que os obstáculos vão descendo)
ObstaculosInicio EQU 44											; Limite superior dos obstáculos
NivelAtual EQU 45														; Nível atual do jogo (que representa a imagem do vetor a ser desenhada)
ImagemAtual EQU 46													;			
LinhaAtiva EQU 47														;
NovaImagem EQU 50												; 
ImagemDisplay EQU 70  											; Display com 7 valores
;*******************************************************************************
; Primeira instrução, após o reset do microcontrolador (rotina principal)
CSEG AT 0000h
JMP Principal
;*******************************************************************************
;*******************************************************************************
; Rotina de tratamento da interrupção externa 0 (mover jogador para a esquerda)
CSEG AT 0003h
JMP MoverJogadorEsquerda
;*******************************************************************************
;*******************************************************************************
; Rotina de tratamento da interrupção externa 1 (mover jogador para a direita)
CSEG AT 0013h
JMP MoverJogadorDireita
;*******************************************************************************
; Rotina de tratamento da interrupção do temporizador 0
CSEG AT 000bh
JMP VerificarObstaculos
;*******************************************************************************
;*******************************************************************************
; Rotina de tratamento da interrupção do temporizador 1 (varrimento do display)
CSEG AT 001bh
JMP VarrerDisplay
;***************************************************************************
;***************************************************************************

;*******************************************************************************	
;*******************************************************************************
; Rotinas principais
;*******************************************************************************
CSEG AT 050h
Principal:
    MOV SP, #STACK_POINTER_INICIAL			        ; Endereço inicial da stack pointer
    MOV LinhaAtual, #0			                    					; Mostrar a primeira linha no display
    MOV LinhaAtiva, #LINHAATIVA_INICIAL             	; A primeira linha do display é a primeira a ser desenhada

    LigarInterrupcoes:
	
		; Timer 1 no modo 2 (contador de 8 bits com auto-reload)
		; Timer 0 no modo 1 (contador de 16 bits)
        MOV TMOD, #00100001b 									
		
        MOV TH0, #TEMPO_T0_HIGH 							; Timer 0 = 50 ms em 50 ms
        MOV TL0, #TEMPO_T0_LOW								; (este timer vai ser usado para puxar os obstáculos para baixo)
		
        MOV TH1, #TEMPO_T1											; Timer 1 = 1 segundo
        MOV TL1, #TEMPO_T1											; (este timer vai ser usado para o varrimento do display)
        
		MOV IP, #0																; Não altera as prioridades das interrupções
        MOV IE, #INTERRUPCOES_SETUP					; Activa as interrupções
        SETB IT0																	; Ext0 detectada na transição descendente
        SETB IT1																	; Ext1 detectada na transição descendente
        SETB TR0																	; Inicia timer 0
        SETB TR1																	; Inicia timer 1
        MOV INPUT, #VAZIO												; Limpeza da porta de entrada (P3)

    Principal_Jogo:
		MOV VidasRestantes, #VIDAS_INICIAL              ; As vidas do jogador são inicializadas
		MOV NivelAtual, #NIVEL_INICIAL			    		 ; Inicialização do nível		
	
        MOV DificuldadeAtual, #DIFICULDADE1			; Muda para a dificuldade do nível 1
        CALL Jogar																; Entra no nível 1
        
        MOV DificuldadeAtual, #DIFICULDADE2			; Muda para a dificuldade do nível 2
        CALL Jogar																; Entra no nível 2
        
        MOV DificuldadeAtual, #DIFICULDADE3			; Muda para a dificuldade do nível 3
        CALL Jogar																; Entra no nível 3
        
        MOV DificuldadeAtual, #DIFICULDADE4			; Muda para a dificuldade do nível 4
        CALL Jogar																; Entra no nível 4
		
        MOV DificuldadeAtual, #DIFICULDADE5			; Muda para a dificuldade do nível 5
        CALL Jogar																; Entra no nível 5
		
		; Caso tenha passado pelos níveis todos
		; Passa para o modo vitória
        JMP Victory
;*******************************************************************************
;*******************************************************************************

;*******************************************************************************	
;*******************************************************************************
; Rotina para desenhar uma imagem no display (obstáculos ou imagem de gameover ou vitória)
;*******************************************************************************
DesenharNovaImagem:
    PUSH ACC																	; Guarda o conteúdo do registo ACC
    PUSH B																			; Guarda o conteúdo do registo B
    PUSH 0																			; Guarda o conteúdo do registo R0
    PUSH 1																			; Guarda o conteúdo do registo R1
    PUSH 2																			; Guarda o conteúdo do registo R2

    MOV A, NovaImagem													; Busca o ID da imagem a ser desenhada (NovaImagem)
    MOV B, #NR_LINHAS												; Busca o número de linhas
    DEC B																			; Decrementa o último valor (visto que não queremos que faça o display na última linha - linha do jogador)
    MUL AB																			; Multiplica o ID da imagem pelo tamanho da linha (de forma a obtermos a imagem pretendida)
	
    MOV R0, #ImagemDisplay										; Aponta para a imagem apresentada no display
    MOV R1, A																	; Guarda o deslocamento
    MOV R2, #POS_JOGADOR										; Número de linhas do display
    MOV DPTR, #Imagens												; Endereço base das imagens
    
	; Ciclo para desenhar no display
    CicloDesenhar:															
        MOVC A, @A+DPTR												; Busca uma linha da imagem
        MOV @R0, A															; Desenha essa linha no display
        INC R0																		; Passa para a próxima linha no display
        INC R1																		; Passa para o próxima linha na tabela
        MOV A, R1			
        DJNZ R2, CicloDesenhar										; Verifica se já desenhou em todas as linhas (exceto na linha do jogador)

    POP 2																			; Repõe o conteúdo do registo R2
    POP 1																			; Repõe o conteúdo do registo R1
    POP 0																			; Repõe o conteúdo do registo R0
    POP B																			; Repõe o conteúdo do registo B
    POP ACC																		; Repõe o conteúddo do registo ACC
    RET
;*******************************************************************************
;*******************************************************************************
	
;*******************************************************************************	
;*******************************************************************************
; Rotinas de interrupção (EXT0 e EXT1) que controlam o movimento do jogador
;*******************************************************************************
MoverJogadorEsquerda:
	PUSH ACC																			; Guarda o conteúdo do registo ACC
	PUSH B																					; Guarda o conteúdo do registo B
	PUSH 0																					; Guarda o conteúdo do registo R0
			
	MOV A,#POS_JOGADOR													; Aponta para a posição do jogador
	MOV B,#ImagemDisplay													; Aponta para a imagem apresentada no display
	ADD A,B																					; Aponta a linha do jogador
	MOV R0,A 																			
	MOV A,@R0																			; Guarda a posição do jogador no registo A
	
	; Caso o jogador não esteja no limite esquerdo do display,
	; Move para a esquerda
	CJNE A, #LIMITE_X_ESQUERDA, MoverEsquerda	
	
	; Caso contrário,
	; Não faz mais nada nesta rotina
    JMP FimMoverJogadorEsquerda
    
    MoverEsquerda:
        RL A																					; Roda para a esquerda o jogador
        MOV @R0,A																		; Atualiza a posição do jogador
    FimMoverJogadorEsquerda:
        POP 0																				; Repõe o conteúdo do registo R0
        POP B																				; Repõe o conteúdo do registo B
        POP ACC																			; Repõe o conteúdo do registo ACC
        RETI																					; Sai da rotina de interrupção
;*******************************************************************************
MoverJogadorDireita:
	PUSH ACC																			; Guarda o conteúddo do registo ACC
	PUSH B																					; Guarda o conteúddo do registo B
	PUSH 0																					; Guarda o conteúddo do registo R0
			
	MOV A,#POS_JOGADOR													; Aponta para a posição do jogador
	MOV B,#ImagemDisplay													; Aponta para a imagem apresentada no display
	ADD A,B																					; Aponta a linha do jogador
	MOV R0,A 																			
	MOV A,@R0																			; Guarda a posição do jogador no registo A
	
	; Caso o jogador não esteja no limite direito do display,
	; Move para a esquerda
	CJNE A, #LIMITE_X_DIREITA, MoverDireita
	
	; Caso contrário,
	; Não faz mais nada nesta rotina
    JMP FimMoverJogadorDireita
    
    MoverDireita:
        RR A																					; Roda para a direita o jogador
        MOV @R0,A																		; Atualiza a posição do jogador
		
    FimMoverJogadorDireita:
        POP 0																				; Repõe o conteúdo do registo R0
        POP B																				; Repõe o conteúdo do registo B
        POP ACC																			; Repõe o conteúdo do registo ACC
        RETI																					; Sai da rotina de interrupção
;*******************************************************************************
;*******************************************************************************
 
;*******************************************************************************	
;*******************************************************************************
; Rotina de interrupção (TIMER 0) para puxar os obstáculos
;*******************************************************************************
VerificarObstaculos:
    PUSH ACC																		; Guarda o conteúdo do registo ACC
	PUSH 0																				; Guarda o conteúdo do registo R0
	PUSH 1																				; Guarda o conteúdo do registo R1
	PUSH 2
    PUSH B																				; Guarda o conteúdo do registo B
    
    MOV TH0, #TEMPO_T0_HIGH										; Reinicializa o timer 0
    MOV TL0, #TEMPO_T0_LOW						

	; Decrementa o tempo restante para o movimento dos obstáculos
	; Verifica se este já acabou (se os obstáculos já se podem mover)
    DJNZ TempoObstaculos, fimVerificarObstaculos
    
	; Caso tenha acabado o tempo, reinicializa o tempo de contagem até que sejam movido outra vez
    ReinicializarDificuldade:
        MOV TempoObstaculos, DificuldadeAtual
        
	; Verifica se houve colisão entre o jogador e um obstáculo
    VerificarColisoes:
		MOV A, #ImagemDisplay											; Aponta para a imagem presente no display
		ADD A, #POS_JOGADOR											; Aponta para a linha do jogador
        MOV B, A
        DEC B																			; Aponta para a linha acima do jogador
        
        MOV R0, A																	
        MOV A, @R0																; Busca a imagem da linha do jogador
        MOV R0, B
        MOV B, @R0																; Busca a imagem da linha acima do jogador
		
		ANL A, B																		; Faz a operação (bitwise) AND de ambas as linhas
		
		; Caso não tenha havido interseção (colisão)
		; Simplesmente move os obstáculos
		JZ MoverObstaculos
        
		; Caso contrário,
		; Decrementa o nº de vidas
		; E move os obstáculos
        DecrementarVidas:
			DEC VidasRestantes

	MoverObstaculos:
		MOV A, #POS_JOGADOR             ;i = POS_JOGADOR -1
		DEC A
		
		CicloMoverObstaculos:
			MOV B, ObstaculosInicio
			CJNE A, B, MoverObstaculosBaixo ; (i != ObstaculosInicio)?
			JMP VerificaObstaculosInicio
		
            MoverObstaculosBaixo:          
                MOV R1, A
                
                MOV A, #ImagemDisplay
                ADD A, R1
                ;ImagemDisplay[i]
                
                MOV B, A
                DEC B
                ;ImagemDisplay[i-1]
                
                MOV R2, A
                MOV R0, B
                MOV A, @R0
                ;Valor de ImagemDisplay[i-1]
                
                MOV B, R2
                MOV R0, B
                ;MOV R0, R2
                
                MOV @R0, A
            
        
                MOV A, R1
                DEC A ;i--
                
                JMP CicloMoverObstaculos

        VerificaObstaculosInicio:
            MOV A, ObstaculosInicio
             
            MOV B, #NR_LINHAS
            DEC B
             
            CJNE A, B, IncrementaObstaculosInicio ; (ObstaculosInicio != NR_LINHAS - 1) ?
            JMP FimVerificarObstaculos
    
            IncrementaObstaculosInicio:
                MOV A, #ImagemDisplay
                ADD A, ObstaculosInicio
                MOV R0, A
                 
                MOV A, #LINHA_VAZIA
                 
                MOV @R0, A         ;ImagemDisplay[ObstaculosInicio] = LINHA_VAZIA
                MOV A, @R0
                 
                INC ObstaculosInicio   ;ObstaculosInicio++
		
FimVerificarObstaculos:
    POP B																				; Repõe o conteúdo do registo B
	POP 2
    POP 1																				; Repõe o conteúdo do registo R1
    POP 0																				; Repõe o conteúdo do registo R0
    POP ACC																			; Repõe o conteúdo do registo ACC
    RETI
;*******************************************************************************
;*******************************************************************************

;*******************************************************************************
;*******************************************************************************
; Rotina de interrupção (TIMER 1) para o varrimento do display
;*******************************************************************************
VarrerDisplay:
    PUSH ACC																		; Guarda o conteúdo do registo ACC
    PUSH 0																				; Guarda o conteúdo do registo R0

	MOV A, #ImagemDisplay												; Aponta para a imagem apresentada no display
	ADD A, LinhaAtual															; Aponta para a linha a varrer
	MOV R0, A																		
    
    MOV A, LinhaAtiva															;
	
	MOV P1, #VAZIO																; Desliga a selecção de todas as linhas
	MOV P2, @R0																	; Actualiza a informação da coluna
	MOV P1, A																		; Selecciona a linha

	INC LinhaAtual																	; Passa para a próxima linha
    RL A																					;
    MOV LinhaAtiva, A															;
	
    MOV A, LinhaAtual															;
	
	; Caso tenha passado por todas as linhas,
	; Reinicializa os valores de LinhaAtual e LinhaAtiva
	CJNE A, #NR_LINHAS, FimVarrerDisplay					
	MOV LinhaAtual, #0														
    MOV LinhaAtiva, #LINHAATIVA_INICIAL						
    
    FimVarrerDisplay:
        POP 0																			; Repõe o conteúdo do registo R0
        POP ACC																		; Repõe o conteúdo do registo ACC
        RETI
;*******************************************************************************
;*******************************************************************************	
		
;*******************************************************************************
;*******************************************************************************
; Rotina que desliga o timer 0 (responsável pelo movimento dos obstáculos)
; (usada no fim do jogo, para manter a imagem final intacta)
;*******************************************************************************
DesligarInterrupcoes:
    CLR TR0																			; Desliga o timer 0
    RET
;*******************************************************************************
;*******************************************************************************

;*******************************************************************************
;*******************************************************************************
; Rotinas para o final do jogo
; (Vitória ou Gameover)
;*******************************************************************************
GameOver:
    MOV NovaImagem, #IMAGEM_GAMEOVER				; A próxima imagem a ser desenhada é a imagem do gameover
    CALL DesenharNovaImagem										; Desenha essa imagem (gameover)
    CALL DesligarInterrupcoes											; Desliga o timer 0
    JMP EndLoop																	; Entra em loop

Victory:
    MOV NovaImagem, #IMAGEM_VICTORY					; A próxima imagem a ser desenhada é a imagem da vitória
    CALL DesenharNovaImagem										; Desenha essa imagem (vitória)
    CALL DesligarInterrupcoes											; Desliga o timer 0
    JMP EndLoop																	; Entra em loop

EndLoop: JMP EndLoop
;*******************************************************************************
;*******************************************************************************

;*******************************************************************************
;*******************************************************************************
; Rotinas para os níveis do jogo
;*******************************************************************************
Jogar:
    MOV TempoObstaculos, DificuldadeAtual				; Inicializa o tempo entre cada movimento dos obstáculos
    
    InicializarJogador:
        MOV A, #ImagemDisplay											; Aponta para a imagem apresentada no display
        ADD A, #POS_JOGADOR											; Aponta para a linha do jogador
        MOV R0, A
        MOV @R0, #POS_JOGADOR_INICIAL 					; Põe o jogador na sua posição inicial
        
    InicializarObstaculos:
        MOV ObstaculosInicio, #0										; Limite superior dos obstáculos é inicializado
		
        MOV R0, NivelAtual													; Busca o ID da imagem do nível (obstáculos)
        DEC R0
		
        MOV NovaImagem, R0												; Passa a ser a imagem a ser desenhada
        CALL DesenharNovaImagem									; Desenha os obstáculos
    
    CicloJogar:
        MOV A, VidasRestantes											; Busca as vidas do jogador
		
		; Caso o jogador já não tenha vidas,
		; Sai do ciclo
        JZ fimCicloJogar
		
        MOV A, ObstaculosInicio											; Busca o limite superior dos obstáculos
        MOV B, #NR_LINHAS												; Busca o número de linhas
        DEC B
		
		; Caso os obstáculos não tenham chegado todos ao fim,
		; Continua o ciclo
        CJNE A, B, CicloJogar
        
    fimCicloJogar:    
        MOV A, VidasRestantes											; Busca o número de vidas restantes
		
		; Caso o jogador ainda tenha vidas,
		; Passa para o próximo nível
        JNZ ProximoNivel
		
		; Caso contrário,
		; Passa para o Gameover
        JMP GameOver
    
    ProximoNivel:
        INC NivelAtual																; Incrementa o nº do nível
        RET
;*******************************************************************************
;*******************************************************************************
; Imagens a mostrar no display
Imagens:
DB 3, 2, 4, 1, 5, 2		; Nível 1
DB 4, 3, 2, 6, 0, 0		; Nível 2
DB 7, 6, 2, 6, 0, 0		; Nível 3
DB 8, 2, 3, 6, 0, 0		; Nível 4
DB 1, 4, 4, 6, 0, 0		; Nível 5  
DB 17,10,4,10,17,0      ; Game over
DB 31,31,31,31,31,31	; Vitória
;**************************************************************************

END