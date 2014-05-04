unit VgaEmu;

{$MODE Delphi}

interface
{
CyTerm Project.
VgaEmu  created by Shawn Rapp

This is the VCL that does all the DOS graphics.
Project wont compile unless you install this component
BE VERY CAREFUL OF CHANGING THINGS.
}

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, DefFont, stdctrls, VgaGlobal;

const
   crtNrmlBufLen = 4000;  //normal size of memory buffer

type
  TCursorInfo = record
     CursorShape : byte;   //which scanlines(rows) are active. bit 1=top bit 8 = bottom
     CurPos      : TPoint; //where the cusor is x,y
     Color       : byte;   //what the active write color is
  end;

  TFontInfo = record
    RawBuffer : array of byte;  //the raw font buffer
    width     : byte;           //how wide the each font is
    height    : byte;           //how tall each font is
    size      : integer;        //the size of the raw font buffer.
  end;

  TVgaEmu = class(TPanel)
  private
    { Private declarations }
    Screen : array of Byte;
    row : PByteArray;
    OldBlinky  : Boolean;
    BlinkPhase : byte;
    ScrollBuffer : array of byte;
    cursor : tCursorInfo;  //attributes of cursor
    Font  : array[0..1] of TFontInfo; //font1 is standard used font, font2 is secondary font. another wierd vga feature
    bufSize : integer; //how big the text memory buffer is
    RawBuffer : array of byte;  //this is to simulate direct writes
    vWidth : Integer;
    vHeight : Integer;
    CursorThread : TTimer;
    function    CalcTheta(Angle : Word) : extended;
    Function    CreateBitmap:HPALETTE;
    Procedure   CheckXY;
    Procedure   DrawBuffer(Const Buffer : Array of byte);
    procedure   CursorThreadTimer(Sender: TObject);
  protected
    { Protected declarations }
  public
    { Public declarations }
    chrCols, chrRows : byte; //how many characters wide and how many high
    chrWidth, chrHeight : byte; //how wide and height a chacter in the current font is
    blinkOn : boolean; //if blinking attribute set will turn background normal intensity color and blink
    blinky  : boolean; //if blinkOn and blinky hi than foreground is displayed else color = background
                        // this was used by notariously used by iCE for doing displays.
    scrollLock : boolean; //if true when text is written at the bottom of screen it will wrap to the top of the screen
    WindMin : word;
    WindMax : word;
    cursorBlinkOn    : boolean;
    ActualBlinking   : boolean;
    DestructiveBS   : boolean;
    textBuf  : TImage;
    graphBuf : TImage;
//    dblBuf : TImage;  // final image before visible write
    WrapTop    : Byte;
    WrapBottom : Byte;
    Scrolling    : Boolean;
    ForcedReDraw : Boolean;
    FPS : word;
    VgaPal  : array[0..15] of TColor;
    FillStyle : TBrushStyle;
    procedure   updateScreen;  //performs update to dblbuf pages
    procedure   ScrollOn;
    Procedure   ScrollTo(Position : Integer;Buffer:TstringList);
    Procedure   ScrollOff;
    //define some new user functions
    procedure   init; //overload;  //this might be a bad idea
    procedure   setFont(fontName:string;bank,fwidth,fheight:byte;fsize:integer);  //sets the font parameters... can use outside font files but it must be in raw format
    procedure   setChrDim(cols,rows : integer);  //sets how many columns and rows are in text mode
    procedure   setResolution(w,h : integer);   // sets how many pixels are in bitmaped images  should be (fontwidth * cols), (fontheight * rows) but you can override this for what ever reason
    procedure   ClrScr; //clears the screen and wipes out direct memory    published
    procedure   GotoXY(x,y : integer); //set the cursor position
    function    WhereX : integer; //CRT standard for returning current cursor X position
    function    WhereY : integer; //CRT standard for returning current cursor Y position
    procedure   write(st:string);  //write formated text to the screen  (different from a direct write)
    procedure   writeLn(st:string);  //same thing as a write only does a character return and line feed at the end
    procedure   setTextColor(fg,bg : integer;blink:boolean);  //change colors of foreground, background, and if blink attribute
    procedure   InsLine; //scrolls all the text up one line leaving a new line at the cursor
    procedure   DelLine; //deletes cursor line and scrolls up from below cursor
    procedure   ClrEOL; //clear to the end of the line from current cursor position.
    procedure   TextColor(fg : byte);
    procedure   TextBackground(bg:byte);
    function    InvertColor : byte; //returns the invertion the current cursor tect color with the current background
    procedure   InvertText(x1,y1,x2,y2 : integer); //inverts display text from x1,y1 to x2,y2
