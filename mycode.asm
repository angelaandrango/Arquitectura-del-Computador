STACK SEGMENT PARA STACK
    DB 64 DUP(' ')
STACK ENDS

;--------------------------------------------------------------

DATA SEGMENT PARA 'DATA'
    
    ; === 1. VARIABLES DEL MENU ===
    MSG_TITLE DB 'FISH INVADERS', '$'
    MSG_EASY DB '  MODO FACIL', '$'
    MSG_HARD DB '  MODO DIFICIL', '$'
    MSG_EASY_SEL DB '>> MODO FACIL <<', '$'
    MSG_HARD_SEL DB '>> MODO DIFICIL <<', '$'
    MSG_INST_LINE1 DB 'COMO JUGAR:', '$'
    MSG_INST_LINE2 DB 'Flechas: Cambiar modo', '$'
    MSG_INST_LINE3 DB 'ENTER: Comenzar juego', '$'
    MSG_INST_LINE4 DB 'ESC: Salir', '$'
    MENU_OPTION DB 0
    GAME_STARTED DB 0
    
    ; === 2. VARIABLES DE CONFIGURACION ===
    WINDOW_WIDTH DW 140h
    WINDOW_HEIGHT DW 0C8h
    WINDOW_BOUNDS DW 6
    TIME_AUX DB 0
    
    ; === 3. VARIABLES DE ENEMIGOS ===
    ENEMY_SIZE DW 0Fh
    ENEMY_SPACING DW 0Ah
    ENEMY_START_X DW 20h
    ENEMY_START_Y DW 10h
    ENEMY_VELOCITY_X DW 03h
    ENEMY_DROP_Y DW 08h
    ENEMY_DIRECTION DB 1
    ROW_SPACING DW 12h
    ENEMY_ACTIVE DB 23 DUP(1)
    ENEMY_HITS DB 23 DUP(0)
    ENEMY_MAX_HITS DB 2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2

    
    ; === 4. VARIABLES DE LA NAVE ===
    NAVE_X DW 96h 
    NAVE_Y DW 0BEh
    NAVE_WIDTH DW 14h
    NAVE_HEIGHT DW 03h
    NAVE_VELOCITY DW 0Ah
    NAVE_LIVES DB 3
    NAVE_DESTROYED DB 0
    HIT_FLASH_TIMER DB 0
    HIT_FLASH_ACTIVE DB 0
    INVASION_DETECTED DB 0
    
    ; === 5. VARIABLES DE DISPAROS ===
    DISPARO_WIDTH DW 02h
    DISPARO_HEIGHT DW 06h
    DISPARO_VELOCITY DW 09h
    MAX_DISPAROS DW 10
    DISPARO_X DW 10 DUP(0)
    DISPARO_Y DW 10 DUP(0)
    DISPARO_ACTIVE DB 10 DUP(0)
    
    ; === 6. VARIABLES DE DISPARO ENEMIGO ===
    ENEMY_BULLET_X DW 0
    ENEMY_BULLET_Y DW 0
    ENEMY_BULLET_ACTIVE DB 0
    ENEMY_BULLET_WIDTH DW 02h
    ENEMY_BULLET_HEIGHT DW 06h
    ENEMY_BULLET_VELOCITY DW 0Ch
    ENEMY_SHOOT_TIMER DB 0
    ENEMY_SHOOT_DELAY DB 00
    
    ; === 7. VARIABLES DE ESCUDOS ===
    SHIELD_WIDTH DW 40h
    SHIELD_HEIGHT DW 07h
    SHIELD_WIDTH_INICIAL DW 40h
    SHIELD1_X DW 40h
    SHIELD1_Y DW 0A0h
    SHIELD1_HITS DB 0
    SHIELD1_MAX_HITS DB 7
    SHIELD1_ACTIVE DB 1
    SHIELD1_CURRENT_WIDTH DW 40h
    SHIELD2_X DW 0C0h
    SHIELD2_Y DW 0A0h
    SHIELD2_HITS DB 0
    SHIELD2_MAX_HITS DB 7
    SHIELD2_ACTIVE DB 1
    SHIELD2_CURRENT_WIDTH DW 40h
    
    ; === 8. VARIABLES DE PUNTUACION Y ESTADO ===
    SCORE DW 0
    GAME_WON DB 0
    
    ; === 9. MENSAJES DE TEXTO ===
    SCORE_STR DB 'SCORE: $'
    SCORE_VALUE DB '000$'
    MSG_GAME_OVER DB 'GAME OVER!', 0Dh, 0Ah, '$'
    MSG_YOU_WIN DB 'YOU WIN!', 0Dh, 0Ah, '$'
    MSG_FINAL_SCORE DB 'SCORE FINAL: $'
    MSG_OPTION_RETRY DB 'F - Volver a intentar', 0Dh, 0Ah, '$'
    MSG_OPTION_MENU DB 'M - Menu principal', 0Dh, 0Ah, '$'
    
DATA ENDS

;-------------------------------------------------------------

CODE SEGMENT PARA 'CODE'
    
    MAIN PROC FAR
            ASSUME CS:CODE,DS:DATA,SS:STACK
            ; Inicializacion del programa
            PUSH DS
            SUB AX,AX
            PUSH AX
            MOV AX, DATA
            MOV DS, AX
            POP AX   
            
            ; ===== MOSTRAR MENU PRINCIPAL =====
        SHOW_MENU:
            CALL CLEAR_SCREEN          ; Limpiar pantalla
            CALL DRAW_MENU             ; Dibujar menu
            CALL WAIT_MENU_INPUT       ; Esperar seleccion del usuario
            
            ; Configurar dificultad segun seleccion
            CMP MENU_OPTION, 0         ; Verificar si selecciono modo Facil
            JE SET_EASY_MODE           ; Saltar a configurar modo Facil
            
            ; === CONFIGURAR MODO DIFICIL ===
            MOV ENEMY_BULLET_VELOCITY, 0Fh    ; Velocidad bala enemiga rapida
            MOV ENEMY_SHOOT_DELAY, 04         ; Disparos mas frecuentes
            JMP START_GAME                    ; Empezar juego
            
        SET_EASY_MODE:
            ; === CONFIGURAR MODO FACIL ===
            MOV ENEMY_BULLET_VELOCITY, 06h    ; Velocidad bala enemiga lenta
            MOV ENEMY_SHOOT_DELAY, 20         ; Disparos menos frecuentes
            
        START_GAME:
            MOV GAME_STARTED, 1               ; Marcar juego como iniciado
            CALL CLEAR_SCREEN                 ; Limpiar pantalla para juego
            
; ============= LOOP PRINCIPAL DEL JUEGO =================
            
            
        CHECK_TIME: 
            ; Obtener tiempo del sistema
            MOV AH,2Ch
            INT 21h
            
            ; Verificar si ha cambiado el tiempo
            CMP DL,TIME_AUX                   ; Comparar con tiempo anterior
            JE CHECK_TIME                     ; Si no cambio, volver a verificar
             
            MOV TIME_AUX, DL                  ; Actualizar tiempo auxiliar
            CALL CLEAR_SCREEN                 ; Limpiar pantalla cada frame
            
            ; === LOGICA DE ENEMIGOS ===
            CALL MOVE_ENEMIES                 ; Mover enemigos
            CALL CHECK_ENEMY_INVASION         ; Verificar invasion
            CALL DRAW_ENEMIES                 ; Dibujar enemigos
            
            ; === LOGICA DE LA NAVE ===
            CALL MOVE_NAVE                    ; Mover nave del jugador
            CALL DRAW_NAVE                    ; Dibujar nave
            
            ; === LOGICA DE DISPAROS DEL JUGADOR ===
            CALL MOVE_DISPAROS                ; Mover disparos del jugador
            CALL CHECK_COLLISIONS             ; Verificar colisiones
            CALL DRAW_DISPAROS                ; Dibujar disparos
            
            ; === LOGICA DE ESCUDOS ===
            CALL CHECK_SHIELD_COLLISIONS      ; Colisiones disparos-escudos
            CALL CHECK_ENEMY_BULLET_SHIELD    ; Colisiones balas enemigas-escudos
            CALL DRAW_SHIELDS                 ; Dibujar escudos
            
            ; === LOGICA DE DISPAROS ENEMIGOS ===
            CALL ENEMY_SHOOT_LOGIC            ; Logica para que enemigos disparen
            CALL MOVE_ENEMY_BULLET            ; Mover bala enemiga
            CALL DRAW_ENEMY_BULLET            ; Dibujar bala enemiga
            CALL CHECK_ENEMY_BULLET_COLLISION ; Colision bala enemiga-nave
            
            ; === INTERFAZ DE USUARIO ===
            CALL DRAW_LIVES_COUNTER           ; Dibujar contador de vidas
            CALL DRAW_SCORE                   ; Dibujar puntuacion
            
            ; ===== VERIFICAR CONDICION DE VICTORIA =====
            CALL CHECK_VICTORY                ; Verificar si gano el juego
            
            CMP GAME_WON, 1                   ; Gano el juego
            JNE CHECK_GAME_OVER               ; No, verificar game over
            
            ; === JUGADOR GANO EL JUEGO ===
            CALL PLAY_VICTORY_SOUND           ; Reproducir sonido de victoria
            CALL SHOW_WIN_SCREEN              ; Mostrar pantalla de victoria
            CALL WAIT_FOR_RESTART_OR_MENU     ; Esperar entrada del usuario
            
            CMP AL, 1                         ; Presiono F (reintentar)
            JE RETRY_GAME_WIN                 ; Si, reiniciar juego
            
            ; Presiono M (menu) - volver al menu principal
            CALL RESET_GAME                   ; Reiniciar variables del juego
            JMP SHOW_MENU                     ; Volver al menu principal
            
        RETRY_GAME_WIN:
            CALL RESET_GAME                   ; Reiniciar variables del juego
            CALL CLEAR_SCREEN                 ; Limpiar pantalla
            JMP START_GAME                    ; Empezar nuevo juego con misma dificultad
            
        CHECK_GAME_OVER:
            ; ===== VERIFICAR CONDICION DE GAME OVER =====
            CMP NAVE_DESTROYED, 1             ; Nave destruida
            JNE CONTINUE_GAME                 ; No, continuar juego
            
            ; === GAME OVER DETECTADO ===
            CALL PLAY_EXPLOSION_SOUND         ; Reproducir sonido de explosion
            CALL SHOW_GAME_OVER_SCREEN        ; Mostrar pantalla de game over
            CALL WAIT_FOR_RESTART_OR_MENU     ; Esperar entrada del usuario
            
            CMP AL, 1                         ; Presiono F (reintentar)
            JE RETRY_GAME_OVER                ; Si, reiniciar juego
            
            ; Presiono M (menu) - volver al menu principal
            CALL RESET_GAME                   ; Reiniciar variables del juego
            JMP SHOW_MENU                     ; Volver al menu principal
            
        RETRY_GAME_OVER:
            CALL RESET_GAME                   ; Reiniciar variables del juego
            CALL CLEAR_SCREEN                 ; Limpiar pantalla
            JMP START_GAME                    ; Empezar nuevo juego con misma dificultad
            
        CONTINUE_GAME:
            JMP CHECK_TIME                    ; Continuar loop principal del juego
            
        RET              ; Retorno del procedimiento principal
    MAIN ENDP  

; ==============================================================
; SECCION 1: PROCEDIMIENTOS DE MOVIMIENTO
; ==============================================================


; MOVE_ENEMIES - Mueve todos los enemigos en pantalla
;---------------------------------------------------------------
 
    MOVE_ENEMIES PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            
            ; Verificar direccion actual de movimiento (1=derecha, 0=izquierda)
            CMP ENEMY_DIRECTION, 1
            JE CHECK_RIGHT_BOUND   ; Si va a la derecha, verificar limite derecho
            
            ; Verificar limite izquierdo
            MOV AX, ENEMY_START_X
            CMP AX, WINDOW_BOUNDS
            JLE CHANGE_DIRECTION   ; Si llego al limite, cambiar direccion
            JMP MOVE_HORIZONTAL    ; Si no, mover horizontalmente
        
        CHECK_RIGHT_BOUND:
            ; Calcular posicion del enemigo mas a la derecha
            MOV AX, ENEMY_START_X     
            MOV BX, ENEMY_SIZE
            ADD BX, ENEMY_SPACING     
            MOV CX, 10               ; 10 espacios entre enemigos (aprox)
        
        CalcLoop:
            ADD AX, BX              ; Sumar espacio entre enemigos
            LOOP CalcLoop
        
            ADD AX, ENEMY_SIZE      ; Sumar tamano del ultimo enemigo
        
            ; Calcular limite derecho de la pantalla
            MOV BX, WINDOW_WIDTH
            SUB BX, WINDOW_BOUNDS
        
            ; Verificar si llego al limite derecho
            CMP AX, BX
            JGE CHANGE_DIRECTION    ; Si llego al limite, cambiar direccion
            JMP MOVE_HORIZONTAL     ; Si no, mover horizontalmente
        
        CHANGE_DIRECTION:
            ; Cambiar direccion (derecha->izquierda o izquierda->derecha)
            XOR ENEMY_DIRECTION, 1
            
            ; Bajar una fila los enemigos
            MOV AX, ENEMY_DROP_Y
            ADD ENEMY_START_Y, AX
            
            JMP END_MOVE_ENEMIES
        
        MOVE_HORIZONTAL:
            ; Mover enemigos en la direccion actual
            MOV AX, ENEMY_VELOCITY_X
        
            ; Verificar direccion para decidir signo de la velocidad
            CMP ENEMY_DIRECTION, 1
            JE MOVE_RIGHT
        
            ; Si va a la izquierda, velocidad negativa
            NEG AX
            
        MOVE_RIGHT:
            ; Aplicar movimiento
            ADD ENEMY_START_X, AX
        
        END_MOVE_ENEMIES:
        
            POP CX
            POP BX
            POP AX
    RET
    MOVE_ENEMIES ENDP


