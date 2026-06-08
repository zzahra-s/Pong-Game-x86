
[org 0x100]
jmp start
originalTimerISR dd 0
originalKeyboardISR dd 0

playerAPaddlePosition: dw 0
playerBPaddlePosition: dw 0
ballX: dw 40            
ballY: dw 12
paddleSize: dw 5
playerAScore: dw 0
playerBScore: dw 0
ballDeltaX: dw 1
ballDeltaY: dw 1
timerTickCount dw 0
ballSpeedDelay: dw 2

welcomeMessage: db 'WELCOME TO PONG GAME!'
pressKeyMessage: db 'Press Any Key to Start'

titleLine1: db '  ____   ___  _   _  ____ '
titleLine2: db ' |  _ \ / _ \| \ | |/ ___|'
titleLine3: db ' | |_) | | | |  \| | |  _ '
titleLine4: db ' |  __/| |_| | |\  | |_| |'
titleLine5: db ' |_|    \___/|_| \_|\____|'
winLine1A db '       --------------------------------',0
winLine2A db '       -        PLAYER A WINS!        -',0
winLine3A db '       --------------------------------',0

winLine1B db '       ---------------------------------',0
winLine2B db '       -        PLAYER B WINS!        -',0
winLine3B db '       --------------------------------',0

timerInterruptHandler:
    push ax
    inc word[cs:timerTickCount]
    mov ax,[cs:ballSpeedDelay]
    cmp word[cs:timerTickCount],ax
    jne exitTimerInterrupt
    mov word[cs:timerTickCount],0
    call updateBallPosition
    exitTimerInterrupt:
    mov al,0x20
    out 0x20,al
    pop ax
    iret

updateBallPosition:
    pusha
    mov ax,0xb800
    mov es,ax
   
    mov ax,[cs:ballY]
    mov bx,160
    mul bx
    mov bx,[cs:ballX]
    shl bx,1
    add ax,bx
    mov si,ax
    mov word[es:si],0x0720
   
    mov ax,[cs:ballDeltaX]
    add [cs:ballX],ax
    mov ax,[cs:ballDeltaY]
    add [cs:ballY],ax
   
    mov ax,[cs:ballX]
    cmp ax,0
    jge checkXUpperBound
    mov word[cs:ballX],0
    jmp checkYBounds
   
    checkXUpperBound:
        cmp ax,79
        jle checkYBounds
        mov word[cs:ballX],79
   
    checkYBounds:
        mov ax,[cs:ballY]
        cmp ax,0
        jge checkYUpperBound
        mov word[cs:ballY],0
        jmp checkWallCollisions
       
    checkYUpperBound:
        cmp ax,24
        jle checkWallCollisions
        mov word[cs:ballY],24
   
    checkWallCollisions:
        mov ax,[cs:ballY]
        cmp ax,0
        jle hitTopWall
        cmp ax,24
        jge hitBottomWall
        jmp checkPaddleCollision
   
    hitTopWall:
        mov word[cs:ballY],1
        mov word[cs:ballDeltaY],1
        mov cx,8997
        mov bx,1
        call playBeepSound
        jmp checkPaddleCollision
   
    hitBottomWall:
        mov word[cs:ballY],24
        neg word[cs:ballDeltaY]
        mov cx,8997
        mov bx,1
        call playBeepSound
   
    checkPaddleCollision:
        mov ax,[cs:ballX]
        cmp ax,1
        jle checkLeftPaddleRange
        cmp ax,78
        jge checkRightPaddleRange
        jmp jumpToDrawBall

    checkLeftPaddleRange:
        cmp word[cs:ballDeltaX],0
        jge jumpToDrawBall
       
        mov ax,[cs:ballY]
        mov bx,[cs:playerAPaddlePosition]
        cmp ax,bx
        jl missedLeft
       
        add bx,[cs:paddleSize]
        cmp ax,bx
        jge missedLeft
       
        neg word[cs:ballDeltaX]
        mov word[cs:ballX],2
       
        mov cx,6479
        mov bx,2
        call playBeepSound
        jmp drawBall
   
    jumpToDrawBall:
        jmp drawBall

    checkRightPaddleRange:
        cmp word[cs:ballDeltaX],0
        jle jumpToDrawBall2
       
        mov ax,[cs:ballY]
        mov bx,[cs:playerBPaddlePosition]
        cmp ax,bx
        jl missedRight
       
        add bx,[cs:paddleSize]
        cmp ax,bx
        jge missedRight
       
        neg word[cs:ballDeltaX]
        mov word[cs:ballX],77
       
        mov cx,6479
        mov bx,2
        call playBeepSound
        jmp drawBall
   
    jumpToDrawBall2:
        jmp drawBall
   
    missedLeft:
        inc word[cs:playerBScore]
        call checkWinCondition
        cmp ax,1
        je skipDrawBall
        call resetGameBoard
        jmp skipDrawBall
   
    missedRight:
        inc word[cs:playerAScore]
        call checkWinCondition
        cmp ax,1
        je skipDrawBall
        call resetGameBoard
        jmp skipDrawBall
   
    drawBall:
        mov ax,[cs:ballY]
        cmp ax,0
        jl skipDrawBall
        cmp ax,24
        jg skipDrawBall
       
        mov bx,[cs:ballX]
        cmp bx,0
        jl skipDrawBall
        cmp bx,79
        jg skipDrawBall
       
        mov ax,[cs:ballY]
        mov bx,160
        mul bx
        mov bx,[cs:ballX]
        shl bx,1
        add ax,bx
        mov si,ax
        mov word[es:si],0x0430
   
    skipDrawBall:
        popa
        ret

