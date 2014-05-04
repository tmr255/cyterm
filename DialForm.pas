unit DialForm;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TfrmDial = class(TForm)
    HostEdit: TEdit;
    Label1: TLabel;
    Button1: TButton;
    Button5: TButton;
    Button4: TButton;
    PortEdit: TEdit;
    Label2: TLabel;
    Button2: TButton;
    OpenDialog1: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmDial: TfrmDial;

implementation
uses IceAnsi;
{$R *.lfm}
procedure TfrmDial.FormCreate(Sender: TObject);
begin
  HostEdit.text := 'dh.darktech.org';
  PortEdit.text := '23';
end;

procedure TfrmDial.Button5Click(Sender: TObject);
var
 X : integer;
 f: file;
 buf : AnsiString;
begin
if OpenDialog1.Execute then
   begin
     AssignFile(F,OpenDialog1.Filename);
     reset(f,1);
     setlength(buf,Filesize(F));
     blockread(f,buf[1],filesize(f),X);
     closefile(f);
     For X :=  1 to length(buf) do
       Ice_Display_ANSI(buf[x]);
   end;
end;

end.