; MOVE_NAVE - Controla el movimiento de la nave del jugador
; -------------------------------------------------------------
    MOVE_NAVE PROC NEAR
            ; Verificar si la nave esta destruida
            CMP NAVE_DESTROYED, 1
            JNE NAVE_CAN_MOVE
            JMP END_MOVE_NAVE
            
        NAVE_CAN_MOVE:
            ; Verificar si hay tecla presionada
            MOV AH, 01h
            INT 16h
            JNZ KEY_PRESSED        ; Si hay tecla, procesarla
            JMP END_MOVE_NAVE      ; Si no, salir
            
        KEY_PRESSED:
            ; Leer tecla del buffer
            MOV AH, 00h
            INT 16h
            
            ; Verificar tecla de disparo (G/g)
            CMP AL, 'G'
            JE DO_SHOOT
            CMP AL, 'g'
            JE DO_SHOOT
            
            ; Verificar tecla de mover derecha (D/d)
            CMP AL, 'D'
            JE DO_MOVE_RIGHT
            CMP AL, 'd'
            JE DO_MOVE_RIGHT
            
            ; Verificar tecla de mover izquierda (A/a)
            CMP AL, 'A'
            JE DO_MOVE_LEFT
            CMP AL, 'a'
            JE DO_MOVE_LEFT
            
            JMP END_MOVE_NAVE      ; Otra tecla, salir
            
        DO_MOVE_RIGHT:
            ; Calcular limite derecho de la pantalla
            MOV AX, WINDOW_WIDTH
            SUB AX, NAVE_WIDTH
            SUB AX, WINDOW_BOUNDS
            
            ; Verificar si puede moverse a la derecha
            CMP NAVE_X, AX
            JL DO_RIGHT_MOVE       ; Si puede, mover
            JMP END_MOVE_NAVE      ; Si no, salir
            
        DO_RIGHT_MOVE:
            ; Mover nave a la derecha
            MOV AX, NAVE_VELOCITY
            ADD NAVE_X, AX
            
            ; Verificar que no se paso del limite
            MOV AX, WINDOW_WIDTH
            SUB AX, NAVE_WIDTH
            SUB AX, WINDOW_BOUNDS
            CMP NAVE_X, AX
            JLE SKIP_RIGHT_ADJUST  ; Si esta dentro del limite, continuar
            
            ; Ajustar al limite exacto si se paso
            MOV NAVE_X, AX
            
        SKIP_RIGHT_ADJUST:
            JMP END_MOVE_NAVE
        
        DO_MOVE_LEFT:
            ; Verificar limite izquierdo
            MOV AX, WINDOW_BOUNDS
            CMP NAVE_X, AX
            JG DO_LEFT_MOVE        ; Si puede, mover
            JMP END_MOVE_NAVE      ; Si no, salir
            
        DO_LEFT_MOVE:
            ; Mover nave a la izquierda
            MOV AX, NAVE_VELOCITY
            SUB NAVE_X, AX
            
            ; Verificar que no se paso del limite
            MOV AX, WINDOW_BOUNDS
            CMP NAVE_X, AX
            JGE SKIP_LEFT_ADJUST   ; Si esta dentro del limite, continuar
            
            ; Ajustar al limite exacto si se paso
            MOV NAVE_X, AX
            
        SKIP_LEFT_ADJUST:
            JMP END_MOVE_NAVE
        
        DO_SHOOT:
            ; Intentar crear disparos
            PUSH SI
            PUSH DI
            
            MOV SI, 0
            MOV DI, 0
            
            ; Buscar slots disponibles para disparos (busca 2 slots consecutivos)
        BUSCAR_SLOTS:
            CMP DI, 9              ; Maximo indice para 2 slots consecutivos
            JGE NO_SLOTS           ; Si no hay slots, salir
            
            ; Verificar si slot actual esta libre
            MOV AL, DISPARO_ACTIVE[DI]
            CMP AL, 0
            JNE SIGUIENTE_SLOT
            
            ; Verificar si siguiente slot esta libre
            MOV AL, DISPARO_ACTIVE[DI+1]
            CMP AL, 0
            JNE SIGUIENTE_SLOT
            
            ; Encontro 2 slots consecutivos libres
            JMP CREAR_DISPAROS
            
        SIGUIENTE_SLOT:
            INC DI
            JMP BUSCAR_SLOTS
            
        NO_SLOTS:
            ; No hay slots disponibles
            POP DI
            POP SI
            JMP SKIP_SHOOT
            
        CREAR_DISPAROS:
            ; Crear dos disparos (doble canon)
            MOV SI, DI
            SHL SI, 1              ; Convertir indice a desplazamiento de word (x2)
            
            ; Primer disparo (canon izquierdo)
            MOV AX, NAVE_X
            ADD AX, 2              ; Ajuste de posicion
            MOV DISPARO_X[SI], AX  ; Posicion X
            
            MOV AX, NAVE_Y
            SUB AX, DISPARO_HEIGHT ; Posicion arriba de la nave
            MOV DISPARO_Y[SI], AX  ; Posicion Y
            
            MOV DISPARO_ACTIVE[DI], 1 ; Activar disparo
            
            ; Segundo disparo (canon derecho)
            ADD SI, 2              ; Siguiente posicion en array
            INC DI                 ; Siguiente indice
            
            MOV AX, NAVE_X
            ADD AX, NAVE_WIDTH
            SUB AX, DISPARO_WIDTH
            SUB AX, 2              ; Ajuste de posicion
            MOV DISPARO_X[SI], AX  ; Posicion X
            
            MOV AX, NAVE_Y
            SUB AX, DISPARO_HEIGHT ; Posicion arriba de la nave
            MOV DISPARO_Y[SI], AX  ; Posicion Y
            
            MOV DISPARO_ACTIVE[DI], 1 ; Activar disparo
            
            ; Reproducir sonido de disparo
            CALL PLAY_SHOOT_SOUND
            
            POP DI
            POP SI
        
        SKIP_SHOOT:
        END_MOVE_NAVE:
    RET
    MOVE_NAVE ENDP


; MOVE_DISPAROS - Mueve todos los disparos activos del jugador
; -------------------------------------------------------------
    MOVE_DISPAROS PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH SI
            
            MOV CX, 0              ; Inicializar contador
            
        LOOP_MOVE_DISPAROS:
            CMP CX, MAX_DISPAROS   ; Verificar si recorrio todos los disparos
            JGE FIN_LOOP_MOVE
            
            MOV BX, CX             ; Usar BX como indice
            
            ; Verificar si el disparo esta activo
            MOV AL, DISPARO_ACTIVE[BX]
            CMP AL, 0
            JE NEXT_DISPARO_MOVE   ; Si no esta activo, siguiente
            
            ; Calcular direccion en arrays de words
            MOV SI, CX
            SHL SI, 1              ; x2 para acceder a arrays de words
            
            ; Mover disparo hacia arriba (restar velocidad)
            MOV AX, DISPARO_VELOCITY
            SUB DISPARO_Y[SI], AX
            
            ; Verificar si el disparo salio de la pantalla (arriba)
            MOV AX, DISPARO_Y[SI]
            CMP AX, WINDOW_BOUNDS
            JG NEXT_DISPARO_MOVE   ; Si esta dentro, continuar
            
            ; Si salio, desactivarlo
            MOV DISPARO_ACTIVE[BX], 0
            
        NEXT_DISPARO_MOVE:
            INC CX                 ; Siguiente disparo
            JMP LOOP_MOVE_DISPAROS
            
        FIN_LOOP_MOVE:
            POP SI
            POP CX
            POP BX
            POP AX
      RET
    MOVE_DISPAROS ENDP



; MOVE_ENEMY_BULLET - Mueve la bala enemiga si esta activa
; ----------------------------------------------------------

    MOVE_ENEMY_BULLET PROC NEAR
        
            ; Verificar si la bala enemiga esta activa
            CMP ENEMY_BULLET_ACTIVE, 0
            JE END_MOVE_ENEMY_BULLET
            
            ; Mover bala hacia abajo (sumar velocidad)
            MOV AX, ENEMY_BULLET_VELOCITY
            ADD ENEMY_BULLET_Y, AX
            
            ; Verificar si la bala salio de la pantalla (abajo)
            MOV AX, ENEMY_BULLET_Y
            CMP AX, WINDOW_HEIGHT
            JGE DEACTIVATE_ENEMY_BULLET  ; Si salio, desactivar
            JMP END_MOVE_ENEMY_BULLET    ; Si no, continuar
            
        DEACTIVATE_ENEMY_BULLET:
            ; Desactivar bala enemiga
            MOV ENEMY_BULLET_ACTIVE, 0
            
        END_MOVE_ENEMY_BULLET:
      RET
    MOVE_ENEMY_BULLET ENDP




; ==============================================================
; SECCION 2: PROCEDIMIENTOS DE COLISION Y LOGICA
; ==============================================================


; CHECK_ENEMY_INVASION - Verifica si los enemigos han invadido
; -------------------------------------------------------------

    CHECK_ENEMY_INVASION PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            
            ; Verificar si ya se detecto invasion
            CMP INVASION_DETECTED, 1
            JE SKIP_INVASION_CHECK
            
            ; Verificar fila 3 (enemigos indices 15-22)
            MOV CX, 15
        CHECK_R3_LOOP:
            CMP CX, 23
            JGE CHECK_R2_START
            
            MOV BX, CX
            CMP ENEMY_ACTIVE[BX], 1   ; Verificar si enemigo esta activo
            JNE NEXT_R3
            
            ; Calcular posicion Y de fila 3
            MOV AX, ENEMY_START_Y
            MOV DX, ROW_SPACING
            SHL DX, 1                  ; x2 (dos filas abajo)
            ADD AX, DX
            ADD AX, ENEMY_SIZE         ; Borde inferior del enemigo
            
            ; Verificar si llego a la altura de la nave
            CMP AX, NAVE_Y
            JGE DO_INVASION            ; Si llego, invasion detectada
            
        NEXT_R3:
            INC CX
            JMP CHECK_R3_LOOP
            
        CHECK_R2_START:
            ; Verificar fila 2 (enemigos indices 8-14)
            MOV CX, 8
        CHECK_R2_LOOP:
            CMP CX, 15
            JGE CHECK_R1_START
            
            MOV BX, CX
            CMP ENEMY_ACTIVE[BX], 1    ; Verificar si enemigo esta activo
            JNE NEXT_R2
            
            ; Calcular posicion Y de fila 2
            MOV AX, ENEMY_START_Y
            ADD AX, ROW_SPACING        ; Una fila abajo
            ADD AX, ENEMY_SIZE         ; Borde inferior del enemigo
            
            ; Verificar si llego a la altura de la nave
            CMP AX, NAVE_Y
            JGE DO_INVASION            ; Si llego, invasion detectada
            
        NEXT_R2:
            INC CX
            JMP CHECK_R2_LOOP
            
        CHECK_R1_START:
            ; Verificar fila 1 (enemigos indices 0-7)
            MOV CX, 0
        CHECK_R1_LOOP:
            CMP CX, 8
            JGE SKIP_INVASION_CHECK
            
            MOV BX, CX
            CMP ENEMY_ACTIVE[BX], 1    ; Verificar si enemigo esta activo
            JNE NEXT_R1
            
            ; Calcular posicion Y de fila 1
            MOV AX, ENEMY_START_Y
            ADD AX, ENEMY_SIZE         ; Borde inferior del enemigo
            
            ; Verificar si llego a la altura de la nave
            CMP AX, NAVE_Y
            JGE DO_INVASION            ; Si llego, invasion detectada
            
        NEXT_R1:
            INC CX
            JMP CHECK_R1_LOOP
            
        DO_INVASION:
            ; Invasion detectada - Game Over
            MOV INVASION_DETECTED, 1
            MOV NAVE_LIVES, 0          ; Quitar todas las vidas
            MOV NAVE_DESTROYED, 1      ; Destruir nave
            
        SKIP_INVASION_CHECK:
        
            POP DX
            POP CX
            POP BX
            POP AX
      RET
    CHECK_ENEMY_INVASION ENDP



; CHECK_COLLISIONS - Verifica colisiones generales del juego
; -------------------------------------------------------------

    CHECK_COLLISIONS PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            PUSH SI
            PUSH DI
            
            MOV CX, 0                  ; Inicializar contador de disparos
            
        LOOP_DISPAROS_COL:
            CMP CX, 10                 ; Verificar todos los disparos (max 10)
            JGE FIN_CHECK_COL
            
            MOV BX, CX                 ; Indice del disparo
            CMP DISPARO_ACTIVE[BX], 0  ; Verificar si disparo esta activo
            JE NEXT_DISPARO_COL
            
            ; Obtener posicion del disparo
            MOV SI, CX
            SHL SI, 1                  ; x2 para arrays de words
            MOV DI, DISPARO_X[SI]      ; X del disparo
            MOV SI, DISPARO_Y[SI]      ; Y del disparo
            
            ; Verificar colision con todos los enemigos
            PUSH CX
            CALL CHECK_DISPARO_VS_ENEMIES
            POP CX
            
        NEXT_DISPARO_COL:
            INC CX
            JMP LOOP_DISPAROS_COL
            
        FIN_CHECK_COL:
        
            POP DI
            POP SI
            POP DX
            POP CX
            POP BX
            POP AX
      RET
    CHECK_COLLISIONS ENDP


