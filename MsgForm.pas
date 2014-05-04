unit MsgForm;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls;

type
  TForm2 = class(TForm)
    Label1: TLabel;
    Timer1: TTimer;
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormHide(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.lfm}

procedure TForm2.FormShow(Sender: TObject);
begin
    Label1.Update;
    Timer1.Enabled := true;
end;

procedure TForm2.Timer1Timer(Sender: TObject);
begin
  Hide;
end;

procedure TForm2.FormHide(Sender: TObject);
begin
  Timer1.Enabled := false;
end;

end.
