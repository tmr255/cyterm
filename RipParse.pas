unit RipParse;

{$MODE Delphi}

{
Shawn - Another unit I borrowed from Swag too... lost the original
author of the unit but the name was Ripsee.
Thanks whoever you are
}

interface

function Display_Rip(ch : char) : boolean;

implementation

Uses Main, sysutils, VgaGlobal;

CONST Place : ARRAY [1..5] OF LONGINT = (1, 36, 1296, 46656, 1679616);
      Seq = ('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ');

VAR
  ccol : INTEGER;
  Clipboard : POINTER;
  LLL : INTEGER;
  command : STRING;
  bslash : BOOLEAN;
  ButtonColor : integer;
  RipEsc      : byte;

FUNCTION Convert (SS : STRING) : LONGINT;
VAR PrLoop, Counter : INTEGER;
    CA, Tag : LONGINT;
BEGIN
  IF LENGTH (ss) = 1 THEN ss := '0' + ss;
  Counter := 0; CA := 0;
  FOR PrLoop := LENGTH (SS) DOWNTO 1 DO BEGIN
    Counter := Counter + 1;
    Tag := POS (SS [PrLoop], Seq) - 1;
    CA := CA + (Tag * Place [Counter]);
  END;
  Convert := CA;
END;

PROCEDURE ResetWindows;
BEGIN
  {SETVIEWPORT (0, 0, GETMAXX, GETMAXY, ClipOn);
  CLEARDEVICE;
  IF clipboard <> NIL THEN DISPOSE (clipboard);
  clipboard := NIL;}
  MF.VgaEmu1.ClearDevice;
  MF.ClearAreas;
END;

PROCEDURE usersetf;
VAR ii, jj : INTEGER;
    zz : FillPatternType;
BEGIN
  jj := 0;
  FOR ii := 1 TO 8 DO BEGIN
    jj := jj + 2;
    zz [ii] := Convert (COPY (command, jj, 2) );
  END;
//  SETFILLPATTERN (zz, Convert (COPY (command, 18, 2) ) );
END;

PROCEDURE DPoly (fillit, ifpoly : BOOLEAN; np : INTEGER);
VAR ii, zz, yy : INTEGER;
    poly : ARRAY [1..200] OF PointType;
BEGIN
  ii := 4;
  FOR zz := 1 TO np DO BEGIN
    poly [zz].x := Convert (COPY (command, ii, 2) );
    poly [zz].y := Convert (COPY (command, ii + 2, 2) );
    ii := ii + 4;
  END; IF ifpoly THEN BEGIN
    poly [np + 1] := poly [1];
    IF NOT fillit THEN MF.VgaEmu1.DrawPoly (np + 1, poly) ELSE MF.VgaEmu1.FillPoly (np + 1, poly);
  END ELSE IF NOT fillit THEN MF.VgaEmu1.DrawPoly (np, poly) ELSE MF.VgaEmu1.FillPoly (np, poly);
END;

//x0:2 y0:2 x1:2 y1:2 hotkey:2 flags:1 res:1
PROCEDURE Button( x0,y0,x1,y1, hotkey : word; flags, res : byte; Text : string);
var
  lbl,
  cmd : string;
  xpos,
  ypos : integer;
begin
  lbl := copy(text,0,pos('<>',text)-1);
  cmd := copy(text,pos('<>',text)+2, length(text));
//  MF.VgaEmu1.SetColor(ButtonColor);
  MF.VgaEmu1.SetColor(7);
  MF.VgaEmu1.Rectangle( x0,y0,x1,y1);

  MF.VgaEmu1.SetColor(15);
  MF.VgaEmu1.MoveTo(X0,Y1);
  MF.VgaEmu1.LineTo(x0,y1);
  MF.VgaEmu1.LineTo(x0,y0);
  MF.VgaEmu1.LineTo(x1,y0);
  MF.VgaEmu1.SetColor(8);
  MF.VgaEmu1.LineTo(x1,y1);
  MF.VgaEmu1.LineTo(x0,y1);

  MF.VgaEmu1.SetColor(1);
  xpos := ((x0 + x1) div 2) - ((length(lbl) * 9) div 2);
  ypos := ((y0+y1) div 2) - 3;
  MF.VgaEmu1.OutTextXY( xpos, ypos, lbl);
  MF.AddArea(x0,y0,x1,y1,0,cmd);
end;

PROCEDURE ParseCommand (command : STRING);
BEGIN
  IF command = '*' THEN resetwindows;
//  IF command [1] = 'W' THEN SetWriteMode (Convert (COPY (command, 2, 2) ) );
//  IF command [1] = 'S' THEN SETFILLSTYLE (Convert (COPY (command, 2, 2) ),
//                                      Convert (COPY (command, 4, 2) ) );
//  IF command [1] = 'E' THEN CRT.CLEARVIEWPORT;
//  IF command [1] = 'v' THEN SETVIEWPORT (Convert (COPY (command, 2, 2) ),
//                          Convert (COPY (command, 4, 2) ),
//                          Convert (COPY (command, 6, 2) ),
//                          Convert (COPY (command, 8, 2) ), ClipOn);
  IF command [1] = 'c' THEN IF LENGTH (command) = 2 THEN
    BEGIN
      ccol := (POS (command [2], Seq) - 1);
      MF.VgaEmu1.SETCOLOR (ccol);
    END ELSE BEGIN
      ccol := (Convert (COPY (command, 2, 2) ) );
      MF.VgaEmu1.SETCOLOR (ccol);
    END;