; CHECK_DISPARO_VS_ENEMIES - Verifica colision de un disparo con enemigos
;------------------------------------------------------------------------

    CHECK_DISPARO_VS_ENEMIES PROC NEAR
            PUSH AX
            PUSH CX
            PUSH DX
            PUSH BP
            
            MOV CX, 0                  ; Contador de enemigos (fila 1)
            MOV DX, ENEMY_START_Y      ; Posicion Y de fila 1
            MOV BP, 0                  ; Offset horizontal (fila 1 centrada)
            
            ; ===== VERIFICAR FILA 1 DE ENEMIGOS (indices 0-7) =====
        CHECK_FILA1:
            CMP CX, 8
            JGE CHECK_FILA2_START
            
            PUSH BX
            MOV BX, CX
            MOV AL, ENEMY_ACTIVE[BX]   ; Verificar si enemigo esta activo
            POP BX
            CMP AL, 0
            JE NEXT_ENEMY_F1
            
            ; Calcular posicion X del enemigo
            PUSH CX
            PUSH DX
            MOV AX, ENEMY_SIZE
            ADD AX, ENEMY_SPACING      ; Espacio entre enemigos
            MOV DX, CX                 ; Indice como multiplicador
            IMUL DX                    ; AX = espacio * indice
            ADD AX, ENEMY_START_X      ; Posicion base X
            ADD AX, BP                 ; Offset de centrado
            POP DX
            
            ; Verificar colision
            PUSH CX
            MOV CX, AX                 ; CX = X del enemigo
            CALL CHECK_HIT
            POP CX
            
            CMP AL, 1                  ; Hubo colision?
            JE HIT_ENEMY_F1
            
            POP CX
            JMP NEXT_ENEMY_F1
            
        HIT_ENEMY_F1:
            POP CX
            PUSH BX
            MOV BX, CX
            INC ENEMY_HITS[BX]         ; Incrementar contador de impactos
            
            
            ; Verificar si el enemigo fue destruido
            MOV AL, ENEMY_HITS[BX]
            CMP AL, ENEMY_MAX_HITS[BX]
            POP BX
            JGE DESTROY_ENEMY_F1
            
            ; Enemigo dañado pero no destruido
            MOV DISPARO_ACTIVE[BX], 0  ; Desactivar disparo
            JMP NEXT_ENEMY_F1
            
        DESTROY_ENEMY_F1:
            ; Enemigo destruido
            PUSH BX
            MOV BX, CX
            MOV ENEMY_ACTIVE[BX], 0    ; Desactivar enemigo
            
            
            ; Reproducir sonido de explosion
            CALL PLAY_EXPLOSION_SOUND
            
            ; Actualizar puntuacion
            PUSH BX
            CALL UPDATE_SCORE
            POP BX
            
            POP BX
            MOV DISPARO_ACTIVE[BX], 0  ; Desactivar disparo
            
        NEXT_ENEMY_F1:
            INC CX
            JMP CHECK_FILA1
            
            ; ===== VERIFICAR FILA 2 DE ENEMIGOS (indices 8-14) =====
        CHECK_FILA2_START:
            MOV CX, 8
            MOV AX, ENEMY_START_Y
            ADD AX, ROW_SPACING        ; Una fila abajo
            MOV DX, AX
            
            ; Calcular offset para centrar fila 2 (7 enemigos en lugar de 8)
            MOV AX, ENEMY_SIZE
            ADD AX, ENEMY_SPACING
            SHR AX, 1                  ; Dividir entre 2 para centrar
            MOV BP, AX
            
        CHECK_FILA2:
            CMP CX, 15
            JGE CHECK_FILA3_START
            
            PUSH BX
            MOV BX, CX
            MOV AL, ENEMY_ACTIVE[BX]   ; Verificar si enemigo esta activo
            POP BX
            CMP AL, 0
            JE NEXT_ENEMY_F2
            
            ; Calcular posicion X del enemigo (fila 2)
            PUSH CX
            PUSH DX
            SUB CX, 8                  ; Indice relativo a fila 2 (0-6)
            MOV AX, ENEMY_SIZE
            ADD AX, ENEMY_SPACING
            MOV DX, CX                 ; Indice como multiplicador
            IMUL DX                    ; AX = espacio * indice
            ADD AX, ENEMY_START_X
            ADD AX, BP                 ; Offset de centrado
            POP DX
            
            ; Verificar colision
            PUSH CX
            MOV CX, AX                 ; CX = X del enemigo
            CALL CHECK_HIT
            POP CX
            
            CMP AL, 1                  ; ¿Hubo colision?
            JE HIT_ENEMY_F2
            
            POP CX
            JMP NEXT_ENEMY_F2
            
        HIT_ENEMY_F2:
            POP CX
            PUSH BX
            MOV BX, CX
            INC ENEMY_HITS[BX]         ; Incrementar contador de impactos
            
            
            ; Verificar si el enemigo fue destruido
            MOV AL, ENEMY_HITS[BX]
            CMP AL, ENEMY_MAX_HITS[BX]
            POP BX
            JGE DESTROY_ENEMY_F2
            
            ; Enemigo dañado pero no destruido
            MOV DISPARO_ACTIVE[BX], 0  ; Desactivar disparo
            JMP NEXT_ENEMY_F2
            
        DESTROY_ENEMY_F2:
            ; Enemigo destruido
            PUSH BX
            MOV BX, CX
            MOV ENEMY_ACTIVE[BX], 0    ; Desactivar enemigo
            
            
            ; Reproducir sonido de explosion
            CALL PLAY_EXPLOSION_SOUND
            
            ; Actualizar puntuacion
            PUSH BX
            CALL UPDATE_SCORE
            POP BX
            
            POP BX
            MOV DISPARO_ACTIVE[BX], 0  ; Desactivar disparo
            
        NEXT_ENEMY_F2:
            INC CX
            JMP CHECK_FILA2
            
            ; ===== VERIFICAR FILA 3 DE ENEMIGOS (indices 15-22) =====
        CHECK_FILA3_START:
            MOV CX, 15
            MOV AX, ENEMY_START_Y
            MOV DX, ROW_SPACING
            SHL DX, 1                  ; x2 (dos filas abajo)
            ADD AX, DX
            MOV DX, AX
            MOV BP, 0                  ; Sin offset (fila completa)
            
        CHECK_FILA3:
            CMP CX, 23
            JGE FIN_CHECK_ENEMIES
            
            PUSH BX
            MOV BX, CX
            MOV AL, ENEMY_ACTIVE[BX]   ; Verificar si enemigo esta activo
            POP BX
            CMP AL, 0
            JE NEXT_ENEMY_F3
            
            ; Calcular posicion X del enemigo (fila 3)
            PUSH CX
            PUSH DX
            SUB CX, 15                 ; Indice relativo a fila 3 (0-7)
            MOV AX, ENEMY_SIZE
            ADD AX, ENEMY_SPACING
            MOV DX, CX                 ; Indice como multiplicador
            IMUL DX                    ; AX = espacio * indice
            ADD AX, ENEMY_START_X
            ADD AX, BP
            POP DX
            
            ; Verificar colision
            PUSH CX
            MOV CX, AX                 ; CX = X del enemigo
            CALL CHECK_HIT
            POP CX
            
            CMP AL, 1                  ; ¿Hubo colision?
            JE HIT_ENEMY_F3
            
            POP CX
            JMP NEXT_ENEMY_F3
            
        HIT_ENEMY_F3:
            POP CX
            PUSH BX
            MOV BX, CX
            INC ENEMY_HITS[BX]         ; Incrementar contador de impactos
            
            
            ; Verificar si el enemigo fue destruido
            MOV AL, ENEMY_HITS[BX]
            CMP AL, ENEMY_MAX_HITS[BX]
            POP BX
            JGE DESTROY_ENEMY_F3
            
            ; Enemigo dañado pero no destruido
            MOV DISPARO_ACTIVE[BX], 0  ; Desactivar disparo
            JMP NEXT_ENEMY_F3
            
        DESTROY_ENEMY_F3:
            ; Enemigo destruido
            PUSH BX
            MOV BX, CX
            MOV ENEMY_ACTIVE[BX], 0    ; Desactivar enemigo
            
            
            ; Reproducir sonido de explosion
            CALL PLAY_EXPLOSION_SOUND
            
            ; Actualizar puntuacion
            PUSH BX
            CALL UPDATE_SCORE
            POP BX
            
            POP BX
            MOV DISPARO_ACTIVE[BX], 0  ; Desactivar disparo
            
        NEXT_ENEMY_F3:
            INC CX
            JMP CHECK_FILA3
            
        FIN_CHECK_ENEMIES:
            POP BP
            POP DX
            POP CX
            POP AX
        RET
    CHECK_DISPARO_VS_ENEMIES ENDP



; CHECK_HIT - Verifica colision entre un punto y un enemigo
; ------------------------------------------------------------

    CHECK_HIT PROC NEAR
            ; DI = X del disparo, SI = Y del disparo
            ; CX = X del enemigo, DX = Y del enemigo
            PUSH BX
            PUSH CX
            PUSH DX
            
            ; Verificar colision en eje X (izquierda)
            CMP DI, CX
            JL NO_HIT
            
            ; Verificar colision en eje X (derecha)
            MOV AX, CX
            ADD AX, ENEMY_SIZE
            CMP DI, AX
            JGE NO_HIT
            
            ; Verificar colision en eje Y (arriba)
            CMP SI, DX
            JL NO_HIT
            
            ; Verificar colision en eje Y (abajo)
            MOV AX, DX
            ADD AX, ENEMY_SIZE
            CMP SI, AX
            JGE NO_HIT
            
            ; COLISION DETECTADA
            MOV AL, 1
            JMP END_CHECK_HIT
            
        NO_HIT:
            ; NO HUBO COLISION
            MOV AL, 0
            
        END_CHECK_HIT:
            POP DX
            POP CX
            POP BX
      RET
    CHECK_HIT ENDP



; CHECK_ENEMY_BULLET_COLLISION - Verifica colision bala enemiga-nave
; -------------------------------------------------------------------

    CHECK_ENEMY_BULLET_COLLISION PROC NEAR
            ; Verificar si bala enemiga esta activa
            CMP ENEMY_BULLET_ACTIVE, 0
            JE END_CHECK_ENEMY_COLLISION
            
            ; Verificar si nave esta destruida
            CMP NAVE_DESTROYED, 1
            JE END_CHECK_ENEMY_COLLISION
            
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            PUSH SI
            PUSH DI
            
            ; ===== COLISION RECTANGULO vs RECTANGULO =====
            
            ; Calcular limites de la BALA ENEMIGA
            MOV SI, ENEMY_BULLET_X              ; SI = bala_izquierda
            MOV DI, SI
            ADD DI, ENEMY_BULLET_WIDTH          ; DI = bala_derecha
            
            MOV CX, ENEMY_BULLET_Y              ; CX = bala_arriba
            MOV DX, CX
            ADD DX, ENEMY_BULLET_HEIGHT         ; DX = bala_abajo
            
            ; Calcular limites de la NAVE
            MOV AX, NAVE_X                      ; AX = nave_izquierda
            MOV BX, AX
            ADD BX, NAVE_WIDTH                  ; BX = nave_derecha
            
            ; VERIFICAR COLISION EN EJE X
            ; No colisiona si: bala_derecha < nave_izquierda
            CMP DI, AX
            JL NO_COLLISION_ENEMY
            
            ; No colisiona si: bala_izquierda > nave_derecha
            CMP SI, BX
            JG NO_COLLISION_ENEMY
            
            ; VERIFICAR COLISION EN EJE Y
            MOV AX, NAVE_Y                      ; AX = nave_arriba
            MOV BX, AX
            ADD BX, NAVE_HEIGHT                 ; BX = nave_abajo
            
            ; No colisiona si: bala_abajo < nave_arriba
            CMP DX, AX
            JL NO_COLLISION_ENEMY
            
            ; No colisiona si: bala_arriba > nave_abajo
            CMP CX, BX
            JG NO_COLLISION_ENEMY
            
            ; ===== ¡COLISION DETECTADA! =====
            
            ; Desactivar bala enemiga
            MOV ENEMY_BULLET_ACTIVE, 0
            
            ; Decrementar vidas de la nave
            DEC NAVE_LIVES
            
            ; Reproducir sonido de explosion
            CALL PLAY_EXPLOSION_SOUND
            
            ; Activar efecto visual de parpadeo
            MOV HIT_FLASH_ACTIVE, 1
            MOV HIT_FLASH_TIMER, 5
            
            ; Verificar si quedan vidas
            CMP NAVE_LIVES, 0
            JG NO_COLLISION_ENEMY       ; Si quedan vidas, continuar
            
            ; Game Over - destruir nave
            MOV NAVE_DESTROYED, 1
            
        NO_COLLISION_ENEMY:
            POP DI
            POP SI
            POP DX
            POP CX
            POP BX
            POP AX
            
        END_CHECK_ENEMY_COLLISION:
      RET
    CHECK_ENEMY_BULLET_COLLISION ENDP


; CHECK_SHIELD_COLLISIONS - Verifica colisiones disparos-escudos
; ---------------------------------------------------------------
    CHECK_SHIELD_COLLISIONS PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH SI
            
            MOV CX, 0                  ; Contador de disparos
            
        LOOP_DISPAROS_SHIELDS:
            CMP CX, 10
            JGE END_CHECK_SHIELDS
            
            MOV BX, CX
            CMP DISPARO_ACTIVE[BX], 0  ; Verificar si disparo esta activo
            JE NEXT_DISPARO_SHIELD
            
            MOV SI, CX
            SHL SI, 1                  ; x2 para arrays de words
            
            ; Verificar colision con ESCUDO 1
            CMP SHIELD1_ACTIVE, 1
            JNE CHECK_SHIELD2_DISP
            
            PUSH CX
            MOV CX, DISPARO_X[SI]      ; X del disparo
            MOV DX, DISPARO_Y[SI]      ; Y del disparo
            CALL CHECK_HIT_SHIELD1
            POP CX
            
            CMP AL, 1                  ; Hubo colision?
            JNE CHECK_SHIELD2_DISP
            
            ; Colision con escudo 1
            MOV DISPARO_ACTIVE[BX], 0  ; Desactivar disparo
            INC SHIELD1_HITS           ; Incrementar dano al escudo
            
            ; Actualizar tamano del escudo (dano visual)
            CALL UPDATE_SHIELD1_WIDTH
            
            ; Verificar si escudo fue destruido
            MOV AL, SHIELD1_HITS
            CMP AL, SHIELD1_MAX_HITS
            JL NEXT_DISPARO_SHIELD
            
            ; Escudo destruido
            MOV SHIELD1_ACTIVE, 0
            JMP NEXT_DISPARO_SHIELD
            
        CHECK_SHIELD2_DISP:
            ; Verificar colision con ESCUDO 2
            CMP SHIELD2_ACTIVE, 1
            JNE NEXT_DISPARO_SHIELD
            
            MOV SI, CX
            SHL SI, 1                  ; x2 para arrays de words
            PUSH CX
            MOV CX, DISPARO_X[SI]      ; X del disparo
            MOV DX, DISPARO_Y[SI]      ; Y del disparo
            CALL CHECK_HIT_SHIELD2
            POP CX
            
            CMP AL, 1                  ; Hubo colision?
            JNE NEXT_DISPARO_SHIELD
            
            ; Colision con escudo 2
            MOV DISPARO_ACTIVE[BX], 0  ; Desactivar disparo
            INC SHIELD2_HITS           ; Incrementar dano al escudo
            
            ; Actualizar tamano del escudo (dano visual)
            CALL UPDATE_SHIELD2_WIDTH
            
            ; Verificar si escudo fue destruido
            MOV AL, SHIELD2_HITS
            CMP AL, SHIELD2_MAX_HITS
            JL NEXT_DISPARO_SHIELD
            
            ; Escudo destruido
            MOV SHIELD2_ACTIVE, 0
            
        NEXT_DISPARO_SHIELD:
            INC CX
            JMP LOOP_DISPAROS_SHIELDS
            
        END_CHECK_SHIELDS:
            POP SI
            POP CX
            POP BX
            POP AX
        RET
    CHECK_SHIELD_COLLISIONS ENDP



