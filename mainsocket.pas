unit mainSocket;

{$mode delphi}

interface

uses
  Classes,
  {$ifdef unix}
    cthreads,
    cmem, // the c memory manager is on some systems much faster for multi-threading
  {$endif}
  SysUtils, sockets;

type
  TMainSocketHasData = procedure(buffer: Pchar; Len: Word);
  TMainSocketSessionClosed = procedure(Error: Integer);

  TMainSocket  = class(TThread)
  private
         connected : boolean;
         SocketError : Integer;
         TCP : TSocket;
         len  : longint;
         saddr : sockaddr;
         addrlen : integer;
  protected
         procedure Execute; override;
  public
    host : string;
    port : string;
    HasData : TMainSockethasData;
    SessionClosed : TMainSocketSessionClosed;
    property IsConnected : boolean read Connected;
    constructor create;
    procedure close;
    procedure connect;
    procedure sendstr(s:string);
  end;

implementation

function StrToAddr(s : String) : LongInt;
var
   c : LongInt;
   i : byte;
   r,p : cardinal;
   t : String;
begin
   StrToAddr := 0;
   r := 0;
   for i := 0 to 3 do
   begin
      p := Pos('.', s);
      if p = 0 then p := Length(s) + 1;
      if p <= 1 then exit;
      t := Copy(s, 1, p - 1);
      Delete(s, 1, p);
      Val(t, p, c);
      if (c <> 0) or (p < 0) or (p > 255) then exit;
      r := r or p shl (i * 8);
   end;
   StrToAddr := r;
end;

constructor TMainSocket.create;
begin
   Inherited create(true);
   host := '';
   port := '';
   Connected := false;
   len := 0;
   addrlen := 0;
   TCP := fpsocket(AF_INET, SOCK_STREAM, 0);
   if (TCP = NOT(0)) then
     socketError := -1
   else
   begin
     addrlen := sizeof(saddr);
     fillchar(saddr, 0, addrlen);
     saddr.sin_family := AF_INET;
     saddr.sin_addr.s_addr := INADDR_ANY;
   end;
end;

procedure TMainSocket.connect;
begin
   if (not IsConnected) then
   try
      saddr.sin_port := htons(strtoint(port));
      saddr.sin_addr.s_addr :=htonl(strtoaddr(Host));
      If fpconnect(TCP,@saddr,Sizeof(saddr)) = -1 Then
         socketError := -2
      else
      begin
          Connected := true;
          start;
      end;
   finally
   end;
end;

procedure TMainSocket.close;
begin
   if (Connected) then
   try
      CloseSocket(TCP);
      Connected := false;
   finally
     SessionClosed(socketError);
   end;
end;

procedure TMainSocket.SendStr(S:string);
var
  Count : integer;
begin
   if (SocketError > -1) then
   begin
      Count := fpsend(TCP,@S[1],Length(S),0);
         if (Count = SOCKET_ERROR) then
               socketError := -3;
   end;
end;

procedure TMainSocket.Execute;
var
   Count : integer;
   Buffer : array[0..65535] of byte;
begin
  While (TCP <> NOT(0)) and (socketError > -1) do
  begin
    Count := fprecv(TCP,@Buffer[0],65530,0);
    if Count <> SOCKET_ERROR Then
       hasData(@Buffer[0],Count)
    else
        SocketError := -4;
  end;
end;

end.