checkWinCondition:
    cmp word[cs:playerAScore],3
    jge playerWins
    cmp word[cs:playerBScore],3
    jge playerWins
    xor ax,ax
    ret
    playerWins:
    mov ax,1
    ret

playBeepSound:
    mov al,182
    out 0x43,al
    mov ax,cx
    out 0x42,al
    mov al,ah
    out 0x42,al
    in al,0x61
    or al,00000011b
    out 0x61,al
    soundDelay1:
        mov cx,65535
    soundDelay2:
       dec cx
        jne soundDelay2
        dec bx
        jne soundDelay1
    in al,0x61
    and al,11111100b
    out 0x61,al
    ret

clearScreen:
    push ax
    push di
    push es
    push cx
    mov ax,0xb800
    mov es,ax
    xor di,di
    mov cx,2000
    mov ax,0x0720
    rep stosw
    pop cx
    pop es
    pop di
    pop ax
    ret
   
drawLine:
    pusha
    mov ax,0xb800
    mov es,ax
   
    mov di,160 + 80      
    mov cx,12            
centerLine:
        mov word[es:di],0x0EDB  
        add di,320              
        loop centerLine
   
    popa
    ret
   
resetGameBoard:
    pusha
   
    mov word[cs:playerAPaddlePosition],10
    mov word[cs:playerBPaddlePosition],10
    mov word[cs:ballX],40       
    mov word[cs:ballY],12
   
    cmp word[cs:ballDeltaX],1
    je alternateToLeft
    mov word[cs:ballDeltaX],1
    jmp resetContinue
    alternateToLeft:
    mov word[cs:ballDeltaX],-1
   
    resetContinue:
    mov word[cs:ballDeltaY],1
   
    call clearScreen
    call drawLine
    call drawPaddles
   
    mov ax,0xb800
    mov es,ax
    mov ax,[cs:ballY]
    mov bx,160
    mul bx
    mov bx,[cs:ballX]
    shl bx,1
    add ax,bx
    mov si,ax
    mov word[es:si],0x0430
   
    call displayScores
   
    popa
    ret

displayScores:
    push ax
    push es
    push di

    mov ax,0xb800
    mov es,ax

    mov di, 10              

    mov word [es:di], 0x0A41   
    add di,2
    mov word [es:di], 0x0A3A   
    add di,2

    mov al, [cs:playerAScore]
    add al, '0'
    mov ah, 0x0A            
    mov word [es:di], ax       

    mov di, 140             

    mov word [es:di], 0x0A42   
    add di,2
    mov word [es:di], 0x0A3A   
    add di,2

    mov al, [cs:playerBScore]
    add al, '0'
    mov ah, 0x0A              
    mov word [es:di], ax

    pop di
    pop es
    pop ax
    ret