//  IF command [1] = 'Y' THEN SETTEXTSTYLE (Convert (COPY (command, 2, 2) ),
//                                      Convert (COPY (command, 4, 2) ),
//                                      Convert (COPY (command, 6, 2) ) );
//  IF command [1] = 's' THEN usersetf;
//  IF command [1] = 'Q' THEN allpalette;
  IF command [1] = '@' THEN MF.VgaEmu1.OUTTEXTXY (Convert (COPY (command, 2, 2) ),
                                   Convert (COPY (command, 4, 2) ),
                                   COPY (command, 6, LENGTH (command) - 5) );
  IF command [1] = 'F' THEN MF.VgaEmu1.FLOODFILL (Convert (COPY (command, 2, 2) ),
                          Convert (COPY (command, 4, 2) ),
                          Convert (COPY (command, 6, 2) ) );
  IF command [1] = 'C' THEN MF.VgaEmu1.CIRCLE (Convert (COPY (command, 2, 2) ),
                          Convert (COPY (command, 4, 2) ),
                          Convert (COPY (command, 6, 2) ) );
  IF command [1] = 'B' THEN MF.VgaEmu1.BAR (Convert (COPY (command, 2, 2) ),
                          Convert (COPY (command, 4, 2) ),
                          Convert (COPY (command, 6, 2) ),
                          Convert (COPY (command, 8, 2) ) );
  IF command [1] = 'A' THEN MF.VgaEmu1.ARC (Convert (COPY (command, 2, 2) ),
                          Convert (COPY (command, 4, 2) ),
                          Convert (COPY (command, 6, 2) ),
                          Convert (COPY (command, 8, 2) ),
                          Convert (COPY (command, 10, 2) ) );
  IF command [1] = 'I' THEN MF.VgaEmu1.PIESLICE (Convert (COPY (command, 2, 2) ),
                          Convert (COPY (command, 4, 2) ),
                          Convert (COPY (command, 6, 2) ),
                          Convert (COPY (command, 8, 2) ),
                          Convert (COPY (command, 10, 2) ) );
  IF command [1] = 'i' THEN MF.VgaEmu1.Sector (Convert (COPY (command, 2, 2) ),
                          Convert (COPY (command, 4, 2) ),
                          Convert (COPY (command, 6, 2) ),
                          Convert (COPY (command, 8, 2) ),
                          Convert (COPY (command, 10, 2) ),
                          Convert (COPY (command, 12, 2) ) );
  IF command [1] = 'L' THEN MF.VgaEmu1.LINE (Convert (COPY (command, 2, 2) ),
                          Convert (COPY (command, 4, 2) ),
                          Convert (COPY (command, 6, 2) ),
                          Convert (COPY (command, 8, 2) ) );
  IF command [1] = 'R' THEN MF.VgaEmu1.RECTANGLE (Convert (COPY (command, 2, 2) ),
                          Convert (COPY (command, 4, 2) ),
                          Convert (COPY (command, 6, 2) ),
                          Convert (COPY (command, 8, 2) ) );
  IF command [1] = 'o' THEN MF.VgaEmu1.FillEllipse (Convert (COPY (command, 2, 2) ),
                          Convert (COPY (command, 4, 2) ),
                          Convert (COPY (command, 6, 2) ),
                          Convert (COPY (command, 8, 2) ) );
//  IF (command [1] = 'O') OR (command [1] = 'V') THEN
//                          MF.VgaEmu1.ELLIPSE (Convert (COPY (command, 2, 2) ),
//                          Convert (COPY (command, 4, 2) ),
//                          Convert (COPY (command, 6, 2) ),
//                          Convert (COPY (command, 8, 2) ),
//                          Convert (COPY (command, 10, 2) ),
//                          Convert (COPY (command, 12, 2) ) );
  IF command [1] = 'P' THEN Dpoly (FALSE, TRUE, Convert (COPY (command, 2, 2) ) );
  IF command [1] = 'p' THEN Dpoly (TRUE, TRUE, Convert (COPY (command, 2, 2) ) );
  IF command [1] = 'X' THEN MF.VgaEmu1.PUTPIXEL (Convert (COPY (command, 2, 2) ),
                                  Convert (COPY (command, 4, 2) ), ccol);
