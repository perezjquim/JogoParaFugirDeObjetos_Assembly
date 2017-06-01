;*******************************************************************************
; Projeto 3 de Arquitetura de Computadores
; Jogo para fugir de objetos (Assembly)
; Manuel Joaquim Andrade Sousa Perez, 2029015
; Cl�udio Ascenso Sardinha, 2030215
;*******************************************************************************

;*******************************************************************************
;	Portas
INPUT EQU P3
DisplayX EQU P2
DisplayY EQU P1
;*******************************************************************************
; Constantes auxiliares (microcontrolador)
TEMPO_HIGH EQU 0x3C	 								; Byte mais significativo do timer 0 - 50 ms (12MHz)
TEMPO_LOW EQU 0xAF	 									; Byte menos significativo do timer 0 - 50 ms (12MHz)
TEMPO_T1 EQU 0x70	   									; 0x70 Tempo do timer 1 - 112 us (12MHz)
VAZIO EQU 0xFF												; Porta vazia (tudo desligado)
INTERRUPCOES_ESTADO_INICIAL EQU 143		; Estado das interrup��es ao ser corrido o programa
;*******************************************************************************
;	Constantes auxiliares (jogo)
IMAGEM_GAMEOVER EQU 5
IMAGEM_VICTORY EQU 6
NR_IMAGENS EQU 7					; N�mero de imagens
NR_LINHAS EQU 7						; N�mero total de linhas
POS_JOGADOR EQU 6					; Coordenada Y do jogador (�ltima linha)
POS_JOGADOR_INICIAL EQU 4					; Posi��o inicial do jogador (no meio da linha)
LINHAATIVA_INICIAL EQU 11111110b
NIVEL_INICIAL EQU 1
VIDAS_INICIAL EQU 4				; N� de vidas para o jogador (3 vidas)
DIFICULDADE1 EQU 20				; Velocidade a que descem os obst�culos (dificuldade)
DIFICULDADE2 EQU 18				; Velocidade a que descem os obst�culos (dificuldade)
DIFICULDADE3 EQU 15 			; Velocidade a que descem os obst�culos (dificuldade)
DIFICULDADE4 EQU 10 			; Velocidade a que descem os obst�culos (dificuldade)
DIFICULDADE5 EQU 7  			; Velocidade a que descem os obst�culos (dificuldade)
LIMITE_X_DIREITA EQU 1			;  Limite direito do display em rela��o ao X
LIMITE_X_ESQUERDA EQU 16	; Limite esquerdo do display em rela��o ao X
LINHA_VAZIA EQU 0					; Representa uma linha vazia (imagem com os LEDs todos desligados)
;*******************************************************************************
;	Vari�veis do jogo
LinhaAtual EQU 40						; Vari�vel para guardar o n�mero de linha
VidasRestantes EQU 41  			; Vidas restantes do jogador
TempoObstaculos EQU 42	 	; Tempo (restante) antes de descerem (novamente) os obst�culos
DificuldadeAtual EQU 43			; Dificuldade atual do jogo (tempo estipulado para a frequ�ncia com que os obst�culos v�o descendo)
ObstaculosInicio EQU 44			; Limite superior dos obst�culos
NivelAtual EQU 45						; N�vel atual do jogo (que representa a imagem do vetor a ser desenhada)
ImagemAtual EQU 46
LinhaAtiva EQU 47
NovaImagem EQU 50
ImagemX EQU 70  						; Display com 7 valores
;*******************************************************************************
; Primeira instru��o, ap�s o reset do microcontrolador 
CSEG AT 0000h
JMP Principal
;*******************************************************************************
;*******************************************************************************
; Rotina de tratamento da interrup��o externa 0 (bot�o anterior) 
CSEG AT 0003h
JMP MoverJogadorEsquerda
;*******************************************************************************
;*******************************************************************************
; Rotina de tratamento da interrup��o externa 1 (bot�o seguinte) 
CSEG AT 0013h
JMP MoverJogadorDireita
;*******************************************************************************
; Rotina de tratamento da interrup��o do temporizador 0
CSEG AT 000bh
JMP VerificarObstaculos
;*******************************************************************************
;*******************************************************************************
; Rotina de tratamento da interrup��o do temporizado 1
CSEG AT 001bh
JMP VarrerDisplay
;***************************************************************************
;***************************************************************************