//these functions are for VGA BGI emulation
    procedure   SetColor(color : integer);
    procedure   Rectangle(X1,Y1,X2,Y2 : integer);
    procedure   Ellipse(X1,Y1,X2,Y2 : integer);
    procedure   FillEllipse(X1,Y1,X2,Y2 : integer);
    procedure   Circle(X,Y, R : integer);
    procedure   Curve(p : array of tPoint); overload;
    procedure   Curve(x1,y1,x2,y2,x3,y3,x4,y4,count : integer); overload;
    procedure   MoveTo(x,y : integer);
    procedure   LineTo(x,y : integer);
    procedure   Bar(X1,Y1,X2,Y2 : integer);
    procedure   Arc(x,y : integer; start_deg, end_deg, radius : Word);
    procedure   FloodFill(x,y,border : integer);
    procedure   Line(x1,y1,x2,y2 : integer);
    procedure   PieSlice(X, Y: Integer; StAngle, EndAngle, Radius: Word);
    procedure   Sector(x, y: Integer; StAngle,EndAngle, XRadius, YRadius: Word);
    procedure   ClearDevice;
    procedure   OutTextXY(x,y : Integer; TextString : string);
    procedure   PutPixel(X, Y, C : Integer);
    procedure   DrawPoly(NumPoints: Word; var PolyPoints);
    procedure   FillPoly(NumPoints: Word; var PolyPoints);
    procedure   Repaint; override;
    constructor  Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    { Published declarations }
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TVgaEmu]);
end;

constructor  TVGAEmu.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Init;
end;

destructor TVGAEmu.Destroy;
begin
  GraphBuf.Destroy;
  TextBuf.Destroy;
  CursorThread.Destroy;

  inherited Destroy;
end;

{----------------------- ============================== ------------------------
                         Initalize Object Defaults
DESCRIPTION
  This method is called from Create and does alot functions
  similar to that which should be in a create.
  Reason for it seperation and public access is to allow
  application to reinitalize the component properities with out
  destroying the component. Kinda like a soft reboot for the
  component.
------------------------ ============================== -----------------------}
procedure TVgaEmu.Init;
var
  c : integer;
begin
  chrCols := 80;
  chrRows := 25;

  textbuf := Timage.create(self);
  graphBuf := TImage.create(self);

  setFont('default',0,8,16,4096); //set font bank 1
  setFont('default',1,8,16,4096); //set font bank 2

  SetResolution(640,400);

//set Graphics layer transparent shit
   GraphBuf.Transparent := false;
   GraphBuf.Picture.Bitmap.TransparentMode := tmFixed;
   GraphBuf.Picture.Bitmap.TransparentColor := VGAColor[16];
   with graphBuf.Canvas do begin
     Pen.Color := VGAColor[16];
     Brush.Color := VGAColor[16];
     Rectangle(0,0,vWidth,vHeight);
     Pen.Color := VgaPal[7];
   end;

  //Set timer
  //its the only practical way to make a thread behave in windows
  CursorThread := TTimer.Create(self);
  //this is the time of a DOS cursor blink. ANSI blink is than calced at 999 ms (or 1sec)
  CursorThread.Interval := 333;
  CursorThread.OnTimer := CursorThreadTimer;
  CursorThread.Enabled := true;


  Cursor.CurPos.x := 1;
  Cursor.CurPos.y := 1;
  Cursor.color := $07;

  BlinkOn := true;
  ActualBlinking := False;
  bufSize := crtNrmlBufLen;

  //fills the VGA color palette
  for c := 0 to 15 do
    VgaPal[c] := VgaColor[c];

end;

procedure TVgaEmu.CursorThreadTimer(Sender: TObject);
begin
  cursorBlinkOn := cursorBlinkOn xor true;
  inc(BlinkPhase);
  IF BlinkPhase >= 3 THEN BEGIN
    blinky := blinky xor true;
    BlinkPhase := 0;
  END;
  UpdateScreen;
end;
{----------------------- ============================== ------------------------
                   Check to see if active screen needs updating
------------------------ ============================== -----------------------}
procedure TVgaEmu.updateScreen;
begin
  DrawBuffer(RawBuffer);
  OldBlinky  := Blinky;
//  TextBuf.Canvas.Draw(0,0, GraphBuf.Picture.Bitmap);
  Canvas.StretchDraw(Canvas.ClipRect,TextBuf.Picture.Bitmap);
end;