; CHECK_ENEMY_BULLET_SHIELD - Verifica colision bala enemiga-escudos
; -------------------------------------------------------------------

    CHECK_ENEMY_BULLET_SHIELD PROC NEAR
            ; Verificar si bala enemiga esta activa
            CMP ENEMY_BULLET_ACTIVE, 0
            JE END_CHECK_ENEMY_SHIELD
            
            PUSH AX
            PUSH CX
            PUSH DX
            
            ; Verificar colision con ESCUDO 1
            CMP SHIELD1_ACTIVE, 1
            JNE CHECK_S2_ENEMY
            
            MOV CX, ENEMY_BULLET_X      ; X de bala enemiga
            MOV DX, ENEMY_BULLET_Y      ; Y de bala enemiga
            CALL CHECK_HIT_SHIELD1
            
            CMP AL, 1                  ; ¿Hubo colision?
            JNE CHECK_S2_ENEMY
            
            ; Colision con escudo 1
            MOV ENEMY_BULLET_ACTIVE, 0 ; Desactivar bala
            INC SHIELD1_HITS           ; Incrementar daño al escudo
            
            ; Actualizar tamano del escudo (daño visual)
            CALL UPDATE_SHIELD1_WIDTH
            
            ; Verificar si escudo fue destruido
            MOV AL, SHIELD1_HITS
            CMP AL, SHIELD1_MAX_HITS
            JL END_CHECK_ENEMY_SHIELD_POP
            
            ; Escudo destruido
            MOV SHIELD1_ACTIVE, 0
            JMP END_CHECK_ENEMY_SHIELD_POP
            
        CHECK_S2_ENEMY:
            ; Verificar colision con ESCUDO 2
            CMP SHIELD2_ACTIVE, 1
            JNE END_CHECK_ENEMY_SHIELD_POP
            
            MOV CX, ENEMY_BULLET_X      ; X de bala enemiga
            MOV DX, ENEMY_BULLET_Y      ; Y de bala enemiga
            CALL CHECK_HIT_SHIELD2
            
            CMP AL, 1                  ; ¿Hubo colision?
            JNE END_CHECK_ENEMY_SHIELD_POP
            
            ; Colision con escudo 2
            MOV ENEMY_BULLET_ACTIVE, 0 ; Desactivar bala
            INC SHIELD2_HITS           ; Incrementar daño al escudo
            
            ; Actualizar tamano del escudo (daño visual)
            CALL UPDATE_SHIELD2_WIDTH
            
            ; Verificar si escudo fue destruido
            MOV AL, SHIELD2_HITS
            CMP AL, SHIELD2_MAX_HITS
            JL END_CHECK_ENEMY_SHIELD_POP
            
            ; Escudo destruido
            MOV SHIELD2_ACTIVE, 0
            
        END_CHECK_ENEMY_SHIELD_POP:
            POP DX
            POP CX
            POP AX
            
        END_CHECK_ENEMY_SHIELD:
      RET
    CHECK_ENEMY_BULLET_SHIELD ENDP



; CHECK_HIT_SHIELD1 - Verifica colision punto-escudo1
; ------------------------------------------------------------

    CHECK_HIT_SHIELD1 PROC NEAR
            ; CX = X del punto, DX = Y del punto
            PUSH BX
            PUSH CX
            PUSH DX
            
            ; Verificar colision en eje X (izquierda del escudo)
            CMP CX, SHIELD1_X
            JL NO_HIT_S1
            
            ; Verificar colision en eje X (derecha del escudo)
            MOV AX, SHIELD1_X
            ADD AX, SHIELD_WIDTH
            CMP CX, AX
            JGE NO_HIT_S1
            
            ; Verificar colision en eje Y (arriba del escudo)
            CMP DX, SHIELD1_Y
            JL NO_HIT_S1
            
            ; Verificar colision en eje Y (abajo del escudo)
            MOV AX, SHIELD1_Y
            ADD AX, SHIELD_HEIGHT
            CMP DX, AX
            JGE NO_HIT_S1
            
            ; COLISION DETECTADA
            MOV AL, 1
            JMP END_HIT_S1
            
        NO_HIT_S1:
            ; NO HUBO COLISION
            MOV AL, 0
            
        END_HIT_S1:
            POP DX
            POP CX
            POP BX
      RET
    CHECK_HIT_SHIELD1 ENDP



; CHECK_HIT_SHIELD2 - Verifica colision punto-escudo2
; -------------------------------------------------------------

    CHECK_HIT_SHIELD2 PROC NEAR
            ; CX = X del punto, DX = Y del punto
            PUSH BX
            PUSH CX
            PUSH DX
            
            ; Verificar colision en eje X (izquierda del escudo)
            CMP CX, SHIELD2_X
            JL NO_HIT_S2
            
            ; Verificar colision en eje X (derecha del escudo)
            MOV AX, SHIELD2_X
            ADD AX, SHIELD_WIDTH
            CMP CX, AX
            JGE NO_HIT_S2
            
            ; Verificar colision en eje Y (arriba del escudo)
            CMP DX, SHIELD2_Y
            JL NO_HIT_S2
            
            ; Verificar colision en eje Y (abajo del escudo)
            MOV AX, SHIELD2_Y
            ADD AX, SHIELD_HEIGHT
            CMP DX, AX
            JGE NO_HIT_S2
            
            ; COLISION DETECTADA
            MOV AL, 1
            JMP END_HIT_S2
            
        NO_HIT_S2:
            ; NO HUBO COLISION
            MOV AL, 0
            
        END_HIT_S2:
            POP DX
            POP CX
            POP BX
      RET
    CHECK_HIT_SHIELD2 ENDP



; ENEMY_SHOOT_LOGIC - Controla cuando los enemigos disparan
; -----------------------------------------------------------

    ENEMY_SHOOT_LOGIC PROC NEAR
        ; Verificar si ya hay una bala enemiga activa
        CMP ENEMY_BULLET_ACTIVE, 1
        JNE CONTINUE_SHOOT_LOGIC
        JMP END_SHOOT_LOGIC
        
    CONTINUE_SHOOT_LOGIC:
        ; Incrementar timer de disparo
        INC ENEMY_SHOOT_TIMER
        
        ; Verificar si es tiempo de disparar
        MOV AL, ENEMY_SHOOT_TIMER
        CMP AL, ENEMY_SHOOT_DELAY
        JGE CHECK_ENEMY
        RET
        
    CHECK_ENEMY:
        ; Resetear timer de disparo
        MOV ENEMY_SHOOT_TIMER, 0
        
        ; Buscar un enemigo vivo aleatorio
        CALL FIND_RANDOM_ALIVE_ENEMY
        CMP AL, 0FFh                ; ¿Encontro enemigo?
        JNE FOUND_ENEMY
        RET                         ; No hay enemigos vivos
        
    FOUND_ENEMY:
        ; Configurar disparo desde el enemigo encontrado
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        
        MOV BL, AL                  ; Indice del enemigo
        XOR BH, BH
        
        ; Determinar fila del enemigo (0-7, 8-14, 15-22)
        CMP BL, 8
        JL ENEMY_SHOOT_ROW1
        CMP BL, 15
        JL ENEMY_SHOOT_ROW2
        JMP ENEMY_SHOOT_ROW3
        
    ENEMY_SHOOT_ROW1:
        ; Fila 1 (indices 0-7)
        XOR CX, CX
        MOV CL, BL
        MOV AX, ENEMY_SIZE
        ADD AX, ENEMY_SPACING
        MUL CX                      ; AX = espacio * indice
        ADD AX, ENEMY_START_X       ; Posicion X del enemigo
        MOV ENEMY_BULLET_X, AX
        
        MOV AX, ENEMY_START_Y       ; Posicion Y de fila 1
        JMP SHORT ACTIVATE_ENEMY_BULLET
        
    ENEMY_SHOOT_ROW2:
            ; Fila 2 (indices 8-14)
            SUB BL, 8                   ; Indice relativo a fila 2
            XOR BH, BH
            XOR CX, CX
            MOV CL, BL
            MOV AX, ENEMY_SIZE
            ADD AX, ENEMY_SPACING
            MUL CX                      ; AX = espacio * indice
            ADD AX, ENEMY_START_X
            MOV CX, AX
            
            ; Centrar (fila 2 tiene 7 enemigos en lugar de 8)
            MOV AX, ENEMY_SIZE
            ADD AX, ENEMY_SPACING
            SHR AX, 1                   ; Dividir entre 2
            ADD CX, AX
            MOV ENEMY_BULLET_X, CX
            
            MOV AX, ENEMY_START_Y
            ADD AX, ROW_SPACING         ; Una fila abajo
            JMP SHORT ACTIVATE_ENEMY_BULLET
            
        ENEMY_SHOOT_ROW3:
            ; Fila 3 (indices 15-22)
            SUB BL, 15                  ; Indice relativo a fila 3
            XOR BH, BH
            XOR CX, CX
            MOV CL, BL
            MOV AX, ENEMY_SIZE
            ADD AX, ENEMY_SPACING
            MUL CX                      ; AX = espacio * indice
            ADD AX, ENEMY_START_X
            MOV ENEMY_BULLET_X, AX
            
            MOV AX, ENEMY_START_Y
            ADD AX, ROW_SPACING
            ADD AX, ROW_SPACING         ; Dos filas abajo
            
        ACTIVATE_ENEMY_BULLET:
            ; Posicionar bala justo debajo del enemigo
            ADD AX, ENEMY_SIZE
            MOV ENEMY_BULLET_Y, AX
            
            ; Activar bala enemiga
            MOV ENEMY_BULLET_ACTIVE, 1
            
            POP DX
            POP CX
            POP BX
            POP AX
        
        END_SHOOT_LOGIC:
      RET
    ENEMY_SHOOT_LOGIC ENDP


; FIND_RANDOM_ALIVE_ENEMY - Encuentra un enemigo vivo aleatorio
;----------------------------------------------------------------
    FIND_RANDOM_ALIVE_ENEMY PROC NEAR
            PUSH BX
            PUSH CX
            PUSH DX
            
            ; Obtener valor aleatorio del reloj del sistema
            MOV AH, 2Ch
            INT 21h
            MOV AL, DL                  ; Usar centesimas de segundo como semilla
            
            ; Convertir a numero entre 0-22 (23 enemigos total)
            MOV CL, AL
            AND CL, 1Fh                 ; Mascara para 0-31
            CMP CL, 23
            JL SEARCH_START
            SUB CL, 23                  ; Ajustar si es mayor a 22
            
        SEARCH_START:
            MOV CH, 0                   ; Contador de intentos
            
        SEARCH_LOOP:
            CMP CH, 23                  ; Maximo 23 intentos (todos los enemigos)
            JGE NO_ENEMY_FOUND
            
            MOV BL, CL
            XOR BH, BH
            MOV AL, ENEMY_ACTIVE[BX]    ; Verificar si enemigo esta activo
            CMP AL, 1
            JE ENEMY_FOUND              ; Enemigo encontrado
            
            ; Siguiente enemigo
            INC CL
            CMP CL, 23
            JL SEARCH_CONTINUE
            MOV CL, 0                   ; Volver al inicio si llega al final
            
        SEARCH_CONTINUE:
            INC CH                      ; Incrementar contador de intentos
            JMP SEARCH_LOOP
            
        ENEMY_FOUND:
            ; Devolver indice del enemigo encontrado
            MOV AL, CL
            JMP END_FIND_ENEMY
            
        NO_ENEMY_FOUND:
            ; No hay enemigos vivos (devolver -1)
            MOV AL, 0FFh
            
        END_FIND_ENEMY:
            POP DX
            POP CX
            POP BX
        RET
    FIND_RANDOM_ALIVE_ENEMY ENDP



; CHECK_VICTORY - Verifica si el jugador gano el juego
; --------------------------------------------------------
    
    CHECK_VICTORY PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            
            ; Verificar si ya gano (evitar verificaciones innecesarias)
            CMP GAME_WON, 1
            JE END_CHECK_VICTORY
            
            ; Contar enemigos vivos
            MOV CX, 23
            MOV BX, 0
            
        COUNT_ENEMIES:
            CMP BX, 23                  ; Verificar todos los enemigos
            JGE NO_ENEMIES_LEFT
            
            MOV AL, ENEMY_ACTIVE[BX]    ; Verificar si enemigo esta activo
            CMP AL, 1
            JE ENEMY_STILL_ALIVE        ; Hay al menos un enemigo vivo
            
            INC BX
            JMP COUNT_ENEMIES
            
        ENEMY_STILL_ALIVE:
            ; Hay enemigos vivos - aun no gana
            JMP END_CHECK_VICTORY
            
        NO_ENEMIES_LEFT:
            ; ¡VICTORIA! No quedan enemigos vivos
            MOV GAME_WON, 1
            
        END_CHECK_VICTORY:
            POP CX
            POP BX
            POP AX
      RET
    CHECK_VICTORY ENDP


; ==============================================================
; SECCION 3: PROCEDIMIENTOS DE DIBUJO
; ==============================================================