;*******************************************************************************
; Instru��es do programa principal
CSEG AT 050h
Principal:
    MOV SP, #100			; Endere�o inicial da stack pointer
    MOV NivelAtual, #NIVEL_INICIAL			; Imagem inicial
    MOV TempoObstaculos, #0
    MOV LinhaAtual, #0			; Mostrar a primeira linha no display
    MOV VidasRestantes, #VIDAS_INICIAL
    MOV LinhaAtiva, #LINHAATIVA_INICIAL

    LigarInterrupcoes:
        MOV TMOD, #00100001b;		; Timer 0 de 16 bits
        MOV TH0, #TEMPO_HIGH;		; Timer 0 = 50 ms
        MOV TL0, #TEMPO_LOW; 
        MOV TH1, #TEMPO_T1;			; Timer 1 = 112 us
        MOV TL1, #TEMPO_T1;
        MOV IP, #0		; N�o altera as prioridades
        MOV IE, #INTERRUPCOES_ESTADO_INICIAL		; Activa as interrup��es:
        SETB IT0			; Ext0 detectada na transi��o descendente
        SETB IT1			; Ext1 detectada na transi��o descendente
        SETB TR0			; Inicia timer 0
        SETB TR1			; Inicia timer 1
        MOV INPUT, #VAZIO			; P3 � uma porta de entrada

    Principal_Jogo:
        MOV DificuldadeAtual, #DIFICULDADE1
        CALL Jogar
        
        MOV DificuldadeAtual, #DIFICULDADE2
        CALL Jogar
        
        MOV DificuldadeAtual, #DIFICULDADE3
        CALL Jogar
        
        MOV DificuldadeAtual, #DIFICULDADE4
        CALL Jogar
        
        MOV DificuldadeAtual, #DIFICULDADE5
        CALL Jogar
        
        JMP Victory
;*******************************************************************************


DesenharNovaImagem:
    PUSH ACC			; Guarda o conte�ddo do registo ACC
    PUSH B
    PUSH 0
    PUSH 1				; Guarda o conte�do do registo R1
    PUSH 2				; Guarda o conte�do do registo R2

    MOV A, NovaImagem
    MOV B, #NR_LINHAS			; N�mero de linhas
    DEC B
    MUL AB				; Multiplica a imagem pelo tamanho da linha
    MOV R0, #ImagemX		; R0 aponta para o display
    MOV R1, A			; Guarda o deslocamento
    MOV R2, #NR_LINHAS		; N�mero de linhas do display
    DEC R2
    MOV DPTR, #Imagens		; Endere�o base das imagens
    
    CicloDesenhar:			; Ciclo da rotina mostrar
        MOVC A, @A+DPTR			; Leitura de uma linha da mem�ria de instru��es
        MOV @R0, A			; Coloca a linha no display
        INC R0				; Passa para a pr�xima linha no display
        INC R1				; Passa para o pr�xima linha na tabela
        MOV A, R1			
        DJNZ R2, CicloDesenhar		; Verifica se j� mostrou todas as linhas

    POP 2				; Rep�e o conte�do do registo R2
    POP 1				; Rep�e o conte�do do registo R1
    POP 0
    POP B
    POP ACC			; Rep�e o conte�ddo do registo ACC
    RET

;*******************************************************************************	
;*******************************************************************************
MoverJogadorEsquerda:
	PUSH ACC
	PUSH B
	PUSH 0
    
	MOV A,#POS_JOGADOR
	MOV B,#ImagemX
	ADD A,B
	MOV R0,A 
	MOV A,@R0					;Posi��o do joagador 
	CJNE A, #LIMITE_X_ESQUERDA, MoverEsquerda
    JMP FimMoverJogadorEsquerda
    
    MoverEsquerda:
        MOV B,#2
        MUL AB
        MOV @R0,A
		
    FimMoverJogadorEsquerda:
        POP 0
        POP B
        POP ACC
        RETI
		
MoverJogadorDireita:
	PUSH ACC
	PUSH B
	PUSH 0

	MOV A,#POS_JOGADOR
	MOV B,#ImagemX
	ADD A,B
	MOV R0,A 
	MOV A,@R0					;Posi��o do joagador 
	CJNE A, #LIMITE_X_DIREITA, MoverDireita
	JMP FimMoverJogadorDireita
    
	MoverDireita:
		MOV B,#2
		DIV AB
		MOV @R0,A
		
    FimMoverJogadorDireita:
        POP 0
        POP B
        POP ACC
        RETI
;*******************************************************************************
;*******************************************************************************
 
