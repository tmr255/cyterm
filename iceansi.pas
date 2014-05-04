{

Here is a good ANSI unit I picked up over WWIVNET.... I've added it to a
     simple modem program I was writing and it worked just fine.  To get
     it to work just send every charachter coming in through the procedure
     Ice_Display_ANSI

Hope this is helpful..... Vince Weaver    c/o   MJWEAVER@UMD5.UMD.EDU

}

{Shawn - old iCE Ansi unit borrowed from swag.}
 
UNIT IceAnsi;

{$MODE Delphi}

INTERFACE

(* If you use this code in your own programs, please give
   proper credit to Alan Caruana/IceSoft Software *)
   
Procedure InitAnsi;
PROCEDURE Ice_Display_ANSI(ch:char);
                   { Displays ch following ANSI graphics protocol}

IMPLEMENTATION
Uses Main,sysutils;
VAR
  ANSI_St :String ;  {stores ANSI escape sequence if receiving ANSI}
  ANSI_SCPL :INTEGER;  {stores the saved cursor position line}
  ANSI_SCPC :INTEGER;  { "  "  "  "  "  column}
  ANSI_FG :INTEGER;  {stores current foreground}
  ANSI_BG :INTEGER;  {stores current background}
  ANSI_C,ANSI_I,ANSI_B,ANSI_R:BOOLEAN ;  {stores current attribute options}
  p,x,y : INTEGER;

PROCEDURE Ice_Display_ANSI(ch:char);  {Displays ch following ANSI graphics protocal }

  PROCEDURE TABULATE;
  VAR x:INTEGER;
  BEGIN
    x:= MF.VGAEmu1.WhereX;
    IF x< MF.VGAEmu1.chrCols THEN
      REPEAT
        Inc(x);
      UNTIL (x MOD 8)=0;
    IF x=MF.VGAEmu1.chrCols THEN x:=1;
    MF.VGAEmu1.GOTOXY(x, MF.VgaEmu1.WHEREY);
    IF x=1 THEN MF.VGAEmu1.WRITELN('');
  END;

  PROCEDURE TTY(ch:char);
  VAR x:INTEGER;
  BEGIN
    IF ANSI_C THEN BEGIN
      IF ANSI_I THEN ANSI_FG:=ANSI_FG OR 8;
      IF ANSI_B THEN ANSI_FG:=ANSI_FG OR 16;
      IF ANSI_R THEN BEGIN
        x:=ANSI_FG;
        ANSI_FG:=ANSI_BG;
        ANSI_BG:=x;
      END;
      ANSI_C:=FALSE;
    END;
    MF.VgaEmu1.TextColor(ANSI_FG);
    MF.VgaEmu1.TextBackground(ANSI_BG);
    CASE Ch of
{      ^G: BEGIN
            BEEP;
          END;} //crt doing bell character
{      ^H: Backspace;} //crt doing backspace
      ^I: Tabulate;
      ^J: BEGIN
            MF.VgaEmu1.TextBackground(0);
            MF.VgaEmu1.Write(^J);
          END;
      ^K: MF.VgaEmu1.GotoXY(1,1);
      ^L: BEGIN
            MF.VgaEmu1.TextBackground(0);
            MF.VgaEmu1.Write(^L);
          END;
      ^M: BEGIN
            MF.VgaEmu1.TextBackground(0);
            MF.VgaEmu1.Write(^M);
          END;
      ELSE MF.VgaEmu1.Write(Ch);
    END;
  END;
  PROCEDURE ANSIWrite(S:String);
  VAR x:INTEGER;
  BEGIN
    FOR x:=1 to Length(S) do
      TTY(S[x]);
  END;
  FUNCTION Param:INTEGER;  {returns -1 if no more parameters}
  VAR S:String;
      x,XX:INTEGER;
      B:BOOLEAN;
  BEGIN
    B:=FALSE;
    FOR x:=3 TO Length(ANSI_St) DO
      IF ANSI_St[x] in ['0'..'9'] THEN B:=TRUE;
    IF NOT B THEN
      Param:=-1
    ELSE BEGIN
      S:='';
      IF ANSI_St[3]=';' THEN BEGIN
        Param:=0;
        Delete(ANSI_St,3,1);
      END
      else
      begin
      X  := 3;
      REPEAT
        S:=S+ANSI_St[x];
        x:=x+1;
      UNTIL (Length(ANSI_St) < X) or (NOT (ANSI_St[x] IN ['0'..'9'])) or (Length(S)>2) or
            (x>Length(ANSI_St));
      IF Length(S)>3 THEN BEGIN
        ANSIWrite(ANSI_St+Ch);
        ANSI_St:='';
        Param:=-1;
      END
      else
      begin
      Delete(ANSI_St,3,Length(S));
      IF Length(Ansi_St) > 2 THEN
        IF ANSI_St[3]=';' THEN Delete(ANSI_St,3,1);

      Val(S,x,XX);
      Param:=x;
      end;
     end;
    END;
  END;

BEGIN
  IF (Ch<>#27) and (ANSI_St='') THEN BEGIN
    TTY(Ch);
    Exit;
  END;
  IF Ch=#27 THEN BEGIN
    IF ANSI_St<>'' THEN BEGIN
      ANSIWrite(ANSI_St+#27);
      ANSI_St:='';
    END ELSE ANSI_St:=#27;
    EXIT;
  END;
  IF ANSI_St=#27 THEN BEGIN
    IF Ch='[' THEN
      ANSI_St:=#27+'['
    ELSE BEGIN
      ANSIWrite(ANSI_St+Ch);
      ANSI_St:='';
    END;
    Exit;
  END;
  IF (Ch='[') and (ANSI_St<>'') THEN BEGIN
    ANSIWrite(ANSI_St+'[');
    ANSI_St:='';
    EXIT;
  END;
  IF not (Ch in ['0'..'9',';','A'..'D','f','H','J','K','m','n','r','s','u']) THEN
  BEGIN
    ANSIWrite(ANSI_St+Ch);
    ANSI_St:='';
    EXIT;
  END;
  IF Ch in ['A'..'D','f','H','J','K','m','n','r','s','u'] THEN BEGIN
    CASE Ch of
    'A': BEGIN
           p:=Param;
           IF p=-1 THEN p:=1;
           IF MF.VgaEmu1.WhereY-p<1 THEN
             MF.VgaEmu1.GotoXY(MF.VgaEmu1.Wherex,1)
           ELSE MF.VgaEmu1.GotoXY(MF.VgaEmu1.WhereX,MF.VgaEmu1.WhereY-p);
         END;
    'B': BEGIN
           p:=Param;
           IF p=-1 THEN p:=1;
           IF MF.VgaEmu1.WhereY+p>MF.VgaEmu1.chrRows THEN
             MF.VgaEmu1.GotoXY(MF.VgaEmu1.WhereX,MF.VgaEmu1.chrRows)
           ELSE MF.VgaEmu1.GotoXY(MF.VgaEmu1.WhereX,MF.VgaEmu1.WhereY+p);
         END;
    'C': BEGIN
           p:=Param;
           IF p=-1 THEN p:=1;
           IF MF.VgaEmu1.WhereX+p>MF.VgaEmu1.chrCols THEN
             MF.VgaEmu1.GotoXY(MF.VgaEmu1.chrCols,MF.VgaEmu1.WhereY)
           ELSE MF.VgaEmu1.GotoXY(MF.VgaEmu1.WhereX+p,MF.VgaEmu1.WhereY);
         END;
    'D': BEGIN
           p:=Param;
           IF p=-1 THEN p:=1;
           IF (MF.VgaEmu1.WhereX-p<1) OR (P > MF.VgaEmu1.chrCols) THEN
             MF.VgaEmu1.GotoXY(1,MF.VgaEmu1.WhereY)
           ELSE
             MF.VgaEmu1.GotoXY(MF.VgaEmu1.WhereX-p,MF.VgaEmu1.WhereY);
         END;
    'H','f': BEGIN
           Y:=Param;
           x:=Param;
           IF Y<1 THEN Y:=1;
           IF x<1 THEN x:=1;
           IF (x>MF.VgaEmu1.chrCols) or (x<1) or (Y>MF.VgaEmu1.chrRows) or (Y<1) THEN BEGIN
             ANSI_St:='';
             EXIT;
           END;
           MF.VgaEmu1.GotoXY(x,Y);
         END;
    'J': BEGIN
           p:=Param;
           IF p=2 THEN BEGIN
             MF.VgaEmu1.TextBackground(0);
             MF.VgaEmu1.ClrScr;
             MF.ClearAreas;
           END;
           IF p=0 THEN BEGIN
             x:=MF.VgaEmu1.WhereX;
             Y:=MF.VgaEmu1.WhereY;
//             Window(1,y,CRT.chrCols,CRT.chrRows);
             MF.VgaEmu1.TextBackground(0);
             MF.VgaEmu1.ClrScr;
//             Window(1,1,CRT.chrCols,CRT.chrRows);
             MF.VgaEmu1.GotoXY(x,Y);
           END;
           IF p=1 THEN BEGIN
             x:=MF.VgaEmu1.WhereX;
             Y:=MF.VgaEmu1.WhereY;
//             Window(1,1,CRT.chrCols,wherey);
             MF.VgaEmu1.TextBackground(0);
             MF.VgaEmu1.ClrScr;
//             Window(1,1,CRT.chrCols,CRT.chrRows);
             MF.VgaEmu1.GotoXY(x,Y);
           END;
           if P=-1 then
              MF.VgaEmu1.ClrScr; //J
         END;
    'K': BEGIN
           MF.VgaEmu1.TextBackground(0);
           MF.VgaEmu1.ClrEol;
         END;
    'n': begin
           x:=MF.VgaEmu1.WhereX;
           Y:=MF.VgaEmu1.WhereY;
           MF.DataOut(#27+'['+ intToStr(y) + ';' + intToStr(x) + 'R');
         end;
    'm': BEGIN
           IF ANSI_St=#27+'[' THEN BEGIN
             ANSI_FG:=7;
             ANSI_BG:=0;
             ANSI_I:=FALSE;
             ANSI_B:=FALSE;
             ANSI_R:=FALSE;
           END;
           REPEAT
             p:=Param;
             CASE p of
               -1:;
                0:BEGIN
                    ANSI_FG:=7;
                    ANSI_BG:=0;
                    ANSI_I:=FALSE;
                    ANSI_R:=FALSE;
                    ANSI_B:=FALSE;
                  END;
                1:ANSI_I:=true;
                5:ANSI_B:=true;
                7:ANSI_R:=true;
               30:ANSI_FG:=0;
               31:ANSI_FG:=4;
               32:ANSI_FG:=2;
               33:ANSI_FG:=6;
               34:ANSI_FG:=1;
               35:ANSI_FG:=5;
               36:ANSI_FG:=3;
               37:ANSI_FG:=7;
               40:ANSI_BG:=0;
               41:ANSI_BG:=4;
               42:ANSI_BG:=2;
               43:ANSI_BG:=6;
               44:ANSI_BG:=1;
               45:ANSI_BG:=5;
               46:ANSI_BG:=3;
               47:ANSI_BG:=7;
             END;
             IF ((p>=30) and (p<=47)) or (p=1) or (p=5) or (p=7) THEN
                ANSI_C:=true;
           UNTIL p=-1;
         END;
    'r': BEGIN
           Y:=Param;
           x:=Param;
           if Y = 0 then
           begin
              MF.VgaEmu1.WrapTop    := 1;
              MF.VgaEmu1.WrapBottom := MF.VgaEmu1.chrRows;
           end
           else
           begin
             if Y < 0 then Y := 1;
             if X < 0 then X := MF.VgaEmu1.chrRows;
             MF.VgaEmu1.WrapTop    := Y;
             MF.VgaEmu1.WrapBottom := X; //tag tmr +1
           end;

         END;
    's': BEGIN
           ANSI_SCPL:=MF.VgaEmu1.WhereY;
           ANSI_SCPC:=MF.VgaEmu1.WhereX;
         END;
    'u': BEGIN
           IF ANSI_SCPL>-1 THEN MF.VgaEmu1.GotoXY(ANSI_SCPC,ANSI_SCPL);
           ANSI_SCPL:=-1;
           ANSI_SCPC:=-1;
         END;
    END;
    ANSI_St:='';
    EXIT;
  END;
  IF Ch in ['0'..'9',';'] THEN
    ANSI_St:=ANSI_St+Ch;
  IF Length(ANSI_St)>50 THEN BEGIN
    ANSIWrite(ANSI_St);
    ANSI_St:='';
    EXIT;
  END;
END;

Procedure InitAnsi;
BEGIN
  ANSI_St:='';
  ANSI_SCPL:=-1;
  ANSI_SCPC:=-1;
  ANSI_FG:=7;
  ANSI_BG:=0;
  ANSI_C:=FALSE;
  ANSI_I:=FALSE;
  ANSI_B:=FALSE;
  ANSI_R:=FALSE;
end;
END.
 
 
 