; DRAW_ENEMIES - Dibuja todos los enemigos en pantalla
; -------------------------------------------------------------
    
    DRAW_ENEMIES PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            
            ; === DIBUJAR FILA 1 DE ENEMIGOS (indices 0-7) ===
            MOV CX, 8                  ; 8 enemigos en fila 1
            MOV BX, 0                  ; Indice inicial
            MOV DX, ENEMY_START_Y      ; Posicion Y de fila 1
            MOV SI, 0                  ; Offset horizontal (fila completa)
            
        DRAW_ROW1_LOOP:
            PUSH CX
            PUSH DX
            
            ; Verificar si enemigo esta activo
            MOV AL, ENEMY_ACTIVE[BX]
            CMP AL, 0
            JE SKIP_ENEMY_R1
            
            ; Calcular posicion X del enemigo
            MOV AX, ENEMY_SIZE
            ADD AX, ENEMY_SPACING      ; Espacio entre enemigos
            PUSH DX
            MOV DX, BX                 ; Indice como multiplicador
            IMUL DX                    ; AX = espacio * indice
            POP DX
            ADD AX, ENEMY_START_X
            ADD AX, SI                 ; Anadir offset
            MOV CX, AX                 ; CX = X del enemigo
            
            ; Dibujar enemigo
            PUSH BX
            PUSH SI
            CALL DRAW_SINGLE_ENEMY
            POP SI
            POP BX
            
        SKIP_ENEMY_R1:
            INC BX                     ; Siguiente enemigo
            POP DX
            POP CX
            LOOP DRAW_ROW1_LOOP
            
            ; === DIBUJAR FILA 2 DE ENEMIGOS (indices 8-14) ===
            MOV CX, 7                  ; 7 enemigos en fila 2
            MOV DX, ENEMY_START_Y
            ADD DX, ROW_SPACING        ; Una fila abajo
            
            ; Calcular offset para centrar fila 2
            MOV AX, ENEMY_SIZE
            ADD AX, ENEMY_SPACING
            SHR AX, 1                  ; Dividir entre 2
            MOV SI, AX
            
        DRAW_ROW2_LOOP:
            PUSH CX
            PUSH DX
            
            ; Verificar si enemigo esta activo
            MOV AL, ENEMY_ACTIVE[BX]
            CMP AL, 0
            JE SKIP_ENEMY_R2
            
            ; Calcular posicion X del enemigo (fila 2)
            PUSH BX
            SUB BX, 8                  ; Indice relativo a fila 2
            MOV AX, ENEMY_SIZE
            ADD AX, ENEMY_SPACING
            PUSH DX
            MOV DX, BX                 ; Indice como multiplicador
            IMUL DX                    ; AX = espacio * indice
            POP DX
            ADD AX, ENEMY_START_X
            ADD AX, SI                 ; Anadir offset de centrado
            MOV CX, AX                 ; CX = X del enemigo
            POP BX
            
            ; Dibujar enemigo
            PUSH BX
            PUSH SI
            CALL DRAW_SINGLE_ENEMY
            POP SI
            POP BX
            
        SKIP_ENEMY_R2:
            INC BX                     ; Siguiente enemigo
            POP DX
            POP CX
            LOOP DRAW_ROW2_LOOP
            
            ; === DIBUJAR FILA 3 DE ENEMIGOS (indices 15-22) ===
            MOV CX, 8                  ; 8 enemigos en fila 3
            MOV AX, ENEMY_START_Y
            MOV DX, ROW_SPACING
            SHL DX, 1                  ; x2 (dos filas abajo)
            ADD AX, DX
            MOV DX, AX                 ; DX = Y de fila 3
            MOV SI, 0                  ; Sin offset (fila completa)
            
        DRAW_ROW3_LOOP:
            PUSH CX
            PUSH DX
            
            ; Verificar si enemigo esta activo
            MOV AL, ENEMY_ACTIVE[BX]
            CMP AL, 0
            JE SKIP_ENEMY_R3
            
            ; Calcular posicion X del enemigo (fila 3)
            PUSH BX
            SUB BX, 15                 ; Indice relativo a fila 3
            MOV AX, ENEMY_SIZE
            ADD AX, ENEMY_SPACING
            PUSH DX
            MOV DX, BX                 ; Indice como multiplicador
            IMUL DX                    ; AX = espacio * indice
            POP DX
            ADD AX, ENEMY_START_X
            ADD AX, SI                 ; Anadir offset
            MOV CX, AX                 ; CX = X del enemigo
            POP BX
            
            ; Dibujar enemigo
            PUSH BX
            PUSH SI
            CALL DRAW_SINGLE_ENEMY
            POP SI
            POP BX
            
        SKIP_ENEMY_R3:
            INC BX                     ; Siguiente enemigo
            POP DX
            POP CX
            LOOP DRAW_ROW3_LOOP
            
            POP DX
            POP CX
            POP BX
            POP AX
      RET
    DRAW_ENEMIES ENDP


; DRAW_SINGLE_ENEMY - Dibuja un solo enemigo en pantalla
; ---------------------------------------------------------

    DRAW_SINGLE_ENEMY PROC NEAR
            ; Guardar registros en pila
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            PUSH SI
            PUSH DI
            
            ; Verificar si enemigo esta activo
            ; BX contiene el indice del enemigo
            CMP ENEMY_ACTIVE[BX], 0
            JE SKIP_DRAW_ENEMY_FISH    ; Saltar si enemigo no esta activo
            
            ; Todos los enemigos usan el mismo tipo de pez grande
            CALL DRAW_LARGE_FISH
            
        SKIP_DRAW_ENEMY_FISH:
            ; Restaurar registros desde pila
            POP DI
            POP SI
            POP DX
            POP CX
            POP BX
            POP AX
      RET
    DRAW_SINGLE_ENEMY ENDP


; DRAW_LARGE_FISH - Dibuja un pez de (8x8)
; ----------------------------------------------

    DRAW_LARGE_FISH PROC NEAR
            ; Guardar registros en pila
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            PUSH SI
            
            ; Guardar posicion X inicial en SI
            MOV SI, CX
            ; Guardar posicion Y inicial en pila temporalmente
            PUSH DX
            
            ; LINEA 1 (parte superior de la cola)
            ; Desplazar 3 pixeles a la derecha desde X inicial
            ADD CX, 3
            CALL DRAW_FISH_PIXEL    ; Pixel 1
            INC CX                  ; Mover a siguiente columna
            CALL DRAW_FISH_PIXEL    ; Pixel 2
            INC CX                  ; Mover a siguiente columna
            CALL DRAW_FISH_PIXEL    ; Pixel 3
            
            ; LINEA 2 (cola mas ancha)
            MOV CX, SI              ; Restaurar posicion X inicial
            INC DX                  ; Bajar una linea (Y+1)
            ADD CX, 2               ; Desplazar 2 pixeles a la derecha
            CALL DRAW_FISH_PIXEL    ; Pixel 1
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 2
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 3
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 4
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 5
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 6
            
            ; LINEA 3 (cuerpo con ojos)
            MOV CX, SI              ; Restaurar posicion X inicial
            INC DX                  ; Bajar otra linea (Y+2)
            ADD CX, 1               ; Desplazar 1 pixel a la derecha
            CALL DRAW_FISH_PIXEL    ; Pixel izquierdo del cuerpo
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel al lado del ojo
            INC CX
            ; Dibujar ojo (pixel blanco)
            MOV AL, 0Fh             ; Color blanco
            CALL DRAW_PIXEL_COLOR   ; Ojo del pez
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel despues del ojo
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 5
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 6
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 7
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 8
            
            ; LINEA 4 (cuerpo completo con aleta)
            MOV CX, SI              ; Restaurar posicion X inicial
            INC DX                  ; Bajar otra linea (Y+3)
            CALL DRAW_FISH_PIXEL    ; Aleta izquierda
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 2
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 3
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 4
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 5
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 6
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 7
            INC CX
            CALL DRAW_FISH_PIXEL    ; Aleta derecha
            
            ; LINEA 5 (cuerpo inferior)
            MOV CX, SI              ; Restaurar posicion X inicial
            INC DX                  ; Bajar otra linea (Y+4)
            ADD CX, 1               ; Desplazar 1 pixel a la derecha
            CALL DRAW_FISH_PIXEL    ; Pixel 1
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 2
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 3
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 4
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 5
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 6
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 7
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 8
            
            ; LINEA 6 (cola inferior)
            MOV CX, SI              ; Restaurar posicion X inicial
            INC DX                  ; Bajar otra linea (Y+5)
            ADD CX, 2               ; Desplazar 2 pixeles a la derecha
            CALL DRAW_FISH_PIXEL    ; Pixel 1
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 2
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 3
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 4
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 5
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 6
            
            ; LINEA 7 (punta de la cola)
            MOV CX, SI              ; Restaurar posicion X inicial
            INC DX                  ; Bajar otra linea (Y+6)
            ADD CX, 3               ; Desplazar 3 pixeles a la derecha
            CALL DRAW_FISH_PIXEL    ; Pixel 1
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 2
            INC CX
            CALL DRAW_FISH_PIXEL    ; Pixel 3
            
    END_LARGE_FISH:
            
            ; El primero recupera el DX guardado al principio
            POP SI
            POP DX
            POP DX    
            POP CX
            POP BX
            POP AX
      RET
    DRAW_LARGE_FISH ENDP


    DRAW_FISH_PIXEL PROC NEAR   ; Configura el color verde y llama a DRAW_PIXEL_COLOR
        MOV AL, 0Ah             ; Color verde para el cuerpo del pez
        JMP DRAW_PIXEL_COLOR    ; Saltar al procedimiento de dibujo
    DRAW_FISH_PIXEL ENDP



; DRAW_PIXEL_COLOR - Procedimiento general para dibujar pixeles
; -----------------------------------------------------------

    DRAW_PIXEL_COLOR PROC NEAR
        PUSH BX                 ; Guardar BX
        MOV AH, 0Ch             ; Funcion de BIOS: escribir pixel
        MOV BH, 00h             ; Pagina de video 0
        INT 10h                 ; Llamar a BIOS de video
        POP BX                  ; Restaurar BX
        RET
    DRAW_PIXEL_COLOR ENDP



; DRAW_NAVE - Dibuja la nave del jugador en pantalla
; --------------------------------------------------------------

    DRAW_NAVE PROC NEAR
            ; Verificar si la nave esta destruida
            CMP NAVE_DESTROYED, 1
            JE END_DRAW_SUBMARINE
            
            ; Verificar si hay efecto de parpadeo por dano
            CMP HIT_FLASH_ACTIVE, 1
            JNE DRAW_SUBMARINE_NORMAL
            
            ; Decrementar temporizador de parpadeo
            DEC HIT_FLASH_TIMER
            CMP HIT_FLASH_TIMER, 0
            JG DRAW_SUBMARINE_FLASH
            
            ; Desactivar efecto de parpadeo
            MOV HIT_FLASH_ACTIVE, 0
            JMP DRAW_SUBMARINE_NORMAL
            
        DRAW_SUBMARINE_FLASH:
            ; Parpadeo alternado (dibujar solo en frames impares)
            MOV AL, HIT_FLASH_TIMER
            AND AL, 1
            CMP AL, 0
            JE END_DRAW_SUBMARINE  ; Saltar dibujo en frames pares
            
        DRAW_SUBMARINE_NORMAL:
            ; Guardar registros en pila
            PUSH AX
            PUSH CX
            PUSH DX
            PUSH SI
            
            ; Obtener posicion de la nave
            MOV CX, NAVE_X
            MOV DX, NAVE_Y
            MOV SI, CX                  ; Guardar posicion X inicial en SI
            
            ; LINEA 1 (torre superior del submarino)
            ; Posicionar 4 pixeles desde la izquierda
            ADD CX, 4
            MOV BX, 12                  ; Dibujar 12 pixeles de ancho
        DRAW_SUB_LINE1:
            MOV AL, 0Dh                 ; Color magenta
            CALL DRAW_PIXEL_COLOR
            INC CX                      ; Mover al siguiente pixel horizontal
            DEC BX                      ; Decrementar contador
            JNZ DRAW_SUB_LINE1          ; Continuar hasta dibujar los 12 pixeles
            
            ; LINEA 2 (cuerpo medio con ventana)
            MOV CX, SI                  ; Restaurar posicion X inicial
            INC DX                      ; Bajar una linea (Y+1)
            ADD CX, 2                   ; Posicionar 2 pixeles desde la izquierda
            MOV BX, 6                   ; Dibujar 6 pixeles (lado izquierdo)
        DRAW_SUB_LINE2_LEFT:
            MOV AL, 0Dh                 ; Color magenta
            CALL DRAW_PIXEL_COLOR
            INC CX
            DEC BX
            JNZ DRAW_SUB_LINE2_LEFT
            
            ; Dibujar ventana (2 pixeles blancos)
            MOV AL, 0Fh                 ; Color blanco
            CALL DRAW_PIXEL_COLOR       ; Primer pixel de ventana
            INC CX
            CALL DRAW_PIXEL_COLOR       ; Segundo pixel de ventana
            INC CX
            
            ; Dibujar lado derecho del cuerpo
            MOV BX, 8                   ; Dibujar 8 pixeles (lado derecho)
        DRAW_SUB_LINE2_RIGHT:
            MOV AL, 0Dh                 ; Color magenta
            CALL DRAW_PIXEL_COLOR
            INC CX
            DEC BX
            JNZ DRAW_SUB_LINE2_RIGHT
            
            ; LINEA 3 (casco inferior completo)
            MOV CX, SI                  ; Restaurar posicion X inicial
            INC DX                      ; Bajar otra linea (Y+2)
            MOV BX, 20                  ; Dibujar 20 pixeles de ancho
        DRAW_SUB_LINE3:
            MOV AL, 0Dh                 ; Color magenta
            CALL DRAW_PIXEL_COLOR
            INC CX
            DEC BX
            JNZ DRAW_SUB_LINE3
            
            ; Restaurar registros desde pila
            POP SI
            POP DX
            POP CX
            POP AX
            
        END_DRAW_SUBMARINE:
       RET
    DRAW_NAVE ENDP
    


; DRAW_DISPAROS - Dibuja todos los disparos activos del jugador
; --------------------------------------------------------------
    DRAW_DISPAROS PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            PUSH SI
            
            MOV CX, 0                  ; Contador de disparos
            
        LOOP_DRAW_DISPAROS:
            CMP CX, MAX_DISPAROS       ; Verificar todos los disparos
            JGE FIN_LOOP_DRAW
            
            MOV BX, CX
            CMP DISPARO_ACTIVE[BX], 0  ; Verificar si disparo esta activo
            JE NEXT_DISPARO_DRAW
            
            ; Obtener posicion del disparo
            MOV SI, CX
            SHL SI, 1                  ; x2 para arrays de words
            PUSH CX
            MOV CX, DISPARO_X[SI]      ; X del disparo
            MOV DX, DISPARO_Y[SI]      ; Y del disparo
            CALL DRAW_SINGLE_DISPARO   ; Dibujar disparo
            POP CX
            
        NEXT_DISPARO_DRAW:
            INC CX                     ; Siguiente disparo
            JMP LOOP_DRAW_DISPAROS
            
        FIN_LOOP_DRAW:
            POP SI
            POP DX
            POP CX
            POP BX
            POP AX
      RET
    DRAW_DISPAROS ENDP
    