;*******************************************************************************
VerificarObstaculos:
    PUSH ACC			; Guarda o conte�ddo do registo ACC
	PUSH 0
	PUSH 1
    PUSH B
    
    MOV TH0, #TEMPO_HIGH;		; Timer 0 = 50 ms
    MOV TL0, #TEMPO_LOW;		; Verifica se j� passou 1 segundo
    DJNZ TempoObstaculos, fimVerificarObstaculos
    
    ReinicializarDificuldade:
        MOV TempoObstaculos, DificuldadeAtual
        
    VerificarColisoes:
		MOV A, #ImagemX
		ADD A, #POS_JOGADOR
        MOV B, A
        DEC B
        
        MOV R0, A
        MOV A, @R0
        MOV R0, B
        MOV B, @R0
		
		ANL A, B
		JZ MoverObstaculos
        
        DecrementarVidas:
        DEC VidasRestantes

	MoverObstaculos:
;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;
		
FimVerificarObstaculos:
    POP B
    POP 1
    POP 0
    POP ACC				; Rep�e o conte�ddo do registo ACC
    RETI
;*******************************************************************************

;*******************************************************************************
;*******************************************************************************
VarrerDisplay:
    PUSH ACC			; Guarda o conte�do do registo A
    PUSH 0				; Guarda o conte�do do registo R0

	MOV A, #ImagemX		; Apontador para a primeira linha
	ADD A, LinhaAtual			; Apontador para a linha a mostrar no display
	MOV R0, A			; Apontador para a linha do display
    
    MOV A, LinhaAtiva
	
	MOV P1, #VAZIO		; Desliga a selec��o de todas as linhas
	MOV P2, @R0			; Actualiza a informa��o da coluna
	MOV P1, A			; Selecciona a linha

	INC LinhaAtual			; Passa para a pr�xima linha
    RL A
    MOV LinhaAtiva, A
    MOV A, LinhaAtual
	CJNE A, #NR_LINHAS, FimVarrerDisplay
	MOV LinhaAtual, #0			; Pr�xima linha a mostrar
    MOV LinhaAtiva, #LINHAATIVA_INICIAL
    
    FimVarrerDisplay:
        POP 0				; Rep�e o conte�do do registo R0
        POP ACC				; Rep�e o conte�do do registo A
        RETI
;*******************************************************************************
;*******************************************************************************
DesligarInterrupcoes:
    CLR TR0
    RET
;*******************************************************************************
;*******************************************************************************
GameOver:
    MOV NovaImagem, #IMAGEM_GAMEOVER
    CALL DesenharNovaImagem
    CALL DesligarInterrupcoes
    JMP EndLoop

Victory:
    MOV NovaImagem, #IMAGEM_VICTORY
    CALL DesenharNovaImagem
    CALL DesligarInterrupcoes
    JMP EndLoop

EndLoop: JMP EndLoop
;*******************************************************************************
;*******************************************************************************
Jogar:
    MOV TempoObstaculos, DificuldadeAtual
    
    InicializarJogador:
        MOV A, #ImagemX		; Apontador para a primeira linha
        ADD A, #POS_JOGADOR			; Apontador para a linha a mostrar no display
        MOV R0, A
        MOV @R0, #POS_JOGADOR_INICIAL 
        
    InicializarObstaculos:
        MOV ObstaculosInicio, #0
        MOV R0, NivelAtual
        DEC R0
        MOV NovaImagem, R0
        CALL DesenharNovaImagem
    
    CicloJogar:
        MOV A, VidasRestantes
        JZ fimCicloJogar
        MOV A, ObstaculosInicio
        MOV B, #NR_LINHAS
        DEC B
        CJNE A, B, CicloJogar
        
    fimCicloJogar:    
        MOV A, VidasRestantes
        JNZ FimJogar
        JMP GameOver
    
    fimJogar:
        INC NivelAtual
        RET
;*******************************************************************************
;*******************************************************************************
; Imagens a mostrar no display
Imagens:
DB 3, 2, 4, 1, 5, 2		; N�vel 1
DB 4, 3, 2, 6, 0, 0		; N�vel 2
DB 7, 6, 2, 6, 0, 0		; N�vel 3
DB 8, 2, 3, 6, 0, 0		; N�vel 4
DB 1, 4, 4, 6, 0, 0		; N�vel 5  
DB 17,10,4,10,17,0      ; Game over
DB 31,31,31,31,31,31	; Vit�ria
;**************************************************************************

END