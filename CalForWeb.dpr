program CalForWeb;

uses
  Forms,
  uMain in 'uMain.pas' {frmServer},
  uWebSocket in 'uWebSocket.pas',
  CnBase64 in 'CnBase64.pas',
  CnSHA1 in 'CnSHA1.pas',
  uJson in 'uJson.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmServer, frmServer);
  Application.Run;
end.
