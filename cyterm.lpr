program cyterm;

{$MODE Delphi}

uses
  Forms, Interfaces,
  main in 'main.pas' {MF},
  DefFont in 'DefFont.pas',
  globals in 'globals.pas',
  DialForm in 'DialForm.pas' {frmDial},
  MsgForm in 'MsgForm.pas' {Form2},
  IceAnsi in 'iceansi.pas',
  RipParse in 'RipParse.pas',
  relay in 'relay.pas',
  VgaEmu in 'VgaEmu.pas',
  Config in 'Config.pas' {frmConfig},
  Help in 'Help.pas' {frmHelp},
  VgaGlobal in 'VgaGlobal.pas';

begin
  Application.Initialize;
  Application.Title := 'cyterm';
  Application.CreateForm(TMF, MF);
  Application.CreateForm(TfrmDial, frmDial);
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TfrmConfig, frmConfig);
  Application.CreateForm(TfrmHelp, frmHelp);
  Application.Run;
end.