drawPaddles:
    push ax
    push es
    push di
    push cx
    mov ax,0xb800
    mov es,ax
   
    mov ax,[cs:playerAPaddlePosition]
    mov bx,160
    mul bx
    mov di,ax
    mov cx,[cs:paddleSize]
   
    drawLeftPaddleLoop:
        mov word[es:di],0x3020  
        add di,160
        loop drawLeftPaddleLoop
   
    mov ax,[cs:playerBPaddlePosition]
    mov bx,160
    mul bx
    add ax,318
    mov di,ax
    mov cx,[cs:paddleSize]
   
    drawRightPaddleLoop:
        mov word[es:di],0x3020  
        add di,160
        loop drawRightPaddleLoop
   
    pop cx
    pop di
    pop es
    pop ax
    ret

keyboardInterruptHandler:
    push ax
    push ds
    push cs
    pop ds
    in al,0x60
   
    cmp al,0x11
    je movePlayerAUp
    cmp al,0x1F
    je movePlayerADown
    cmp al,0x48
    je movePlayerBUp
    cmp al,0x50
    je movePlayerBDown
   
    jmp endKeyboardInterrupt
   
    movePlayerAUp:
    call movePlayerAUp_func
    jmp endKeyboardInterrupt
   
    movePlayerADown:
    call movePlayerADown_func
    jmp endKeyboardInterrupt
   
    movePlayerBUp:
    call movePlayerBUp_func
    jmp endKeyboardInterrupt
   
    movePlayerBDown:
    call movePlayerBDown_func
   
    endKeyboardInterrupt:
    pop ds
    mov al,0x20
    out 0x20,al
    pop ax
    iret

movePlayerAUp_func:
    pusha
    mov ax,[cs:playerAPaddlePosition]
    cmp ax,1
    jle exitPlayerAUp
    dec word[cs:playerAPaddlePosition]
    call redrawPaddles
    exitPlayerAUp:
    popa
    ret

movePlayerADown_func:
    pusha
    mov ax,[cs:playerAPaddlePosition]
    add ax,[cs:paddleSize]
    cmp ax,25
    jge exitPlayerADown
    inc word[cs:playerAPaddlePosition]
    call redrawPaddles
    exitPlayerADown:
    popa
    ret

movePlayerBUp_func:
    pusha
    mov ax,[cs:playerBPaddlePosition]
    cmp ax,0
    jle exitPlayerBUp
    dec word[cs:playerBPaddlePosition]
    call redrawPaddles
    exitPlayerBUp:
    popa
    ret

movePlayerBDown_func:
    pusha
    mov ax,[cs:playerBPaddlePosition]
    add ax,[cs:paddleSize]
    cmp ax,24
    jge exitPlayerBDown
    inc word[cs:playerBPaddlePosition]
    call redrawPaddles
    exitPlayerBDown:
    popa
    ret

redrawPaddles:
    push ax
    push es
    push di
    push cx
   
    mov ax,0xb800
    mov es,ax
   
    cli
   
    xor di,di
    mov cx,25
    clearLeftLoop:
        mov word[es:di],0x0720
        add di,160
        loop clearLeftLoop
   
    mov di,318
    mov cx,25
    clearRightLoop:
        mov word[es:di],0x0720
        add di,160
        loop clearRightLoop
   
    mov ax,[cs:playerAPaddlePosition]
    mov bx,160
    mul bx
    mov di,ax
    mov cx,[cs:paddleSize]
    drawLeftLoop:
        mov word[es:di],0x3020 
        add di,160
        loop drawLeftLoop
   
    mov ax,[cs:playerBPaddlePosition]
    mov bx,160
    mul bx
    add ax,318
    mov di,ax
    mov cx,[cs:paddleSize]
    drawRightLoop:
        mov word[es:di],0x3020  
        add di,160
        loop drawRightLoop
   
    sti
   
    mov ax,[cs:ballY]
    mov bx,160
    mul bx
    mov bx,[cs:ballX]
    shl bx,1
    add ax,bx
    mov si,ax
    mov word[es:si],0x0430
   
    call displayScores
   
    pop cx
    pop di
    pop es
    pop ax
    ret