; DRAW_SINGLE_DISPARO - Dibuja un solo disparo del jugador
; -------------------------------------------------------------

    DRAW_SINGLE_DISPARO PROC NEAR
            ; CX = X inicial, DX = Y inicial
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            
            ; Guardar posiciones iniciales
            MOV BX, CX                 ; BX = X inicial
            MOV SI, DX                 ; SI = Y inicial
            
        DRAW_DISP_H:
            ; Dibujar pixel del disparo
            MOV AH, 0Ch
            MOV AL, 0Fh                ; Color blanco brillante
            MOV BH, 00h
            INT 10h
            
            ; Mover a siguiente pixel horizontal
            INC CX
            MOV AX, CX
            SUB AX, BX                 ; Calcular ancho dibujado
            CMP AX, DISPARO_WIDTH      ; Llego al ancho del disparo?
            JNG DRAW_DISP_H            ; Si no, continuar
            
            ; Volver a inicio de la linea y bajar una fila
            MOV CX, BX
            INC DX
            
            ; Verificar si llego a la altura completa
            MOV AX, DX
            SUB AX, SI                 ; Calcular alto dibujado
            CMP AX, DISPARO_HEIGHT     ; ¿Llego al alto del disparo?
            JNG DRAW_DISP_H            ; Si no, continuar
            
            POP DX
            POP CX
            POP BX
            POP AX
        RET
    DRAW_SINGLE_DISPARO ENDP



; DRAW_ENEMY_BULLET - Dibuja la bala enemiga si esta activa
; -----------------------------------------------------------

    DRAW_ENEMY_BULLET PROC NEAR
            ; Verificar si la bala enemiga esta activa
            CMP ENEMY_BULLET_ACTIVE, 0
            JE END_DRAW_ENEMY_BULLET
            
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            PUSH SI
            
            ; Obtener posicion de la bala enemiga
            MOV CX, ENEMY_BULLET_X     ; X de la bala
            MOV DX, ENEMY_BULLET_Y     ; Y de la bala
            
            ; Guardar posiciones iniciales
            MOV BX, CX                 ; BX = X inicial
            MOV SI, DX                 ; SI = Y inicial
            
        DRAW_ENEMY_BULLET_H:
            ; Dibujar pixel de la bala enemiga
            MOV AH, 0Ch
            MOV AL, 0Ch                ; Color rojo brillante
            MOV BH, 00h
            INT 10h
            
            ; Mover a siguiente pixel horizontal
            INC CX
            MOV AX, CX
            SUB AX, BX                 ; Calcular ancho dibujado
            CMP AX, ENEMY_BULLET_WIDTH ; ¿Llego al ancho de la bala?
            JNG DRAW_ENEMY_BULLET_H    ; Si no, continuar
            
            ; Volver a inicio de la linea y bajar una fila
            MOV CX, BX
            INC DX
            
            ; Verificar si llego a la altura completa
            MOV AX, DX
            SUB AX, SI                 ; Calcular alto dibujado
            CMP AX, ENEMY_BULLET_HEIGHT ; ¿Llego al alto de la bala?
            JNG DRAW_ENEMY_BULLET_H    ; Si no, continuar
            
            POP SI
            POP DX
            POP CX
            POP BX
            POP AX
            
        END_DRAW_ENEMY_BULLET:
        RET
    DRAW_ENEMY_BULLET ENDP
    
    


; DRAW_LIVES_COUNTER - Dibuja el contador de vidas en pantalla
; -------------------------------------------------------------

    DRAW_LIVES_COUNTER PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            PUSH SI
            
            ; Obtener numero de vidas restantes
            MOV AL, NAVE_LIVES
            MOV AH, 0
            MOV CX, AX                 ; CX = numero de vidas
            
            ; Verificar si hay vidas para dibujar
            CMP CX, 0
            JLE END_DRAW_LIVES
            
            ; Configurar posicion inicial
            MOV BX, 10                 ; X inicial (columna 10)
            MOV SI, 5                  ; Y inicial (fila 5)
            
        DRAW_LIFE_LOOP:
            CMP CX, 0                  ; Verificar si quedan vidas por dibujar
            JLE END_DRAW_LIVES
            
            PUSH CX
            
            ; Dibujar mini-nave (representacion de una vida)
            MOV CX, BX                 ; X de la mini-nave
            MOV DX, SI                 ; Y de la mini-nave
            
            ; Guardar posicion X inicial
            PUSH BX
            MOV BX, CX
            
            ; Dibujar mini-nave (4x2 pixeles)
        DRAW_MINI_H:
            MOV AH, 0Ch
            MOV AL, 0Dh                ; Color magenta (igual que la nave)
            PUSH BX
            MOV BH, 00h
            INT 10h
            POP BX
            
            ; Mover a siguiente pixel horizontal
            INC CX
            PUSH AX
            MOV AX, CX
            SUB AX, BX                 ; Calcular ancho dibujado
            CMP AX, 4                  ; Ancho de mini-nave = 4 pixeles
            POP AX
            JNG DRAW_MINI_H            ; Si no, continuar
            
            ; Volver a inicio de la linea y bajar una fila
            MOV CX, BX
            INC DX
            
            ; Verificar si llego a la altura completa
            PUSH AX
            MOV AX, DX
            SUB AX, SI                 ; Calcular alto dibujado
            CMP AX, 2                  ; Alto de mini-nave = 2 pixeles
            POP AX
            JNG DRAW_MINI_H            ; Si no, continuar
            
            ; Preparar para siguiente mini-nave
            POP BX
            ADD BX, 8                  ; Espacio entre mini-naves
            POP CX
            DEC CX                     ; Decrementar contador de vidas
            JMP DRAW_LIFE_LOOP
            
        END_DRAW_LIVES:
            POP SI
            POP DX
            POP CX
            POP BX
            POP AX
       RET
    DRAW_LIVES_COUNTER ENDP



; DRAW_SCORE - Dibuja la puntuacion en pantalla
; -------------------------------------------------------------

    DRAW_SCORE PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            
            ; Convertir puntuacion a string
            CALL CONVERT_SCORE_TO_STRING
            
            ; Posicionar cursor en esquina superior derecha
            MOV AH, 02h                ;Establecer posicion del cursor
            MOV BH, 00h
            MOV DH, 01h                ; Fila 1
            MOV DL, 10h                ; Columna 31
            INT 10h
            
            ; Cambiar color de fondo a amarillo
            MOV AH, 09h                ;Escribir caracter con atributo en posicion actual del cursor
            MOV AL, 20h                ; Espacio
            MOV BL, 0Eh                ; Amarillo brillante
            MOV CX, 1
            INT 10h
            
            ; Imprimir texto "SCORE: "
            LEA DX, SCORE_STR
            MOV AH, 09h
            INT 21h
            
            ; Imprimir valor de la puntuacion
            LEA DX, SCORE_VALUE
            MOV AH, 09h
            INT 21h
            
            POP DX
            POP CX
            POP BX
            POP AX
        RET
    DRAW_SCORE ENDP
    


; DRAW_SHIELDS - Dibuja los escudos en pantalla
; --------------------------------------------------------------
    DRAW_SHIELDS PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            PUSH SI
            
            ; === DIBUJAR ESCUDO 1 (izquierdo) ===
            CMP SHIELD1_ACTIVE, 1      ; Verificar si escudo 1 esta activo
            JNE SKIP_SHIELD1
            
            ; Configurar posicion y tamano del escudo 1
            MOV CX, SHIELD1_X          ; X del escudo
            MOV DX, SHIELD1_Y          ; Y del escudo
            MOV SI, SHIELD1_CURRENT_WIDTH ; Ancho actual (puede reducirse por daño)
            CALL DRAW_SINGLE_SHIELD    ; Dibujar escudo
            
        SKIP_SHIELD1:
            ; === DIBUJAR ESCUDO 2 (derecho) ===
            CMP SHIELD2_ACTIVE, 1      ; Verificar si escudo 2 esta activo
            JNE SKIP_SHIELD2
            
            ; Configurar posicion y tamano del escudo 2
            MOV CX, SHIELD2_X          ; X del escudo
            MOV DX, SHIELD2_Y          ; Y del escudo
            MOV SI, SHIELD2_CURRENT_WIDTH ; Ancho actual (puede reducirse por daño)
            CALL DRAW_SINGLE_SHIELD    ; Dibujar escudo
            
        SKIP_SHIELD2:
            POP SI
            POP DX
            POP CX
            POP BX
            POP AX
        RET
    DRAW_SHIELDS ENDP



; DRAW_SINGLE_SHIELD - Dibuja un solo escudo en pantalla
; -----------------------------------------------------------

    DRAW_SINGLE_SHIELD PROC NEAR
            ; CX = X inicial, DX = Y inicial, SI = ancho actual
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            PUSH DI
            
            ; Verificar si el escudo tiene ancho (no destruido completamente)
            CMP SI, 0
            JLE END_DRAW_SINGLE_SHIELD
            
            ; Centrar escudo (si el ancho se redujo por daño)
            MOV AX, SHIELD_WIDTH
            SUB AX, SI                 ; Diferencia de tamaño
            SHR AX, 1                  ; Dividir entre 2 para centrar
            ADD CX, AX                 ; Ajustar X para centrar
            
            ; Guardar posiciones iniciales
            MOV BX, CX                 ; BX = X inicial
            MOV DI, DX                 ; DI = Y inicial
            
        DRAW_SHIELD_H:
            ; Dibujar pixel del escudo
            MOV AH, 0Ch
            MOV AL, 0Bh                ; Color cyan
            PUSH BX
            MOV BH, 00h
            INT 10h
            POP BX
            
            ; Mover a siguiente pixel horizontal
            INC CX
            PUSH AX
            MOV AX, CX
            SUB AX, BX                 ; Calcular ancho dibujado
            CMP AX, SI                 ; ¿Llego al ancho actual del escudo?
            POP AX
            JNG DRAW_SHIELD_H          ; Si no, continuar
            
            ; Volver a inicio de la linea y bajar una fila
            MOV CX, BX
            INC DX
            
            ; Verificar si llego a la altura completa
            PUSH AX
            MOV AX, DX
            SUB AX, DI                 ; Calcular alto dibujado
            CMP AX, SHIELD_HEIGHT      ; ¿Llego al alto del escudo?
            POP AX
            JNG DRAW_SHIELD_H          ; Si no, continuar
            
        END_DRAW_SINGLE_SHIELD:
            POP DI
            POP DX
            POP CX
            POP BX
            POP AX
        RET
    DRAW_SINGLE_SHIELD ENDP
    
    
; ==============================================================
; SECCION 4: PROCEDIMIENTOS DEL MENU
; ==============================================================


; DRAW_MENU - Dibuja la pantalla del menu principal
; -------------------------------------------------------------

    DRAW_MENU PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            PUSH SI
            
            ; Limpiar pantalla
            MOV AH, 00h                ;Establecer modo video
            MOV AL, 13h                ; Modo video 320x200 256 colores
            INT 10h
            
            ; Configurar color de fondo
            MOV AH, 0Bh
            MOV BH, 00h
            MOV BL, 00h                
            INT 10h
            
            ; ===== DIBUJAR TITULO "FISH INVADERS" =====
            MOV AH, 02h                ; Funcion posicionar cursor
            MOV BH, 00h                ; Pagina 0
            MOV DH, 03h                ; Fila 3
            MOV DL, 0Dh                ; Columna 13
            INT 10h
            
            ; Imprimir titulo con color cyan brillante
            LEA SI, MSG_TITLE
            MOV AH, 0Eh                ; Funcion: Imprimir caracter
            MOV BL, 0Bh                ; Cyan brillante
        PRINT_TITLE:
            LODSB                      ; Cargar caracter de MSG_TITLE
            CMP AL, '$'                ; Verificar fin de string
            JE TITLE_DONE
            INT 10h                    ; Imprimir caracter
            JMP PRINT_TITLE
        TITLE_DONE:
            
            ; ===== DIBUJAR LINEA DECORATIVA =====
            MOV AH, 02h
            MOV BH, 00h
            MOV DH, 04h                ; Fila 4
            MOV DL, 0Ah                ; Columna 10
            INT 10h
            
            ; Dibujar linea de 20 signos '='
            MOV AH, 0Eh
            MOV AL, '='                ; Caracter de linea
            MOV BL, 0Eh                ; Amarillo
            MOV CX, 20                 ; 20 caracteres
        DRAW_LINE:
            INT 10h
            LOOP DRAW_LINE
            
            ; ===== VERIFICAR OPCION SELECCIONADA =====
            CMP MENU_OPTION, 0         ; ¿Modo Facil seleccionado?
            JE DRAW_EASY_SELECTED
            
            ; === DIBUJAR MODO DIFICIL SELECCIONADO ===
            
            ; Opcion 1 - MODO FACIL (NO seleccionado)
            MOV AH, 02h                ;Posicionar cursor
            MOV BH, 00h
            MOV DH, 07h                ; Fila 7
            MOV DL, 0Ch                ; Columna 12
            INT 10h
            
            LEA SI, MSG_EASY
            MOV AH, 0Eh
            MOV BL, 0Ah                ; Verde normal
        PRINT_EASY:
            LODSB
            CMP AL, '$'
            JE EASY_DONE
            INT 10h
            JMP PRINT_EASY
        EASY_DONE:
            
            ; Opcion 2 - MODO DIFICIL (SELECCIONADO)
            MOV AH, 02h
            MOV BH, 00h
            MOV DH, 09h                ; Fila 9
            MOV DL, 0Ah                ; Columna 10
            INT 10h
            
            LEA SI, MSG_HARD_SEL
            MOV AH, 0Eh
            MOV BL, 0Ch                ; Rojo brillante
        PRINT_HARD_SEL:
            LODSB
            CMP AL, '$'
            JE HARD_SEL_DONE
            INT 10h
            JMP PRINT_HARD_SEL
        HARD_SEL_DONE:
            JMP DRAW_4_INSTRUCTIONS    ; Saltar a instrucciones
            
        DRAW_EASY_SELECTED:
            ; === DIBUJAR MODO FACIL SELECCIONADO ===
            
            ; Opcion 1 - MODO FACIL (SELECCIONADO)
            MOV AH, 02h
            MOV BH, 00h
            MOV DH, 07h                ; Fila 7
            MOV DL, 0Ah                ; Columna 10
            INT 10h
            
            LEA SI, MSG_EASY_SEL
            MOV AH, 0Eh
            MOV BL, 0Ch                ; Rojo brillante
        PRINT_EASY_SEL:
            LODSB
            CMP AL, '$'
            JE EASY_SEL_DONE
            INT 10h
            JMP PRINT_EASY_SEL
        EASY_SEL_DONE:
            
            ; Opcion 2 - MODO DIFICIL (NO seleccionado)
            MOV AH, 02h
            MOV BH, 00h
            MOV DH, 09h                ; Fila 9
            MOV DL, 0Ch                ; Columna 12
            INT 10h
            
            LEA SI, MSG_HARD
            MOV AH, 0Eh
            MOV BL, 0Ah                ; Verde normal
        PRINT_HARD:
            LODSB
            CMP AL, '$'
            JE HARD_DONE
            INT 10h
            JMP PRINT_HARD
        HARD_DONE:
        
        DRAW_4_INSTRUCTIONS:
            ; ===== INSTRUCCION 1: "COMO JUGAR:" =====
            MOV AH, 02h
            MOV BH, 00h
            MOV DH, 0Ch                ; Fila 12
            MOV DL, 0Bh                ; Columna 11
            INT 10h
            
            LEA SI, MSG_INST_LINE1
            MOV AH, 0Eh
            MOV BL, 0Fh                ; Blanco brillante
        PRINT_LINE1:
            LODSB
            CMP AL, '$'
            JE LINE1_DONE
            INT 10h
            JMP PRINT_LINE1
        LINE1_DONE:
            
            ; ===== INSTRUCCION 2: "Flechas: Cambiar modo" =====
            MOV AH, 02h
            MOV BH, 00h
            MOV DH, 0Eh                ; Fila 14
            MOV DL, 07h                ; Columna 7
            INT 10h
            
            LEA SI, MSG_INST_LINE2
            MOV AH, 0Eh
            MOV BL, 07h                ; Gris claro
        PRINT_LINE2:
            LODSB
            CMP AL, '$'
            JE LINE2_DONE
            INT 10h
            JMP PRINT_LINE2
        LINE2_DONE:
            
            ; ===== INSTRUCCION 3: "ENTER: Comenzar juego" =====
            MOV AH, 02h
            MOV BH, 00h
            MOV DH, 0Fh                ; Fila 15
            MOV DL, 07h                ; Columna 7
            INT 10h
            
            LEA SI, MSG_INST_LINE3
            MOV AH, 0Eh
            MOV BL, 07h                ; Gris claro
        PRINT_LINE3:
            LODSB
            CMP AL, '$'
            JE LINE3_DONE
            INT 10h
            JMP PRINT_LINE3
        LINE3_DONE:
            
            POP SI
            POP DX
            POP CX
            POP BX
            POP AX
        RET
    DRAW_MENU ENDP



