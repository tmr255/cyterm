unit globals;

{$MODE Delphi}

{
CyTerm Project.
globals  created by Shawn Rapp

Not too itresting stuff here.
}

interface

uses classes;

const
  SoftwareName = 'AutoTerminator';
  SoftwareVer  = '1.0.0';
  //Loging mode types
  lmPlainText = 0;
  lmAnsiText  = 1;

type
  tProfileEntry = record
    Name : string;  //simple profile name to rember what entry is
    Device : byte;  //0 for telnet; 1 for serial
   // For Internet Use
    HostName : string;
    SocketPort : byte;
  end;
  pArea = ^tArea;
  tArea = record
    x0,y0,
    x1,y1 : integer;
    cmdType  : word;
    cmd   : string;
  end;

Var
  //global Scroll back buffers
  LogingBuffer : TStringList;
  LogingStr    : String;
  LogingMode   : Byte;

  CurrentProfile : tProfileEntry;
  AreaList       : tList;

implementation

end.
