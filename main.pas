unit main;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, TNCNX, StdCtrls, Buttons, ComCtrls, ImgList, VgaEmu;

type
  TMF = class(TForm)
    Panel_SysBar: TPanel;
    Panel_StatusBar: TPanel;
    ImgSizer: TImage;
    ButtonsImageList: TImageList;
    MainScrollBar: TScrollBar;
    ImgSysBar: TImage;
    ButtonImages: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MainSocketDataAvailable(Sender: TTnCnx; Buffer: PChar;
      Len: Integer);
    procedure MaxResWin;
    procedure ImgSysBarMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ImgSysBarMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImgSysBarDblClick(Sender: TObject);
    procedure ImgSizerMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImgSizerMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ButtonImagesMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ButtonImagesMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure ImgSizerMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormDestroy(Sender: TObject);
    procedure MainSocketSessionClosed(Sender: TTnCnx; Error: Word);

    procedure UpdateScrollBar;
    procedure MainScrollBarScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);
    procedure FormResize(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure VgaEmu1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure VgaEmu1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure VgaEmu1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
     Xbase, Ybase, LeftBase, Topbase, Xnew, Ynew : integer;
     AfterStep : Boolean;
     OldHeight, OldWidth : Word;
     color     : tColor;
     dataScope : boolean;
     fullscreen : boolean;
     procedure toggle50Col;
     procedure toggleDataScope;
     procedure appfocuson(Sender: TObject);
     procedure appfocusoff(Sender: TObject);
     procedure Resetwindowsize;
  public
{    Parser : TIOBuf;}
    procedure DataIn( strIn : PChar; Len : integer ); overload;
    procedure DataIn( strIn : String ); overload;
    procedure DataOut(chr: string);
    procedure Connect;
    procedure Disconnect;
    procedure SendMsg(msg:string);
    Procedure Logchar(ch:char);
    procedure AddArea(x0,y0,x1,y1 : integer; cmdType : word; cmd : string);
    procedure DeleteArea(pos : integer);
    procedure ClearAreas;
    procedure ExecuteAreas(x,y : integer; execType : word);
  end;

var
  MF: TMF;
  repaintok : boolean = true;
  RipLine : boolean;

implementation

uses DialForm, IceAnsi, RipParse, MsgForm, Globals, Config, Help;
{$R *.lfm}

{###############################################################################
                          FORM SECTION
###############################################################################}

{--------------------- ================ -------------------
                  avoid clearing the background
               (causes flickering and speed penalty)
 --------------------- ================ -------------------}
procedure TMF.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin Message.Result:=1; end;

{--------------------- ================ -------------------
                       Form Create
 --------------------- ================ -------------------}
procedure TMF.FormCreate(Sender: TObject);
begin
  //handles focus and alt-tab etc
  Application.OnActivate := appfocuson;
  Application.OnDeactivate := appfocusoff;
  fullscreen := false;

  //init VgaEmu1
  VgaEmu1.Init;
  VgaEmu1.setResolution(640,400);


  //Initalize ScrollBack Buffer
  LogingMode := lmPlainText;
  LogingBuffer := TstringList.Create;
  LogingStr := '';
  UpdateScrollBar;

  //init Form content
  OldHeight := 0;
  AfterStep := False;
  ImgSysBar.Align := AlNone;
  ImgSysBar.SendToBack;
  ImgSysBar.Width := MF.Width;
  ButtonImages.BringToFront;

  AreaList := tList.Create;

  //initalize ansi
  InitAnsi;

{  Parser := TIOBuf.Create(false);}
end;

{--------------------- ================ -------------------
                         Destroy Form
 --------------------- ================ -------------------}
procedure TMF.FormDestroy(Sender: TObject);
begin
   {$IFDEF WINNT}
   DXDrawFinalize(Sender);
   {$ENDIF}
   VgaEmu1.Free;
   if MainSocket.IsConnected then
      MainSocket.Close;
   MainSocket.Destroy;
end;

{--------------------- ================ -------------------
                       Form keypressed
 --------------------- ================ -------------------}
procedure TMF.FormKeyPress(Sender: TObject; var Key: Char);
begin
  DataOut(Key);
end;

{--------------------- ================ -------------------
                       Form KeyDown
 --------------------- ================ -------------------}
procedure TMF.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  keyChr : string;
begin //do hot keys
  if ssAlt in Shift then
    case Key of
      13 : MaxResWin; //ALT-ENTER
      67 : begin //Alt-C
             frmConfig.ShowModal
           end;
      68 : begin  //ALT-D
             if frmDial.ShowModal = mrOk then
               Connect;
           end;
      72 : Disconnect; //ALT-H
      84 : VgaEmu1.InvertText(1,1,80,25); //alt-T
      86 : toggle50Col;
    end; //ends case key statement

//  VgaEmu1.write(inttostr(key));  //debug stuff for finding keys
//  VgaEmu1.textBuf.Canvas.TextOut(10,10,inttostr(Key));

  keyChr := #0;
  case Key of
//  33 : ; //pgup  (broken ???)
//  34 : ; //pgdn  (broken ???)
    35 : keyChr := #27 + '[K'; //end
    36 : keyChr := #27 + '[H'; //home
    37 : keyChr := #27 + '[D'; //left
    38 : keyChr := #27 + '[A'; //up
    39 : keyChr := #27 + '[C'; //right
    40 : keyChr := #27 + '[B'; //down
    45 : keyChr := #22;        //insert key
    46 : keyChr := #127;       //delete key
    112 : begin //f1
            frmHelp.ShowModal;
          end;
    122 : Resetwindowsize; //F11
    123 : ToggleDataScope; //F12
  end;
  IF keyChr <> #0 then DataOut(keyChr);
end;

{--------------------- ================ -------------------
                    Form Normal/Maximize
 --------------------- ================ -------------------}
procedure TMF.MaxResWin;
begin
  if MF.windowState <> wsMaximized then
  begin
    if OldHeight <> 0 then
      ImgSysBarDblClick(self);
    ButtonImages.Hide;
    Panel_SysBar.Hide;
    ImgSizer.Hide;
    Panel_StatusBar.Hide;
    MainScrollBar.Hide;
    MF.WindowState := wsMaximized;
    fullscreen := true;
  end else begin
    MF.WindowState := wsNormal;
    Panel_SysBar.Show;
    ButtonImages.Show;
    Panel_StatusBar.Show;
    ImgSizer.Show;
    MainScrollBar.Show;
    fullscreen := False;
  end;
end;

{--------------------- ================ -------------------
                  Reset window size to screen res;
 --------------------- ================ -------------------}
procedure TMF.Resetwindowsize;
var
  h : Integer;
begin
  if fullscreen then //then switch back to normal
     MaxResWin;    

  h := VgaEmu1.textbuf.Picture.Bitmap.Height;
  inc(h,panel_statusbar.height);
  inc(h,panel_sysbar.height);
  clientwidth := VgaEmu1.textbuf.Picture.Bitmap.Width + MainScrollBar.width;
  clientheight := h;
end;

{--------------------- ================ -------------------
                  System Toolbar Start moving
 --------------------- ================ -------------------}
procedure TMF.ImgSysBarMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
    Xbase := X;
    LeftBase := MF.Left;

    YBase := Y;
    TopBase := MF.Top;
end;

{--------------------- ================ -------------------
                   System Toolbar Move around
 --------------------- ================ -------------------}
procedure TMF.ImgSysBarMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);

begin
   if (ssLeft in Shift) then begin
      Xnew := LeftBase + (X - Xbase);
      Ynew := TopBase + (Y - Ybase);
      MF.Top := YNew;
      MF.left  := Xnew;
      LeftBase := MF.Left;
      TopBase := MF.Top;
  end;
end;

{--------------------- ================ -------------------
                   System Toolbar Shrink
 --------------------- ================ -------------------}
procedure TMF.ImgSysBarDblClick(Sender: TObject);
var
 min : integer;
begin
    AfterStep := AfterStep xor true;
   if AfterStep then
   begin
      Panel_StatusBar.Visible := false;
      OldHeight := MF.Height;
      min := Panel_SysBar.Height + ((Panel_SysBar.BevelWidth-1) * 2);
      MF.Height := min;
   end
   else
    begin
      MF.Height := OldHeight;
      OldHeight := 0;
      Panel_StatusBar.Visible := true;
    end;
end;

{--------------------- ================ -------------------
                   Form Sizer start movement
 --------------------- ================ -------------------}
procedure TMF.ImgSizerMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  OldWidth := MF.Width;
  OldHeight := MF.Height;
  XBase := X;
  YBase := Y;
end;

{--------------------- ================ -------------------
                   Form Sizer resize form
 --------------------- ================ -------------------}
procedure TMF.ImgSizerMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
   xx,yy : integer;
begin
   if (ssLeft in Shift) then
    begin
      if MF.WindowState = wsMaximized then
      begin
         xNew := MF.Width;
         yNew := MF.Height;
         xx   := MF.top;
         yy   := MF.Left;
         MF.WindowState := wsNormal;
         MF.Width := xNew;
         MF.Height := yNew;
         MF.Top := xx;
         MF.Left := yy;
      end;
      Xnew := OldWidth + (X - Xbase);
      Ynew := OldHeight + (Y - Ybase);
      MF.Height := YNew;
      MF.width := Xnew;
      OldWidth := MF.Width;
      OldHeight := MF.Height;
    end;
end;

{--------------------- ================ -------------------
                   Form sizer stop sizing
 --------------------- ================ -------------------}
procedure TMF.ImgSizerMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin OldHeight := 0; end;

{--------------------- ================ -------------------
                     System Button Click
 --------------------- ================ -------------------}
procedure TMF.ButtonImagesMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
   Bitmap : Tbitmap;
begin
   if ssLeft in shift then
   begin
   bitmap := tBitmap.create;
   bitmap.PixelFormat := pf8bit;
   ButtonsImageList.getBitmap(1,Bitmap);

   color := bitmap.Canvas.Pixels[x,y];
   if color <> clWhite then
   begin
   if Color = clRed then
   begin
   ButtonsImageList.GetBitmap(2,ButtonImages.Picture.Bitmap);
   end
   else
   if color = clYellow then
   begin
   ButtonsImageList.GetBitmap(3,ButtonImages.Picture.Bitmap);
   end
   else
   if color = clBlue then
   begin
   ButtonsImageList.GetBitmap(4,ButtonImages.Picture.Bitmap);
   end
   else
   if color = clLime then
   begin
   ButtonsImageList.GetBitmap(5,ButtonImages.Picture.Bitmap);
   end;
   ButtonImages.Invalidate;
   end;
   bitmap.Destroy;
   end;
end;

{--------------------- ================ -------------------
                 System Buttons Preform tasks
 --------------------- ================ -------------------}
procedure TMF.ButtonImagesMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
   if color <> clWhite then
   begin
   if Color = clRed then
   begin
     Resetwindowsize;
   end
   else
   if color = clYellow then
   begin
      MF.WindowState := wsMinimized;
   end
   else
   if color = clBlue then
   begin
      MaxResWin;
   end
   else
   if color = clLime then
   begin
     Application.Terminate;
   end;
   color := clWhite;
   ButtonsImageList.GetBitmap(0,ButtonImages.Picture.Bitmap);
   ButtonImages.Invalidate;
   end;
end;

{--------------------- ================ -------------------
                     Form Resize capture
 --------------------- ================ -------------------}
procedure TMF.FormResize(Sender: TObject);
begin
   ImgSysBar.Width := Panel_SysBar.Width;
end;


{###############################################################################
                          TELNET SECTION
###############################################################################}

{--------------------- ================ -------------------
                       Connect to Telnet
 --------------------- ================ -------------------}
procedure TMF.Connect;
begin
  MainSocket.Host := frmDial.HostEdit.Text;
  MainSocket.Port :=  frmDial.PortEdit.Text;
  MainSocket.Connect;
end;

{--------------------- ================ -------------------
                    Disconnect from Telnet
 --------------------- ================ -------------------}
procedure TMF.Disconnect;
begin
  MainSocket.Close;
end;

{--------------------- ================ -------------------
                Send Data out through telnet
 --------------------- ================ -------------------}
procedure TMF.DataOut(chr : string);
begin
  IF MainSocket.IsConnected THEN
    MainSocket.SendStr(chr)
  ELSE begin
    VgaEmu1.write(chr);
  end;
end;

{--------------------- ================ -------------------
                      Telnet Data Avalible
 --------------------- ================ -------------------}
procedure TMF.MainSocketDataAvailable(Sender: TTnCnx; Buffer: PChar;
  Len: Integer);
begin
  DataIn(Buffer, Len);
end;

{--------------------- ================ -------------------
                         Close Telnet
 --------------------- ================ -------------------}
procedure TMF.MainSocketSessionClosed(Sender: TTnCnx; Error: Word);
begin
  SendMsg('Disconnected from host.');
end;


{###############################################################################
                      DATA PROCESSING SECTION
###############################################################################}

{--------------------- ================ -------------------
                      Process input data (Pchar)
 --------------------- ================ -------------------}
procedure TMF.DataIn( strIn : PChar; Len : integer );
var
  I : integer;
begin
  for I := 0 to len-1 do begin
     if StrIn[i] <> #$0F then
     begin
        if (Display_Rip(strIn[I]) = false) then
          Ice_Display_ANSI(strIn[I]);
        LogChar(StrIn[i]);
     end;
  end;

{  Parser.Add(strIn);}
end;

{--------------------- ================ -------------------
                      Process input data (String)
                      (Not Active)
 --------------------- ================ -------------------}
procedure TMF.DataIn( strIn : string );
var
  I,L : integer;
begin
  L := Length(Strin);
  for I := 0 to L do
  begin
    Ice_Display_ANSI(strIn[I]);
    //Display_Rip(strIn[I]);
    LogChar(StrIn[i]);
  end;

{  Parser.Add(strIn);}
end;

{--------------------- ================ -------------------
          Create a ~2-3 Second Dialog with MSG
 --------------------- ================ -------------------}
procedure TMF.SendMsg(msg:string);
begin
  Form2.Label1.Font.Color := clLime;
  Form2.Label1.Caption := msg;
  Form2.Show;
end;


{###############################################################################
                       Logging Section
###############################################################################}

{--------------------- ================ -------------------
                    Add a char to Log buffer
 --------------------- ================ -------------------}
Procedure TMF.Logchar(ch:char);
begin
   LogingStr := LogingStr + Ch;
   if Ch = #10 then //#10 should be a future option for dilimiter
   begin
      LogingBuffer.add(LogingStr);
      LogingStr := '';
      UpdateScrollBar;
   end;
end;


{###############################################################################
                     Scrolling buffer section
###############################################################################}

{--------------------- ================ -------------------
                     Update Scrollbar position
 --------------------- ================ -------------------}
Procedure TMF.UpdateScrollBar;
var
  X : Integer;
begin
   if not VgaEmu1.Scrolling then
   begin
      X := (LogingBuffer.count-VgaEmu1.ChrRows+1);
      if X < 1 then
         X := 1;
      if MainScrollBar.Max <> X then
         MainScrollBar.Max := X;
         MainScrollBar.Position := X;
   end;
end;

{--------------------- ================ -------------------
                  Start/Stop/Scroll buffer
 --------------------- ================ -------------------}
procedure TMF.MainScrollBarScroll(Sender: TObject; ScrollCode: TScrollCode;
  var ScrollPos: Integer);
begin
   if LogingBuffer.count > VgaEmu1.chrRows then
   begin
      if ScrollPos = MainScrollBar.Max then
      begin
         VgaEmu1.ScrollOff;
      end
      else
      if not VgaEmu1.Scrolling then
         VgaEmu1.ScrollOn;
      if VgaEmu1.Scrolling then
         VgaEmu1.ScrollTo(ScrollPos,LogingBuffer);
   end;
end;


{###############################################################################
                      Misc Timer Section (blink/cursor)
###############################################################################}
procedure TMF.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  repaintok := false;
end;

{--------------------- ================ -------------------
                        Cursor Timer
 --------------------- ================ -------------------}
procedure TMF.toggle50Col;
var
  i,
  x,y : byte;
begin
  if VgaEmu1.chrRows = 25 then begin
    VgaEmu1.setFont('8x8.raw',0,8,8,2048); //set font bank 1 to a outside 50 col font rom file.
    VgaEmu1.setChrDim(80,50);
  end else begin
    y := VgaEmu1.WhereY;
    x := VgaEmu1.WhereX;
    if (y > 25) then begin
      VgaEmu1.GotoXY(x,50);
      for i := 1 to 25 do VgaEmu1.Write(#10);
      VgaEmu1.GotoXY(x,25);
      end;
    VgaEmu1.setFont('default',0,8,16,4096); //set font bank 1
    VgaEmu1.setChrDim(80,25);
  end;
end;

procedure TMF.toggleDataScope;
var x,y,i :byte;
begin
  if DataScope then begin
    VgaEmu1.setFont('hex.raw',0,8,8,2048); //set font bank 1 to a outside 50 col font rom file.
    VgaEmu1.setChrDim(80,50);
  end else begin
    y := VgaEmu1.WhereY;
    x := VgaEmu1.WhereX;
    if (y > 25) then begin
      VgaEmu1.GotoXY(x,50);
      for i := 1 to 25 do VgaEmu1.Write(#10);
      VgaEmu1.GotoXY(x,25);
      end;
    VgaEmu1.setFont('default',0,8,16,4096); //set font bank 1
    VgaEmu1.setChrDim(80,25);
  end;
  DataScope := DataScope xor true;
end;

procedure TMF.appfocuson(Sender: TObject);
begin
  imgsysbar.visible := true;
end;

procedure TMF.appfocusoff(Sender: TObject);
begin
  imgsysbar.visible := false;
end;

procedure TMF.AddArea(x0,y0,x1,y1 : integer; cmdType : word; cmd : string);
var
  newArea : pArea;
begin
//adds a new mouse area command
  new(newArea);
  newArea^.x0 := x0;
  newArea^.y0 := y0;
  newArea^.x1 := x1;
  newArea^.y1 := y1;
  newArea^.cmdType := cmdType;
  newArea^.cmd := cmd;
  Arealist.Add(newArea);
//  dispose(newArea);  //I was being a naughty monkey =)
end;

procedure TMF.DeleteArea(pos : integer);
begin
//deletes a record out of the list
  AreaList.Delete(pos);
end;

procedure TMF.ClearAreas;
begin
//deletes all records in the area list
  Arealist.Clear;
end;

procedure TMF.ExecuteAreas(x,y : integer; execType : word);
var
  areaPos : integer;
  curArea : pArea;
begin
//find and execute cmd based on position x,y
  if AreaList.Count > 0 then
   begin
     new(curArea);
     for areaPos := 0 to AreaList.Count-1 do
      begin
        curArea := AreaList.Items[areaPos];
        if (curArea^.x0 <= x) and (curArea^.x1 >= x) then
         if (curArea^.y0 <= y) and (curArea^.y1 >= y) then
          begin
            case curArea^.cmdType of
              0  : begin  // cmdtype 0 sends stored command to connection
                     if execType = 1 then //only executes on mouse click
                      DataOut(curArea^.cmd);
                   end;
            end;
          end;
      end;
//     dispose(curArea);
   end;
end;

procedure TMF.VgaEmu1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ExecuteAreas(x,y,1);  //send mouse position as mouse pointer is possiably clicking on a area
end;

procedure TMF.VgaEmu1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  //ExecuteAreas(x,y,0);  //send mouse position as mouse pointer is possiably overend
end;

procedure TMF.VgaEmu1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ExecuteAreas(x,y,2);  //send mouse position as mouse pointer is possiably unclicked from a area
end;

end.