; WAIT_MENU_INPUT - Espera y procesa la entrada del usuario en el menu
; ------------------------------------------------------------

    WAIT_MENU_INPUT PROC NEAR
        MENU_LOOP:
            ; Esperar tecla del usuario
            MOV AH, 00h
            INT 16h
            
            ; Verificar tecla FLECHA ARRIBA (codigo 48h)
            CMP AH, 48h
            JE SELECT_EASY
            
            ; Verificar tecla FLECHA ABAJO (codigo 50h)
            CMP AH, 50h
            JE SELECT_HARD
            
            ; Verificar tecla NUMERO 1 (Modo Facil)
            CMP AL, '1'
            JE SELECT_EASY_NUM
            
            ; Verificar tecla NUMERO 2 (Modo Dificil)
            CMP AL, '2'
            JE SELECT_HARD_NUM
            
            ; Verificar tecla ENTER (Iniciar juego)
            CMP AL, 0Dh
            JE START_SELECTED
            
            
            ; Tecla no reconocida, volver a esperar
            JMP MENU_LOOP
            
        SELECT_EASY:
        SELECT_EASY_NUM:
            ; Seleccionar Modo Facil
            MOV MENU_OPTION, 0
            CALL DRAW_MENU             ; Redibujar menu con nueva seleccion
            JMP MENU_LOOP              ; Volver a esperar entrada
            
        SELECT_HARD:
        SELECT_HARD_NUM:
            ; Seleccionar Modo Dificil
            MOV MENU_OPTION, 1
            CALL DRAW_MENU             ; Redibujar menu con nueva seleccion
            JMP MENU_LOOP              ; Volver a esperar entrada
            
        START_SELECTED:
            ; Iniciar juego - salir del procedimiento
            RET
            
        EXIT_GAME:
            ; Salir del juego - terminar programa
            MOV AH, 4Ch                ; Funcion terminar programa
            MOV AL, 00h                ; Codigo de salida 0
            INT 21h
            
            ; Nunca deberia llegar aqui, pero por si acaso
            RET
    WAIT_MENU_INPUT ENDP    
 
 
; ==============================================================
; SECCION 5: PROCEDIMIENTOS DE PANTALLAS
; ==============================================================


; SHOW_WIN_SCREEN - Muestra la pantalla de victoria
; ------------------------------------------------------------

    SHOW_WIN_SCREEN PROC NEAR
        
            CALL CLEAR_SCREEN          ; Limpiar pantalla
            
            ; Configurar fondo para pantalla de victoria
            MOV AH, 00h
            MOV AL, 13h                ; Modo video 320x200 256 colores
            INT 10h
            
            MOV AH, 0Bh
            MOV BH, 00h
            MOV BL, 00h                ; negro como fondo
            INT 10h
            
            ; ===== DIBUJAR "YOU WIN!" =====
            MOV AH, 02h                ; Posicionar cursor
            MOV BH, 00h
            MOV DH, 08h                ; Fila 8
            MOV DL, 10h                ; Columna 16
            INT 10h
            
            ; Imprimir mensaje de victoria en amarillo brillante
            LEA SI, MSG_YOU_WIN
            MOV AH, 0Eh                ; Funcion teletype output
            MOV BL, 0Eh                ; Amarillo brillante
        PRINT_YOU_WIN:
            LODSB                      ; Cargar caracter
            CMP AL, '$'                ; Verificar fin de string
            JE YOU_WIN_DONE
            INT 10h                    ; Imprimir caracter
            JMP PRINT_YOU_WIN
        YOU_WIN_DONE:
        
            ; ===== DIBUJAR PUNTUACION FINAL =====
            CALL CONVERT_SCORE_TO_STRING ; Convertir puntuacion a string
            
            ; Imprimir texto "SCORE FINAL:" en blanco
            MOV AH, 02h
            MOV BH, 00h
            MOV DH, 0Ah                ; Fila 10
            MOV DL, 0Dh                ; Columna 13
            INT 10h
            
            LEA SI, MSG_FINAL_SCORE
            MOV AH, 0Eh
            MOV BL, 0Fh                ; Blanco brillante
        PRINT_FINAL_SCORE:
            LODSB
            CMP AL, '$'
            JE FINAL_SCORE_DONE
            INT 10h
            JMP PRINT_FINAL_SCORE
        FINAL_SCORE_DONE:
        
            ; Imprimir valor de la puntuacion en cyan
            MOV AH, 02h
            MOV BH, 00h
            MOV DH, 0Ah                ; Misma fila
            MOV DL, 18h                ; Columna 24 (despues del texto)
            INT 10h
            
            LEA SI, SCORE_VALUE
            MOV AH, 0Eh
            MOV BL, 0Bh                ; Cyan
        PRINT_SCORE_VALUE:
            LODSB
            CMP AL, '$'
            JE SCORE_VALUE_DONE
            INT 10h
            JMP PRINT_SCORE_VALUE
        SCORE_VALUE_DONE:
        
            ; ===== DIBUJAR OPCION "F - VOLVER A INTENTAR" =====
            MOV AH, 02h
            MOV BH, 00h
            MOV DH, 0Dh                ; Fila 13
            MOV DL, 0Ah                ; Columna 10
            INT 10h
            
            LEA SI, MSG_OPTION_RETRY
            MOV AH, 0Eh
            MOV BL, 0Ah                ; Verde
        PRINT_OPTION_RETRY:
            LODSB
            CMP AL, '$'
            JE OPTION_RETRY_DONE
            INT 10h
            JMP PRINT_OPTION_RETRY
        OPTION_RETRY_DONE:
        
            ; ===== DIBUJAR OPCION "M - MENU PRINCIPAL" =====
            MOV AH, 02h
            MOV BH, 00h
            MOV DH, 0Eh                ; Fila 14
            MOV DL, 0Ah                ; Columna 10
            INT 10h
            
            LEA SI, MSG_OPTION_MENU
            MOV AH, 0Eh
            MOV BL, 0Fh                ; Blanco brillante
        PRINT_OPTION_MENU:
            LODSB
            CMP AL, '$'
            JE OPTION_MENU_DONE
            INT 10h
            JMP PRINT_OPTION_MENU
        OPTION_MENU_DONE:
    
        RET
    SHOW_WIN_SCREEN ENDP
    
    

; SHOW_GAME_OVER_SCREEN - Muestra la pantalla de Game Over
; ------------------------------------------------------------

    SHOW_GAME_OVER_SCREEN PROC NEAR
            CALL CLEAR_SCREEN          ; Limpiar pantalla
            
            ; ===== DIBUJAR "GAME OVER!" EN ROJO =====
            MOV AH, 02h
            MOV BH, 00h
            MOV DH, 08h                ; Fila 8
            MOV DL, 0Fh                ; Columna 15
            INT 10h
            
            LEA SI, MSG_GAME_OVER
            MOV AH, 0Eh                ; Funcion teletype output
            MOV BL, 0Ch                ; Rojo
        PRINT_GAME_OVER:
            LODSB                      ; Cargar caracter
            CMP AL, '$'                ; Verificar fin de string
            JE GAME_OVER_DONE
            INT 10h                    ; Imprimir caracter
            JMP PRINT_GAME_OVER
        GAME_OVER_DONE:
            
            ; ===== DIBUJAR PUNTUACION FINAL =====
            CALL CONVERT_SCORE_TO_STRING ; Convertir puntuacion a string
            
            ; Configurar color amarillo para el texto de puntuacion
            MOV AH, 0Bh
            MOV BH, 00h
            MOV BL, 0Eh                ; Amarillo
            INT 10h
            
            ; Imprimir texto "SCORE FINAL:"
            MOV AH, 02h
            MOV DH, 0Ah                ; Fila 10
            MOV DL, 0Dh                ; Columna 13
            INT 10h
            
            LEA DX, MSG_FINAL_SCORE
            MOV AH, 09h                ; Funcion imprimir string
            INT 21h
            
            ; Imprimir valor de la puntuacion
            LEA DX, SCORE_VALUE
            MOV AH, 09h
            INT 21h
            
            ; ===== DIBUJAR OPCION "F - VOLVER A INTENTAR" =====
            MOV AH, 0Bh
            MOV BH, 00h
            MOV BL, 0Ah                ; Verde
            INT 10h
            
            MOV AH, 02h
            MOV DH, 0Dh                ; Fila 13
            MOV DL, 0Ah                ; Columna 10
            INT 10h
            
            LEA DX, MSG_OPTION_RETRY
            MOV AH, 09h
            INT 21h
            
            ; ===== DIBUJAR OPCION "M - MENU PRINCIPAL" =====
            MOV AH, 0Bh
            MOV BH, 00h
            MOV BL, 0Fh                ; Blanco
            INT 10h
            
            MOV AH, 02h
            MOV DH, 0Eh                ; Fila 14
            MOV DL, 0Ah                ; Columna 10
            INT 10h
            
            LEA DX, MSG_OPTION_MENU
            MOV AH, 09h
            INT 21h
        
        RET
    SHOW_GAME_OVER_SCREEN ENDP


; WAIT_FOR_RESTART_OR_MENU - Espera entrada en pantallas de fin de juego
; --------------------------------------------------------------

    WAIT_FOR_RESTART_OR_MENU PROC NEAR
            ; Este procedimiento espera a que el usuario presione:
            ; - F/f para reiniciar el juego
            ; - M/m para volver al menu principal
            
        WAIT_INPUT_LOOP:
            ; Esperar tecla del usuario
            MOV AH, 00h
            INT 16h
            
            ; Verificar tecla F (Reintentar/Reiniciar)
            CMP AL, 'F'
            JE KEY_F_PRESSED
            CMP AL, 'f'
            JE KEY_F_PRESSED
            
            ; Verificar tecla M (Menu principal)
            CMP AL, 'M'
            JE KEY_M_PRESSED
            CMP AL, 'm'
            JE KEY_M_PRESSED
            
            ; Tecla no reconocida, seguir esperando
            JMP WAIT_INPUT_LOOP
            
        KEY_F_PRESSED:
            ; Usuario presiono F - Retornar 1 en AL para indicar reinicio
            MOV AL, 1
            RET
            
        KEY_M_PRESSED:
            ; Usuario presiono M - Retornar 0 en AL para indicar volver al menu
            MOV AL, 0
        RET
        
    WAIT_FOR_RESTART_OR_MENU ENDP



; ==============================================================
; SECCION 6: PROCEDIMIENTOS DE UTILIDAD
; ==============================================================


; CLEAR_SCREEN - Limpia la pantalla y configura modo video
; -------------------------------------------------------------

    CLEAR_SCREEN PROC NEAR
        ; Configurar modo video 320x200 256 colores
        MOV AH, 00h                ;Establecer un modo de video
        MOV AL, 13h                ;Modo de video N13
        INT 10h
        
                                   ; Configurar color de fondo
        MOV AH, 0Bh                ;Funcion para cambiar colores
        MOV BH, 00h                ;Cambiar color de fondo
        MOV BL, 00h                ; Color negro
        INT 10h
        
        RET
    CLEAR_SCREEN ENDP


