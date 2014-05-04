unit Config;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, Main,
  StdCtrls, maskedit{, Mask};

type
  TfrmConfig = class(TForm)
    Button1: TButton;
    Button2: TButton;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    MaskEdit1: TMaskEdit;
    MaskEdit2: TMaskEdit;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    Label3: TLabel;
    Label4: TLabel;
    MaskEdit3: TMaskEdit;
    MaskEdit4: TMaskEdit;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure RadioButton1Click(Sender: TObject);
    procedure RadioButton2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmConfig: TfrmConfig;

implementation

{$R *.lfm}

procedure TfrmConfig.FormCreate(Sender: TObject);
begin
  MaskEdit1.Text := IntToStr(MF.VgaEmu1.chrCols);
  MaskEdit2.Text := IntToStr(MF.VgaEmu1.chrRows);
  MaskEdit3.Text := IntToStr(MF.VgaEmu1.Width);
  MaskEdit4.Text := IntToStr(MF.VgaEmu1.Height);
end;

procedure TfrmConfig.Button1Click(Sender: TObject);
var
  col, row : integer;
begin
  if RadioButton1.Checked then begin
    col := StrToInt(MaskEdit1.Text);
    row := StrToInt(MaskEdit2.Text);
    MF.VgaEmu1.setChrDim(col,row);
  end else begin
    col := StrToInt(MaskEdit3.Text);
    row := StrToInt(MaskEdit4.Text);
    MF.VgaEmu1.setResolution(col,row);
  end;
end;

procedure TfrmConfig.RadioButton1Click(Sender: TObject);
begin
  RadioButton1.Checked := true;
  RadioButton2.Checked := false;
end;

procedure TfrmConfig.RadioButton2Click(Sender: TObject);
begin
  RadioButton1.Checked := false;
  RadioButton2.Checked := true;
end;

end.