{----------------------- ============================== ------------------------
  Repaint made by Shawn Rapp Oct, 21 2000
DESCRIPTION:
  This is NOT to be used like update.
  This function does not update blink phases while.
  This method is just to allow windows or parent application
  to tell the component to redraw what was there.
  Part of the inherited TWinControl
------------------------ ============================== -----------------------}
procedure TVgaEmu.Repaint;
begin
  inherited Repaint;
//  DrawBuffer(RawBuffer);
  Canvas.StretchDraw(Canvas.ClipRect,TextBuf.Picture.Bitmap);
end;


{###############################################################################
                             Screen Drawing Section
###############################################################################}

{----------------------- ============================== ------------------------
                         Main Buffer painting to dblbuf
------------------------ ============================== -----------------------}
procedure tVgaEmu.DrawBuffer(Const Buffer : Array of byte);
var
  SpecialY1,SpecialY2,base,R,I,xPos,yPos,x,y,FontXpos,fontYpos : integer;
  clr :byte;
  GrPix : PByteArray;
begin
//  Testing code for graphics
//   SetColor(15);
//   Circle(100,100,50);
//  test code end

   for I := 0 to (bufSize div 2)-1 do
   begin
      R := I * 2;
      //does background
      clr := Buffer[R+1] div 16;
      if (BlinkOn) and (clr > 7) then
         clr := clr - 8;
      yPos := (R div (chrCols*2) * font[0].Height);
      xPos := (R mod (chrCols*2) * (font[0].Width div 2));

      for fontYPos := 0 to font[0].Height-1 do
       begin
         GrPix := GraphBuf.Picture.Bitmap.ScanLine[yPos+fontYPos];
         for fontXPos := font[0].Width-1 downto 0 do
          begin

         //debug
            if Buffer[R+1] > $80 then
              blinky := blinky;
         //debug

            if GrPix[((xPos+Font[0].width-1)-fontXPos)] = 12 then
//            if GrPix[((xPos+Font[0].width-1)-fontXPos)] = VGAPal[16] then
             begin
               if (Buffer[R+1] < $80) or (blinky) then begin//blink set true than display character
                 base := 1 shl fontXPos;
                 if base = (Font[0].RawBuffer[ (Buffer[R] * Font[0].Height) + fontYPos] and base) then
                   screen[ (vWidth * (yPos+fontYPos)) + ((xPos+Font[0].width-1)-fontXPos) ] :=
                   Buffer[R+1] mod 16
                 else
                   Screen[((xPos+Font[0].width-1)-fontXPos)+((FontYpos+ypos)*vWidth)] := Clr; //background
               end else
                 Screen[((xPos+Font[0].width-1)-fontXPos)+((FontYpos+ypos)*vWidth)] := Clr; //background
             end else
               Screen[((xPos+Font[0].width-1)-fontXPos)+((FontYpos+ypos)*vWidth)] := GrPix[((xPos+Font[0].width-1)-fontXPos)];
          end;
       end;
   end; //end of for I loop and DrawScreen;

   if cursorBlinkOn then
   begin
      R := (Cursor.CurPos.X-1 + (Cursor.CurPos.y-1)*chrCols) * 2;
      yPos := ((R div (chrCols*2)) * font[0].Height);
      xPos := ((R mod (chrCols*2)) * (font[0].Width div 2));
      SpecialY1 := yPos;
      SpecialY2 := yPos+font[0].height-1;
      clr := 15;//lo(Cursor.color); im sick of the changing color currsor //tag
      For Y := SpecialY1 to SpecialY2 do
         For x := xPos to xPos+font[0].width-1 do
              screen[X+Y*vWidth] := clr;
   end;
   For Y := 0 to vHeight-1 do
   begin
      Row := textBuf.picture.bitmap.ScanLine[y];
      move(screen[(y*vWidth)],
           row^,
           (vWidth));
   end;
end;

{----------------------- ============================== ------------------------
                         Set screen font
------------------------ ============================== -----------------------}
procedure TVgaEmu.setFont(fontName:string;bank,fwidth,fheight:byte;fsize:integer);
var
  I : integer;
  f : file of byte;
  b : byte;
begin
  chrWidth := fwidth;
  chrHeight := fheight;
  setLength(Font[bank].RawBuffer,fsize);  //set the dynamic length of the array
  if (fontName = 'default') then
    for I := 0 to fsize-1 do
      Font[bank].RawBuffer[I] := defFontImage[I+1]
  else begin
    //load file and smash into buffer
    {$I-}
    AssignFile(f, fontName);
    Reset(f);
    {$I+}
    IF IOResult = 0 then begin
      I := 0;
      while (I < fsize-1) and (not EOF(f)) do begin
        read(f, b);
        Font[bank].RawBuffer[I] := b;
        inc(I);
      end;
      CloseFile(f);
    end else Application.MessageBox('Could not find file 8x8.raw','Haha you screwed up!',MB_OK);
  end;
  Font[bank].width := fwidth;
  Font[bank].height := fheight;
  Font[bank].size := fsize;
end;


{###############################################################################
                                Misc Procedures
###############################################################################}

{----------------------- ============================== ------------------------
                    Create a Dos text compatable pal 16 colors
------------------------ ============================== -----------------------}
Function TVgaEmu.CreateBitmap:HPALETTE;
var
   i : Integer;
   lpPalette : ^tagLOGPALETTE;
   Palette : HPALETTE;
begin
   GetMem(lpPalette,sizeof(word)*2+sizeof(TPaletteEntry)*256);
   with lpPalette^ do
   begin
      PalVersion := $300;
      PalNumEntries := 255;
   end;
  {-$R-}
   For I := 0 to 15 do
   with lpPalette.PalPalEntry[I] do
   begin
      peRed   := pbyteArray(@VGAColor[i])[0];
      peGreen := pbyteArray(@VGAColor[i])[1];
      peBlue  := pbyteArray(@VGAColor[i])[2];
   end;
   For I := 16 to 255 do
   with lpPalette.PalPalEntry[I] do
   begin
      peRed   := i;
      peGreen := i;
      peBlue  := i;
   end;
  {-$R+}
  Palette := CreatePalette(lpPalette^);
  FreeMem(lpPalette);
  if (Palette <> 0) then
   begin
     result := Palette;
   end
   else
    result := Palette;
end;


{###############################################################################
                                  CRT Section
###############################################################################}

{----------------------- ============================== ------------------------
                      Initalize buffers based on Col/row
------------------------ ============================== -----------------------}
procedure TVgaEmu.setChrDim(cols,rows:integer);
var
  w,h : integer;
begin
  chrCols := cols;
  chrRows := rows;
  w := (chrCols*Font[0].width);
  h := (chrRows*Font[0].height);
  textBuf.picture.bitmap.Width := w;
  textbuf.picture.bitmap.Height := h;
  textbuf.picture.bitmap.PixelFormat := pf8bit;
  textbuf.Picture.Bitmap.Palette := CreateBitmap;

  graphBuf.Picture.bitmap.Width := w;
  graphBuf.Picture.bitmap.Height := h;
  graphBuf.Picture.bitmap.PixelFormat := pf8bit;
  graphBuf.Picture.Bitmap.Palette := CreateBitmap;

  bufsize := chrCols * chrRows * 2;

  SetLength(Screen,w*h);
  setlength(rawbuffer,bufsize);
  setlength(ScrollBuffer, bufSize);

  WindMin := 0;
  WindMax := (chrCols-1) or ((chrRows-1) shl 8);
  WrapTop := 1;
  WrapBottom := ChrRows;
  vHeight := textBuf.picture.bitmap.Height;
  vWidth := textBuf.picture.bitmap.Width;
end;

{----------------------- ============================== ------------------------
                        Initalize buffers based on Pixels
------------------------ ============================== -----------------------}
procedure TVgaEmu.setResolution(w,h : integer);
begin
  textBuf.picture.bitmap.Width := w;
  textBuf.picture.bitmap.Height := h;
  textBuf.picture.bitmap.PixelFormat := pf8bit;
  textBuf.Picture.Bitmap.Palette := CreateBitmap;
  graphBuf.Picture.bitmap.Width := w;
  graphBuf.Picture.bitmap.Height := h;
//  graphBuf.Picture.Bitmap.PixelFormat := pf32bit;
  graphBuf.Picture.bitmap.PixelFormat := pf8bit;
  graphBuf.Picture.Bitmap.Palette := CreateBitmap;

  chrCols := (w div Font[0].width);
  chrRows := (h div Font[0].height);
  bufsize := chrCols * chrRows * 2;

  SetLength(Screen,w*h);
  setlength(rawbuffer,bufsize);
  setlength(ScrollBuffer, bufSize);

  WindMin := 0;
  WindMax := (chrCols-1) or ((chrRows-1) shl 8);
  WrapTop := 1;
  WrapBottom := ChrRows;
  vHeight := textBuf.picture.bitmap.Height;
  vWidth := textBuf.picture.bitmap.Width;
end;

{----------------------- ============================== ------------------------
                       Check for wraping and out of range
------------------------ ============================== -----------------------}
Procedure TVgaEmu.CheckXY;
begin
   if (Cursor.CurPos.x > ChrCols) then
   begin
      Cursor.CurPos.x := 1;
      inc(Cursor.CurPos.y);
   end;
   if (Cursor.CurPos.y > WrapBottom) then
   if ScrollLock then
   begin
      Cursor.CurPos.x := 1;
      Cursor.CurPos.y := WrapTop;
   end
   else
   begin
      if Cursor.CurPos.y > ChrRows then //tag tmr?????
         Cursor.CurPos.y := ChrRows;
      InsLine;
      Cursor.CurPos.x := 1;
      Cursor.CurPos.y := WrapBottom;
  end;
end;

{----------------------- ============================== ------------------------
                         Clear the Screen
------------------------ ============================== -----------------------}
procedure TVgaEmu.ClrScr;
var
  I : integer;
begin
  //this will fill the screen with black null chars
  //exactly what a freshly inited pc vga system does
  Cursor.CurPos.x := 1;
  Cursor.CurPos.y := 1;
  for I := 0 to bufSize-1 do begin
    rawBuffer[I] := 0;
  end;
  ActualBlinking := False;
  with graphBuf.Canvas do begin
    Pen.Color := VGAColor[16];
    Brush.Color := VGAColor[16];
    Rectangle(0,0,vWidth,vHeight);
    Pen.Color := VgaPal[7];
  end;
  graphBuf.Canvas.Pen.Color := clSilver;
end;

{----------------------- ============================== ------------------------
                         Goto X Y
------------------------ ============================== -----------------------}
procedure TVgaEmu.gotoXY(x,y : integer);
begin
    if X < 1 then
        Cursor.CurPos.x := 1
    else if X >= chrCols then
        Cursor.CurPos.x := chrCols
    else
        Cursor.CurPos.x := X;

    if Y < 1 then
        Cursor.CurPos.y := 1
    else if Y >= chrRows then
        Cursor.CurPos.y := chrRows
    else
        Cursor.CurPos.y := Y;
end;

{----------------------- ============================== ------------------------
                         Where is X
------------------------ ============================== -----------------------}
function TVgaEmu.WhereX : integer;
begin
  WhereX := Cursor.CurPos.x;
end;

{----------------------- ============================== ------------------------
                         Where is Y
------------------------ ============================== -----------------------}
function TVgaEmu.WhereY : integer;
begin
  WhereY := Cursor.CurPos.y;
end;

{----------------------- ============================== ------------------------
                         Write (line)
------------------------ ============================== -----------------------}
procedure TVgaEmu.write(st:string);
var
  I : integer;
  MemBufPos : integer;
begin
  for I := 1 to length(st) do
  begin
    case ord(st[i]) of
      0  : ; //placement holder to avoid nulls
      7  : BEGIN  //^G
            BEEP;
           END;
      8  : If DestructiveBS then begin //^H
             dec(Cursor.CurPos.x);
             if (Cursor.CurPos.x < 1) then Cursor.CurPos.x := 1;
             MemBufPos := (((Cursor.CurPos.y-1) * chrCols) + Cursor.CurPos.x-1)*2;
             RawBuffer[MemBufPos] := 32;
             RawBuffer[MemBufPos+1] := Cursor.Color;
           end else begin
             dec(Cursor.CurPos.x);
             if (Cursor.CurPos.x < 1) then Cursor.CurPos.x := 1;
           end;
      10 : BEGIN  //Line feed or ^J
               inc(Cursor.CurPos.y);
               CheckXY;
           END;
      12 : ClrScr;             //page feed or ^L
      13 : Cursor.CurPos.x := 1; //Cariage Return or ^M
      255 :;
    else //standard text to output to screen
    begin
//    CheckXY; //tag tmr
      MemBufPos := (((Cursor.CurPos.y-1) * chrCols) + Cursor.CurPos.x-1)*2;
      RawBuffer[MemBufPos] := ord(st[I]);
      RawBuffer[MemBufPos+1] := Cursor.Color;
      inc(Cursor.CurPos.x);
      CheckXY;
    end;
    end;
  end;
//  UpdateScreen;
end;

{----------------------- ============================== ------------------------
                         Write Line
------------------------ ============================== -----------------------}
procedure TVgaEmu.writeLn(st:string);
begin
  write(st+#13+#10);
end;

{----------------------- ============================== ------------------------
                         Set colors
------------------------ ============================== -----------------------}
procedure TVgaEmu.setTextColor(fg,bg : integer;blink:boolean);
begin
  if (bg < 8) and (fg < 16) then begin
    Cursor.Color := (bg * 16) + fg;
    if blink then Cursor.Color := Cursor.Color + 128;
  end;
end;

{----------------------- ============================== ------------------------
                         Insert a line
------------------------ ============================== -----------------------}
procedure TVgaEmu.InsLine;
var
  I, LineLen, StartI, EndI : integer;
begin
  linelen := (chrCols*2);
  StartI := (((WrapTop-1)*ChrCols)*2);
  if Cursor.CurPos.Y > ChrRows then
     EndI :=  ChrCols * ChrRows * 2
  else
     EndI := ChrCols * Cursor.CurPos.y * 2;
  for I := StartI to EndI-1 do
  begin
    if I < (EndI-linelen) then
      RawBuffer[I]:=RawBuffer[I+linelen]
    else
      RawBuffer[I] := 0; //fill bottom line with 0s
  end;
end;

{----------------------- ============================== ------------------------
                         Delete a line
------------------------ ============================== -----------------------}
procedure TVgaEmu.DelLine;
var
  I : integer;
  linelen : integer;
  endI : Integer;
begin
  linelen := (chrCols*2);
  endI := (WrapBottom*ChrCols*2)-1;
  for I := (chrCols * (Cursor.CurPos.y-1) * 2) to EndI do begin
    if (I < bufSize-linelen) then
      RawBuffer[I]:=RawBuffer[I+linelen]
    else
      RawBuffer[I] := 0; //fill bottom line with 0s
  end;
end;

{----------------------- ============================== ------------------------
                         Clear until End of Line
------------------------ ============================== -----------------------}
procedure TVgaEmu.ClrEOL;
var
  I : integer;
  MemBufPos : integer;
  EndPos : integer;
begin
  MemBufPos := (((Cursor.CurPos.y-1) * chrCols) + Cursor.CurPos.x-1)*2;
  EndPos :=    (((Cursor.CurPos.y-1) * chrCols) + ChrCols-1)*2;//((chrCols-1) - (Cursor.CurPos.X-1))*2;
   For I := MemBufPos to EndPos do
    RawBuffer[I] := 0;
end;

{----------------------- ============================== ------------------------
                         Set textForeground Color
------------------------ ============================== -----------------------}
procedure tVgaEmu.TextColor(fg:byte);
var
  bClr : byte;
begin //keeps everything but bit 8 and bit 1-4
  bClr := fg;
  if fg > 15 then
    bClr := ($0F and fg) + 128;  //eliminate all but first 4 bits and toggle 8th bit high for blinky

  Cursor.Color := ($70 and Cursor.color) + bClr;
end;

{----------------------- ============================== ------------------------
                         Set textBackground color
------------------------ ============================== -----------------------}
procedure tVgaEmu.TextBackground(bg:byte);
begin //keep only bit 1-4
  Cursor.Color := ($8F and Cursor.color) + (bg shl 4);
end;


{###############################################################################
                                Scroll Section
###############################################################################}

{----------------------- ============================== ------------------------
                                  Scroll on
------------------------ ============================== -----------------------}
procedure tVgaEmu.ScrollOn;
begin
   Scrolling := True;
end;

{----------------------- ============================== ------------------------
                                 Scroll off
------------------------ ============================== -----------------------}
procedure tVgaEmu.ScrollOff;
begin
   Scrolling := False;
end;

{----------------------- ============================== ------------------------
                        Display String buffer at Position
------------------------ ============================== -----------------------}
Procedure tVgaEmu.ScrollTo(Position : Integer; Buffer : TStringList);
var
   StartLine, EndLine : Integer;
   ScrollPos : Integer;
   I,X,Y,Z : Integer;
   S   : String;
begin
   if Scrolling {and (vgabuf.picture.bitmap.canvas.lockcount = 0)} then
   begin
      FillChar(ScrollBuffer[0],Length(Scrollbuffer),0);

      StartLine := Position;
      EndLine := StartLine + (ChrRows-1);

      if EndLine > buffer.count-1 then
      begin
         StartLine := Buffer.Count-1-(ChrRows-1);
         EndLine := Buffer.Count-1;
      end;

      if StartLine < 0 then
      begin
         EndLine := Buffer.Count-1;
         StartLine := 0;
      end;

      Z := -1;
      For I := StartLine to EndLine do
      begin
         inc(Z);
         ScrollPos := (Z * ChrCols)*2;
         S := Buffer[i];
         X := Length(S);
         if X > ChrCols then X := ChrCols;
         For Y := 1 to X do
         begin
            if not (S[Y] in [#10,#13,' ']) then //fillter chars //tag
            ScrollBuffer[ScrollPos] := ord(S[Y]);
            ScrollBuffer[ScrollPos+1] := 15;
            inc(ScrollPos,2);
         end;
      end;
         DrawBuffer(ScrollBuffer);
   end;
end;

procedure tVgaEmu.SetColor(color : integer);
begin
  graphBuf.Canvas.Pen.Color := VgaPal[color];
  graphBuf.Canvas.Brush.Color := VgaPal[color]; // ???
end;

Procedure tVgaEmu.Rectangle(X1,Y1,X2,Y2 : integer);
begin
//  graphBuf.Canvas.Brush.Style := bsClear;
  graphBuf.Canvas.Rectangle(x1,y1,x2,y2);
  graphBuf.Canvas.Brush.Style := FillStyle;
end;

{----------------------- ============================== ------------------------
                        Draws a Elipse into VGA bufffer
------------------------ ============================== -----------------------}
Procedure tVgaEmu.Ellipse(X1,Y1,X2,Y2 : integer);
begin
  graphBuf.Canvas.Brush.Style := bsClear;
  graphBuf.Canvas.Ellipse(x1,y1,x2,y2);
  graphBuf.Canvas.Brush.Style := FillStyle;
end;

procedure tVgaEmu.FillEllipse(X1,Y1,X2,Y2 : integer);
begin
  graphBuf.Canvas.Ellipse(x1,y1,x2,y2);
end;

procedure tVgaEmu.Circle(X,Y,R : integer);
begin
  graphBuf.Canvas.Ellipse(x,y,x+r,y+r);
end;

procedure tVgaEmu.Curve(p: array of tPoint);
begin
  graphBuf.Canvas.PolyBezier(p);
end;

procedure tVgaEmu.Curve(x1,y1,x2,y2,x3,y3,x4,y4,count : integer);
  FUNCTION pow (x : REAL; y : WORD) : REAL;
  VAR
    nt     : WORD;
  BEGIN
    result := 1;
      FOR nt := 1 TO y DO
        result := result * x;
        pow := result;
  END;

  PROCEDURE Bezier (t : REAL; VAR x, y : INTEGER);
  BEGIN
    x := TRUNC (pow (1 - t, 3) * x1 + 3 * t * pow (1 - t, 2) * x2 +
                3 * t * t * (1 - t) * x3 + pow (t, 3) * x4);
    y := TRUNC (pow (1 - t, 3) * y1 + 3 * t * pow (1 - t, 2) * y2 +
                3 * t * t * (1 - t) * y3 + pow (t, 3) * y4);
  END;

VAR
 resolution, t : REAL;
 xc, yc       : INTEGER;
BEGIN
  IF count = 0 THEN EXIT;
  resolution := 1 / count;
  graphBuf.Canvas.MoveTo(x1, y1);
  t := 0;
  WHILE t < 1 DO BEGIN
    Bezier (t, xc, yc);
    graphBuf.Canvas.LineTo(xc,yc);
    t := t + resolution;
  END;
  graphBuf.Canvas.LineTo(x4,y4);
END;

procedure tVgaEmu.MoveTo(x,y : integer);
begin
  graphBuf.Canvas.MoveTo(x,y);
end;

procedure tVgaEmu.LineTo(x,y : integer);
begin
  graphBuf.Canvas.LineTo(x,y);
end;

procedure tVgaEmu.Bar(x1,y1,x2,y2 : integer);
begin
  graphBuf.Canvas.FillRect(rect(x1,y1,x2,y2));
end;

procedure tVgaEmu.FloodFill(x,y,border : integer);
begin
  graphBuf.Canvas.FloodFill(x,y,VGAPal[border],fsBorder);
end;

procedure tVgaEmu.Line(x1,y1,x2,y2 : integer);
begin
  graphBuf.Canvas.MoveTo(x1,y1);
  graphBuf.Canvas.LineTo(x2,y2);
end;

{-------------------------------------------------------------------------------
CalcTheta(Angle : word) returns extended
This function calculates a theta for a Borland BGI angle theta which uses
a system where degree 0 is at the right and than increments counter clockwise.
Don't ask me why they did this... I think it was a cruel joke or something.
0 degrees = east, 180 degrees = west, 90 degrees = north,
270 degrees = south.
DO NOT ENTER RADIANS INTO ANGLE!!! DUH!
-------------------------------------------------------------------------------}
function tVgaEmu.CalcTheta(Angle : word) : extended;
var
  degree : integer;
begin
  Degree := 450 - Angle;
  if Degree > 360 then Degree := Degree - 360;
  result := (Degree * pi) / 180;
end;

procedure tVgaEmu.Arc(x,y : integer; start_deg, end_deg, radius : word);
var
  x1,y1,
  x2,y2,
  x3,y3,
  x4,y4 : integer;
  theta : extended;
begin
  x1 := x - radius; y1 := y - radius;
  x2 := x + radius; y2 := y + radius;
  theta := CalcTheta(start_deg);
  x3 := trunc(radius*sin(theta));
  y3 := trunc(radius*cos(theta));
  theta := CalcTheta(end_deg);
  x4 := trunc(radius*sin(theta));
  y4 := trunc(radius*cos(theta));

  graphBuf.Canvas.Arc(x1,y1,x2,y2,x3,y3,x4,y4);
end;

procedure tVgaEmu.PieSlice(X, Y: Integer; StAngle, EndAngle, Radius: Word);
var
  x1,y1,
  x2,y2,
  x3,y3,
  x4,y4 : integer;
  theta : extended;
begin
  x1 := x - radius; y1 := y - radius;
  x2 := x + radius; y2 := y + radius;

  theta := CalcTheta(StAngle);
  x3 := trunc(radius*sin(theta));
  y3 := trunc(radius*cos(theta));

  theta := CalcTheta(EndAngle);
  x4 := trunc(radius*sin(theta));
  y4 := trunc(radius*cos(theta));

  graphBuf.Canvas.Pie(x1,y1,x2,y2,x3,y3,x4,y4);
end;

procedure tVgaEmu.Sector(x, y: Integer; StAngle,EndAngle, XRadius, YRadius: Word);
var
  x1,y1,
  x2,y2,
  x3,y3,
  x4,y4 : integer;
  theta : extended;
begin
  x1 := x - XRadius; y1 := y - YRadius;
  x2 := x + XRadius; y2 := y + YRadius;

  theta := CalcTheta(StAngle);
  x3 := trunc(XRadius * sin(theta));
  y3 := trunc(YRadius * cos(theta));

  theta := CalcTheta(EndAngle);
  x4 := trunc(XRadius*sin(theta));
  y4 := trunc(YRadius*cos(theta));

  graphBuf.Canvas.Pie(x1,y1,x2,y2,x3,y3,x4,y4);
end;

procedure tVgaEmu.ClearDevice;
var
  X, y : integer;
begin
  ClrScr;
end;

procedure TVgaEmu.OutTextXY(x,y: Integer; TextString: String);
begin
  graphBuf.Canvas.Brush.Style := bsClear;
  graphBuf.Canvas.Font.Color := graphBuf.Canvas.Pen.Color;
  graphBuf.Canvas.Font.Height := 9;
  graphBuf.Canvas.Font.Pitch := fpFixed;
  graphBuf.Canvas.TextOut(x,y,TextString);
  graphBuf.Canvas.Brush.Style := FillStyle;
end;

procedure TVgaEmu.PutPixel(X, Y, C : Integer);
begin
  graphBuf.Canvas.Brush.Style := bsClear;
  graphBuf.Canvas.Pixels[X,Y] := VGAColor[c];
  graphBuf.Canvas.Brush.Style := FillStyle;
end;

procedure TVgaEmu.DrawPoly(NumPoints: Word; var PolyPoints);
begin
  graphBuf.Canvas.Brush.Style := FillStyle;
  graphBuf.Canvas.Polygon(TPoint(PolyPoints));
end;

procedure TVgaEmu.FillPoly(NumPoints: Word; var PolyPoints);
begin
  graphBuf.Canvas.Polygon(TPoint(PolyPoints));
end;

function TVgaEmu.InvertColor : byte;
var
  valRet,
  valFG,
  valBG : byte;
begin
  valBG := (Cursor.Color and $07) shl 4; //take current foreground move it to background value
  valFG := (Cursor.Color and $70) shr 4; //take current background and move it to the foreground value
  valRet := (Cursor.Color and $88) + valBG + valFG; //leave intensity and flashing bits as is and add together background and foreground
  result := valRet; //viola!
end;

procedure TVgaEmu.InvertText(x1,y1,x2,y2 : integer);
var
  startPos,
  endPos,
  curPos,
  memPos : integer;
  valRet,
  valFG,
  valBG : byte;
begin
  startPos := ((y1-1)*chrCols) + (x1-1); //where in text buffer to start
  endPos := ((y2-1)*chrCols) + (x2-1); //where in the text buffer to end
  if endPos > startPos then begin //ensure that the selection is from top right to bottom left style
    for curPos := startPos to endPos do begin
      memPos := (curPos * 2) + 1;
      valFG := (rawBuffer[memPos] and $07) shl 4;
      valBG := (rawBuffer[memPos] and $70) shr 4;
      valRet := (rawBuffer[memPos] and $88) + valBG + valFG;
      rawBuffer[memPos] := valRet;
    end;
  end;
  DrawBuffer(rawBuffer);
end;

end.