displayWinMessage:
    pusha
    mov ax,0B800h
    mov es,ax

    cmp si,0
    je playerA
    jmp playerB
   
playerA:
    mov bx, winLine1A
    mov dx, winLine2A
    mov bp, winLine3A
    jmp printLines

playerB:
    mov bx, winLine1B
    mov dx, winLine2B
    mov bp, winLine3B

printLines:
    mov si,bx
    mov di, (12*160) + 15*2
    call printLine

    mov si,dx
    mov di, (13*160) + 15*2
    call printLine

    mov si,bp
    mov di, (14*160) + 15*2
    call printLine

    popa
    ret
   
printLine:
nextChar:
    lodsb              
    cmp al,0
    je done
    mov ah,0x0A         
    mov [es:di],ax
    add di,2
    jmp nextChar
done:
    ret

start:
    call clearScreen
   
    mov ah,0x13
    mov al,0
    mov bh,0
    mov bl,0x0E
    mov dx,0x0317
    mov cx,26
    push cs
    pop es
    mov bp,titleLine1
    int 0x10
   
    mov dx,0x0417
    mov bp,titleLine2
    int 0x10
   
    mov dx,0x0517
    mov bp,titleLine3
    int 0x10
   
    mov dx,0x0617
    mov bp,titleLine4
    int 0x10
   
    mov dx,0x0717
    mov bp,titleLine5
    int 0x10
   
    mov bl,0x0B
    mov dx,0x0A1B
    mov cx,21
    mov bp,welcomeMessage
    int 0x10
   
    mov ax,0xb800
    mov es,ax
    mov di,(12*160) + 20
    mov cx,5
    drawLeftPaddleWelcome:
        mov word[es:di],0x3020  
        add di,160
        loop drawLeftPaddleWelcome
   
    mov di,(12*160) + 118
    mov cx,5
    drawRightPaddleWelcome:
        mov word[es:di],0x3020  
        add di,160
        loop drawRightPaddleWelcome
   
    mov di,(14*160) + 80
    mov word[es:di],0x0C4F
   
    mov ah,0x13
    mov bl,0x0A
    mov dx,0x131D
    mov cx,22
    push cs
    pop es
    mov bp,pressKeyMessage
    int 0x10
   
    xor ah,ah
    int 0x16

    call resetGameBoard
    xor ax,ax
    mov es,ax
    mov ax,[es:8*4]
    mov [cs:originalTimerISR],ax
    mov ax,[es:8*4+2]
    mov [cs:originalTimerISR+2],ax
    mov ax,[es:9*4]
    mov [cs:originalKeyboardISR],ax
    mov ax,[es:9*4+2]
    mov [cs:originalKeyboardISR+2],ax
    cli
    mov word[es:8*4],timerInterruptHandler
    mov word[es:8*4+2],cs
    mov word[es:9*4],keyboardInterruptHandler
    mov word[es:9*4+2],cs
    sti

mainGameLoop:
    cli
    cmp word[cs:playerAScore],3
    jge declarePlayerAWinner
    cmp word[cs:playerBScore],3
    jge declarePlayerBWinner
    sti
    jmp mainGameLoop

declarePlayerAWinner:
    call clearScreen
    xor si, si          
    call displayWinMessage
    jmp exitProgram

declarePlayerBWinner:
    call clearScreen
    mov si, 1        
    call displayWinMessage

exitProgram:
    xor ax,ax
    mov es,ax
    mov ax,[cs:originalTimerISR]
    mov [es:8*4],ax
    mov ax,[cs:originalTimerISR+2]
    mov [es:8*4+2],ax
    mov ax,[cs:originalKeyboardISR]
    mov [es:9*4],ax
    mov ax,[cs:originalKeyboardISR+2]
    mov [es:9*4+2],ax
    sti
    mov ax,0x4C00
    int 0x21