//  IF command [1] = 'a' THEN SETPALETTE (Convert (COPY (command, 2, 2) ),
//                                    Convert (COPY (command, 4, 2) ) );
//  IF command [1] = '=' THEN SETLINESTYLE (Convert (COPY (command, 2, 2) ),
//                                      Convert (COPY (command, 4, 4) ),
//                                      Convert (COPY (command, 8, 2) ) );
  IF command [1] = 'l' THEN Dpoly (FALSE, FALSE, Convert (COPY (command, 2, 2) ) );
  IF command [1] = 'Z' THEN MF.VgaEmu1.Curve (Convert (COPY (command, 2, 2) ),
                          Convert (COPY (command, 4, 2) ),
                          Convert (COPY (command, 6, 2) ),
                          Convert (COPY (command, 8, 2) ),
                          Convert (COPY (command, 10, 2) ),
                          Convert (COPY (command, 12, 2) ),
                          Convert (COPY (command, 14, 2) ),
                          Convert (COPY (command, 16, 2) ),
                          Convert (COPY (command, 18, 2) ) );
  IF command [1] = '1' THEN BEGIN {level one commands}
//    IF command [2] = 'C' THEN Toclip (Convert (COPY (command, 3, 2) ),
//                                  Convert (COPY (command, 5, 2) ),
//                                  Convert (COPY (command, 7, 2) ),
//                                  Convert (COPY (command, 9, 2) ) );
//    IF (command [2] = 'P') AND (Clipboard <> NIL)
//                               THEN PUTIMAGE (Convert (COPY (command, 3, 2) ),
//                                    Convert (COPY (command, 5, 2) ),
//                                    Clipboard^,
//                                    Convert (COPY (command, 7, 2) ) );
//    IF command [2] = 'I' THEN LoadIcon (Convert (COPY (command, 3, 2) ),
//                                    Convert (COPY (command, 5, 2) ),
//                                    Convert (COPY (command, 7, 2) ),
//                                    Convert (COPY (command, 9, 1) ),
//                                    COPY (command, 12, LENGTH (command) - 11) );
//    IF command [2] = 'G' THEN Scrollgraph (Convert (COPY (command, 3, 2) ),
//                                       Convert (COPY (command, 5, 2) ),
//                                       Convert (COPY (command, 7, 2) ),
//                                       Convert (COPY (command, 9, 2) ),
//                                       Convert (COPY (command, 13, 2) ) );
    IF command[2] = 'K' then MF.ClearAreas;  //Kill mouse fields
    IF command[2] = 'U' then Button( Convert (COPY (command, 3, 2) ),
                                     Convert (COPY (command, 5, 2) ),
                                     Convert (COPY (command, 7, 2) ),
                                     Convert (COPY (command, 9, 2) ),
                                     Convert (COPY (command, 13, 2) ),
                                     Convert (COPY (command, 15, 1) ),
                                     Convert (COPY (command, 16, 1) ),
                                     COPY (command, 17, LENGTH (command) - 16)
                                   );
  END;
END;

PROCEDURE Init;
BEGIN
  clipboard := NIL;
  MF.VgaEmu1.CLEARDEVICE;
  LLL := 0;
  command := '';
  bslash := FALSE;
  ripline := FALSE;
  ButtonColor := 8;
END;

procedure detectRip(ch : char);
begin
    if (RipEsc = 3) and (Ch = '!') then begin
      MF.DataOut('RIPSCRIP015410');
      RipEsc := 0;
    end else if (RipEsc = 3) then RipEsc := 0;

    if (RipEsc = 2) and (Ch = '!') then begin
      MF.DataOut('RIPSCRIP015410');
      RipEsc := 0;
    end;

    if (RipEsc = 2) and (Ch = '0') then
      RipEsc := 3
    else if (RipEsc = 2) then RipEsc := 0;

    if (RipEsc = 1) and (Ch = '[') then
      RipEsc := 2;

    if (Ch = #27) then  //check for RIP escape codes
     RipEsc := 1;
end;

function Display_Rip(ch : char) : boolean;
begin
   DetectRip(ch);

    IF (ORD (ch) = 13) OR (ORD (ch) = 10) THEN BEGIN
      IF bslash = TRUE THEN BEGIN
//        READ (f, ch);
          bslash := FALSE;
          ripline := false;
      END ELSE BEGIN
        LLL := 0;
        ripline := false;
//        READ (f, ch);
      END;
    END ELSE BEGIN
      LLL := LLL + 1;
      IF (LLL = 1) AND (Ch = '!') THEN ripline := TRUE ELSE BEGIN
        IF ripline THEN BEGIN
          CASE ch OF
          '|' : BEGIN
            IF bslash THEN BEGIN
              command := command + ch; bslash := FALSE;
            END ELSE BEGIN
              IF command <> '' THEN ParseCommand (command);
              command := '';
            END;
          END;
          '\' : BEGIN
            IF bslash THEN BEGIN
              command := command + ch; bslash := FALSE;
            END ELSE
              bslash := TRUE;
          END;
          ELSE
            command := command + ch;
          END;
        END ELSE BEGIN
//          WriteString (ch, 15);
            RipLine := false;
        END;
      END;
    END;
  Display_Rip := RipLine;  
end;

end.