; RESET_GAME - Reinicia todas las variables del juego
; ------------------------------------------------------------

    RESET_GAME PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            
            ; Reiniciar puntuacion
            MOV SCORE, 0
            
            ; Reiniciar nave
            MOV NAVE_X, 96h            ; Posicion X inicial
            MOV NAVE_Y, 0BEh           ; Posicion Y inicial
            MOV NAVE_LIVES, 3          ; 3 vidas iniciales
            MOV NAVE_DESTROYED, 0      ; Nave no destruida
            MOV HIT_FLASH_TIMER, 0     ; Resetear timer de parpadeo
            MOV HIT_FLASH_ACTIVE, 0    ; Desactivar parpadeo
            MOV INVASION_DETECTED, 0   ; Resetear flag de invasion
            
            ; Reiniciar estado de victoria
            MOV GAME_WON, 0
            
            ; Reiniciar enemigos
            MOV ENEMY_START_X, 20h     ; Posicion X inicial
            MOV ENEMY_START_Y, 10h     ; Posicion Y inicial
            MOV ENEMY_DIRECTION, 1     ; Direccion inicial: derecha
            
            ; Reactivar todos los enemigos
            MOV CX, 23                 ; 23 enemigos en total
            MOV BX, 0                  ; Indice inicial
        RESET_ENEMIES_LOOP:
            MOV ENEMY_ACTIVE[BX], 1    ; Activar enemigo
            MOV ENEMY_HITS[BX], 0      ; Resetear contador de impactos
            
            
            INC BX                     ; Siguiente enemigo
            LOOP RESET_ENEMIES_LOOP
            
            ; Desactivar todos los disparos del jugador
            MOV CX, 10                 ; Maximo 10 disparos
            MOV BX, 0                  ; Indice inicial
        RESET_DISPAROS_LOOP:
            MOV DISPARO_ACTIVE[BX], 0  ; Desactivar disparo
            INC BX
            LOOP RESET_DISPAROS_LOOP
            
            ; Desactivar disparo enemigo
            MOV ENEMY_BULLET_ACTIVE, 0
            MOV ENEMY_SHOOT_TIMER, 0   ; Resetear timer de disparo enemigo
            
            ; Reiniciar escudos
            MOV SHIELD1_HITS, 0        ; Resetear daño del escudo 1
            MOV SHIELD1_ACTIVE, 1      ; Reactivar escudo 1
            MOV AX, SHIELD_WIDTH_INICIAL
            MOV SHIELD1_CURRENT_WIDTH, AX ; Restaurar ancho inicial
            
            MOV SHIELD2_HITS, 0        ; Resetear daño del escudo 2
            MOV SHIELD2_ACTIVE, 1      ; Reactivar escudo 2
            MOV SHIELD2_CURRENT_WIDTH, AX ; Restaurar ancho inicial
            
            POP CX
            POP BX
            POP AX
        RET
    RESET_GAME ENDP


; UPDATE_SCORE - Actualiza la puntuacion al destruir un enemigo
; -------------------------------------------------------------

    UPDATE_SCORE PROC NEAR
            ; BX debe contener el indice del enemigo destruido
            PUSH AX
            PUSH BX
            PUSH CX
            
            ; Determinar puntos segun fila del enemigo
            CMP BX, 8                  ; Enemigo en fila 1 (indices 0-7)?
            JL ENEMY_ROW1
            
            CMP BX, 15                 ; Enemigo en fila 2 (indices 8-14)?
            JL ENEMY_ROW2
            
            ; Enemigo en fila 3 (indices 15-22)
            JMP ENEMY_ROW3
            
        ENEMY_ROW1:
            ; Fila 1 = 2 puntos
            ADD SCORE, 2
            JMP END_UPDATE_SCORE
            
        ENEMY_ROW2:
            ; Fila 2 = 3 puntos
            ADD SCORE, 3
            JMP END_UPDATE_SCORE
            
        ENEMY_ROW3:
            ; Fila 3 = 2 puntos
            ADD SCORE, 2
            
        END_UPDATE_SCORE:
            POP CX
            POP BX
            POP AX
            RET
    UPDATE_SCORE ENDP
    
                           

; CONVERT_SCORE_TO_STRING - Convierte la puntuacion a string ASCII
; -----------------------------------------------------------------

    CONVERT_SCORE_TO_STRING PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            PUSH SI
            
            ; Convertir SCORE (word) a string de 2 digitos
            MOV AX, SCORE              ; Cargar puntuacion
            MOV SI, 2                  ; Empezar desde el ultimo digito (indice 2)
            MOV CX, 2                  ; 2 digitos a convertir
            
        CONVERT_LOOP:
            MOV DX, 0                  ; Limpiar DX para la division
            MOV BX, 10                 ; Divisor = 10
            DIV BX                     ; AX = AX / 10, DX = resto (0-9)
            
            ADD DL, '0'                ; Convertir digito a ASCII
            MOV SCORE_VALUE[SI], DL    ; Almacenar digito en string
            
            DEC SI                     ; Mover al digito anterior
            LOOP CONVERT_LOOP          ; Convertir siguiente digito
            
            ; Asegurar que los digitos sean visibles (no espacios)
            CMP SCORE_VALUE[0], '0'    ; Primer digito es '0'?
            JNE SCORE_CONVERT_DONE
            MOV SCORE_VALUE[0], ' '    ; Cambiar a espacio si es cero
            
        SCORE_CONVERT_DONE:
            POP SI
            POP DX
            POP CX
            POP BX
            POP AX
        RET
    CONVERT_SCORE_TO_STRING ENDP

    

; UPDATE_SHIELD1_WIDTH - Actualiza el ancho del escudo 1 segun dato
;---------------------------------------------------------------

    UPDATE_SHIELD1_WIDTH PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            
            ; Calcular cuantos hits le quedan al escudo
            MOV AL, SHIELD1_MAX_HITS   ; Maximo de hits (7)
            MOV CL, AL                 ; Guardar maximo en CL
            MOV AL, SHIELD1_HITS       ; Hits actuales
            SUB CL, AL                 ; CL = hits restantes
            
            CMP CL, 0                  ; ¿Escudo destruido?
            JLE SET_S1_ZERO
            
            ; Calcular nuevo ancho proporcional a hits restantes
            MOV AL, SHIELD1_MAX_HITS   ; Maximo de hits
            MOV AH, 0                  ; Convertir a word
            MOV DX, AX                 ; DX = max hits
            
            MOV AX, SHIELD_WIDTH_INICIAL ; Ancho inicial
            MUL CL                     ; AX = ancho_inicial * hits_restantes
            DIV DL                     ; AX = (ancho_inicial * hits_restantes) / max_hits
            
            ; Asegurar ancho minimo de 2 pixeles
            CMP AL, 2
            JGE STORE_S1
            MOV AL, 2                  ; Ancho minimo
            JMP STORE_S1
            
        SET_S1_ZERO:
            ; Escudo destruido - ancho cero
            MOV AL, 0
            
        STORE_S1:
            ; Almacenar nuevo ancho
            MOV AH, 0                  ; Limpiar AH
            MOV SHIELD1_CURRENT_WIDTH, AX
            
            POP DX
            POP CX
            POP BX
            POP AX
        RET
    UPDATE_SHIELD1_WIDTH ENDP


; UPDATE_SHIELD2_WIDTH - Actualiza el ancho del escudo 2 segun daño
; -------------------------------------------------------------

    UPDATE_SHIELD2_WIDTH PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            
            ; Calcular cuantos hits le quedan al escudo
            MOV AL, SHIELD2_MAX_HITS   ; Maximo de hits (7)
            MOV CL, AL                 ; Guardar maximo en CL
            MOV AL, SHIELD2_HITS       ; Hits actuales
            SUB CL, AL                 ; CL = hits restantes
            
            CMP CL, 0                  ; Escudo destruido?
            JLE SET_S2_ZERO
            
            ; Calcular nuevo ancho proporcional a hits restantes
            MOV AL, SHIELD2_MAX_HITS   ; Maximo de hits
            MOV AH, 0                  ; Convertir a word
            MOV DX, AX                 ; DX = max hits
            
            MOV AX, SHIELD_WIDTH_INICIAL ; Ancho inicial
            MUL CL                     ; AX = ancho_inicial * hits_restantes
            DIV DL                     ; AX = (ancho_inicial * hits_restantes) / max_hits
            
            ; Asegurar ancho minimo de 2 pixeles
            CMP AL, 2
            JGE STORE_S2
            MOV AL, 2                  ; Ancho minimo
            JMP STORE_S2
            
        SET_S2_ZERO:
            ; Escudo destruido - ancho cero
            MOV AL, 0
            
        STORE_S2:
            ; Almacenar nuevo ancho
            MOV AH, 0                  ; Limpiar AH
            MOV SHIELD2_CURRENT_WIDTH, AX
            
            POP DX
            POP CX
            POP BX
            POP AX
        RET
    UPDATE_SHIELD2_WIDTH ENDP
    
    
    
; ==============================================================
; SECCION 7: PROCEDIMIENTOS DE SONIDO
; ==============================================================


; PLAY_SHOOT_SOUND - Reproduce sonido de disparo del jugador
; -------------------------------------------------------------

    PLAY_SHOOT_SOUND PROC NEAR
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            
            ; Tono alto y corto (efecto de disparo)
            MOV AL, 182                 ; Preparar el timer del PC
            OUT 43h, AL                 ; Puerto de control del timer
            
            ; Configurar frecuencia para 1000 Hz aproximadamente
            MOV AX, 1193                ; Valor para 1000 Hz
            OUT 42h, AL                 ; Byte bajo de la frecuencia
            MOV AL, AH
            OUT 42h, AL                 ; Byte alto de la frecuencia
            
            ; Activar el speaker del PC
            IN AL, 61h                  ; Leer estado del puerto 61h
            OR AL, 00000011b            ; Activar bits 0 y 1 (speaker on)
            OUT 61h, AL                 ; Escribir nuevo estado
            
            ; Delay corto para el sonido (2 loops externos)
            MOV CX, 0002h               ; Solo 2 iteraciones externas
        
        SHOOT_DELAY_OUTER:
            PUSH CX
            MOV CX, 1000h               ; Loop interno reducido
        
        SHOOT_DELAY_INNER:
            NOP                         ; Instruccion de espera
            LOOP SHOOT_DELAY_INNER
            POP CX
            LOOP SHOOT_DELAY_OUTER
            
            ; Apagar el speaker
            IN AL, 61h                  ; Leer estado del puerto 61h
            AND AL, 11111100b           ; Desactivar bits 0 y 1 (speaker off)
            OUT 61h, AL                 ; Escribir nuevo estado
            
            POP DX
            POP CX
            POP BX
            POP AX
        RET
    PLAY_SHOOT_SOUND ENDP


; PLAY_EXPLOSION_SOUND - Reproduce sonido de explosion
; -------------------------------------------------------------


    PLAY_EXPLOSION_SOUND PROC NEAR
            ; Sonido de explosion fuerte
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            
            ; ===== IMPACTO INICIAL GRAVE (PUM) =====
            MOV AL, 182          ; 182 = timer 2, modo 3, Binario
            OUT 43h, AL          ; Envia comando al puerto de control
            
            ; Frecuencia MUY BAJA para sonido grave profundo
            MOV AX, 4000         ; Frecuencia grave, 298.3 Hz
            OUT 42h, AL          ; Envia byte bajo de la frecuencia al timer
            MOV AL, AH
            OUT 42h, AL          ; Envia byte alto de la frecuencia al timer
            
            ; Activar speaker
            IN AL, 61h
            OR AL, 00000011b     ;Activa timer 2 + speaker
            OUT 61h, AL          ;Suena con tono grave
            
            ; Delay mediano para el impacto
            MOV CX, 0003h
                           ; 3 iteraciones externas
        BOOM_DELAY_OUTER:
        
            PUSH CX
            MOV CX, 1000h               ; Loop interno
            
        BOOM_DELAY_INNER:
        
            NOP
            LOOP BOOM_DELAY_INNER
            POP CX
            LOOP BOOM_DELAY_OUTER
            
            ; ===== eco del boom =====
            MOV BX, 3                   ; 3 ecos
            
        REVERB_LOOP:
        
            ; Apagar momentaneamente
            IN AL, 61h
            AND AL, 11111100b
            OUT 61h, AL
            
            ; Pausa cortisima entre ecos
            PUSH CX
            MOV CX, 0100h
            
        REVERB_PAUSE:
        
            NOP
            LOOP REVERB_PAUSE
            POP CX
            
            ; Reactivar con tono ligeramente mas agudo
            MOV AL, 182
            OUT 43h, AL
            
            MOV AX, 3500                ; Frecuencia un poco mas aguda
            OUT 42h, AL
            MOV AL, AH
            OUT 42h, AL
            
            IN AL, 61h
            OR AL, 00000011b
            OUT 61h, AL
            
            ; Echo mas corto que el impacto principal
            PUSH CX
            MOV CX, 0400h
            
        REVERB_DELAY:
        
            NOP
            LOOP REVERB_DELAY
            POP CX
            
            DEC BX
            JNZ REVERB_LOOP             ; Repetir para todos los ecos
            
            ; Apagar speaker completamente
            IN AL, 61h
            AND AL, 11111100b
            OUT 61h, AL
            
            POP DX
            POP CX
            POP BX
            POP AX
        RET
    PLAY_EXPLOSION_SOUND ENDP

; PLAY_VICTORY_SOUND - Reproduce sonido de victoria
;---------------------------------------------------------------

    PLAY_VICTORY_SOUND PROC NEAR
            ; Sonido de victoria simple con solo 2 tonos
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            
            ; ===== PRIMER TONO (ALTO) =====
            MOV AL, 182
            OUT 43h, AL
            
            MOV AX, 600                 ;1988Hz, Tono agudo
            OUT 42h, AL
            MOV AL, AH
            OUT 42h, AL
            
            IN AL, 61h
            OR AL, 00000011b
            OUT 61h, AL
            
            ; Tono largo (5 iteraciones externas)
            MOV CX, 0005h
            
        FIRST_TONE_OUTER:
            PUSH CX
            MOV CX, 0FFFFh              ; Loop interno largo
            
        FIRST_TONE_INNER:
            NOP
            LOOP FIRST_TONE_INNER
            POP CX
            LOOP FIRST_TONE_OUTER
            
            IN AL, 61h
            AND AL, 11111100b
            OUT 61h, AL
            
            ; ===== PAUSA BREVE =====
            MOV CX, 0002h
        PAUSE_OUTER:
            PUSH CX
            MOV CX, 0800h               ; Loop interno corto
        PAUSE_INNER:
            NOP
            LOOP PAUSE_INNER
            POP CX
            LOOP PAUSE_OUTER
            
            ; ===== SEGUNDO TONO (GRAVE) =====
            MOV AL, 182
            OUT 43h, AL
            
            MOV AX, 1200                ;994,  Tono grave
            OUT 42h, AL
            MOV AL, AH
            OUT 42h, AL
            
            IN AL, 61h
            OR AL, 00000011b
            OUT 61h, AL
            
            ; Tono muy largo (8 iteraciones externas)
            MOV CX, 0008h
        SECOND_TONE_OUTER:
            PUSH CX
            MOV CX, 0FFFFh              ; Loop interno largo
        SECOND_TONE_INNER:
            NOP
            LOOP SECOND_TONE_INNER
            POP CX
            LOOP SECOND_TONE_OUTER
            
            ; Apagar speaker
            IN AL, 61h
            AND AL, 11111100b
            OUT 61h, AL
            
            POP DX
            POP CX
            POP BX
            POP AX
        RET
    PLAY_VICTORY_SOUND ENDP

  
CODE ENDS
END