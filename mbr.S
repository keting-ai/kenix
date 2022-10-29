;MBR STARTS
;------------------------------------------------------------
%include "boot.inc"
SECTION MBR vstart=0x7c00         
   mov ax,cs      
   mov ds,ax
   mov es,ax
   mov ss,ax
   mov fs,ax
   mov sp,0x7c00
   mov ax,0xb800
   mov gs,ax

;Clean screen
;0x06: roll up all rows
;输入：
;Input:
;AH function number: 0x06
;AL: number of lines to roll up (0 means all)
;BH: attributes of lines to roll up
;(CL,CH): upper left corner
;(DL,DH): lower right corver
;无返回值：
   mov     ax, 0600h
   mov     bx, 0700h
   mov     cx, 0                   ; upper left corner: (0, 0)
   mov     dx, 184fh		   ; lower right corner: (80,25),
				   ; In VGA type, one line=80bytes, one page=25 lines
				   ; 0x18=24,0x4f=79, Index grows from 0.
   int     10h                     ; int 10h

   ; 输出字符串:MBR
   mov byte [gs:0x00],'1'
   mov byte [gs:0x01],0xA4

   mov byte [gs:0x02],' '
   mov byte [gs:0x03],0xA4

   mov byte [gs:0x04],'M'
   mov byte [gs:0x05],0xA4	   ;A: green backgroud flicker; 4: foreground color is red

   mov byte [gs:0x06],'B'
   mov byte [gs:0x07],0xA4

   mov byte [gs:0x08],'R'
   mov byte [gs:0x09],0xA4
	 
   mov eax,LOADER_START_SECTOR	 ;LBA addr of the starting sector
   mov bx,LOADER_BASE_ADDR       ;Addr to write in
   mov cx,4			 ;number of sectors that are waiting to be read
   call rd_disk_m_16		 ;Following starts to read program (In one sector)
  
   jmp LOADER_BASE_ADDR + 0x300
       
;-------------------------------------------------------------------------------
;Function: read in n sectors from the disk
rd_disk_m_16:	   
;-------------------------------------------------------------------------------
				       ; eax: LBA sector number
				       ; ebx: memory addr that used to write in data
				       ; ecx: number of LBA sector being read in
      mov esi,eax	  ;backup eax
      mov di,cx		  ;backup cx
;Read and write to the disk
;Step1: set the number of sectors to read
      mov dx,0x1f2
      mov al,cl
      out dx,al            ;reading sector number

      mov eax,esi	   ;recoverax

;Step2: mov LBA addr to 0x1f3 to 0x1f6

      ;LBA addr 7~0 bits are 0x1f3
      mov dx,0x1f3                       
      out dx,al                          

      ;LBA addr 15~8 bits are 0x1f4
      mov cl,8
      shr eax,cl
      mov dx,0x1f4
      out dx,al

      ;LBA addr 23~16 bits are0x1f5
      shr eax,cl
      mov dx,0x1f5
      out dx,al

      shr eax,cl
      and al,0x0f	   ;lba 24-27 bits
      or al,0xe0	   ;set 7-4 bits to 1110, lba mode
      mov dx,0x1f6
      out dx,al

;Step3: write read cmd 0x20 to 0x1f7 
      mov dx,0x1f7
      mov al,0x20                        
      out dx,al

;Step4: check disk
  .not_ready:
      nop
      in al,dx
      and al,0x88	   ;bit4: ready to tranfer data, bit7: disk busy
      cmp al,0x08
      jnz .not_ready	   ;wait until ready

;Step5: read from 0x1f0
      mov ax, di
      mov dx, 256
      mul dx
      mov cx, ax	   ; di is the number of sectors, 512bytes/sector, 1byte read in each time
			           ; totally need i*512/2times, so di*256
      mov dx, 0x1f0
  .go_on_read:
      in ax,dx
      mov [bx],ax
      add bx,2		  
      loop .go_on_read
      ret

   times 510-($-$$) db 0
   db 0x55,0xaa
