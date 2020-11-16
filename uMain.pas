unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, uWebSocket, CnBase64, CnSHA1, uJson, IdBaseComponent,
  IdComponent, IdTCPServer;

type
  TfrmServer = class(TForm)
    btnBroadcast: TButton;
    mmoMessages: TMemo;
    edtBroadcastMsg: TEdit;
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBroadcastClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
    FWebSocketServer: TWebSocketServer;
    function GetWebSocketServer: TWebSocketServer;
    procedure MessageReceived(AConnection: TWebSocketConnection; const AMessage: string);
    procedure NewConnection(AConnection: TWebSocketConnection);
    procedure ConnectionClosed(AConnection: TWebSocketConnection);
    property WebSocketServer: TWebSocketServer read GetWebSocketServer;
  protected
    procedure Broadcast(AMessage: string);
  public
    { Public declarations }
  end;

var
  frmServer: TfrmServer;

implementation

{$R *.dfm}

{ TfrmServer }
procedure TfrmServer.Broadcast(AMessage: string);
begin
  // Preconditions
  Assert(WebSocketServer.Active);
  // Send AMessage to all clients
  if AMessage <> '' then
  begin
    WebSocketServer.Broadcast(AMessage);
    mmoMessages.Lines.Add('Broadcast: ' + AMessage);
  end;
end;

procedure TfrmServer.ConnectionClosed(AConnection: TWebSocketConnection);
begin
//  Broadcast(AConnection.PeerIP + ' disconnected!');
end;

function TfrmServer.GetWebSocketServer: TWebSocketServer;
begin
  if not Assigned(FWebSocketServer) then
  begin
    FWebSocketServer := TWebSocketServer.Create(7000);
  end;
  Result := FWebSocketServer;
end;

procedure TfrmServer.MessageReceived(AConnection: TWebSocketConnection;
  const AMessage: string);
begin
  mmoMessages.Lines.Add(AConnection.HandshakeRequest.Host + '(' + AConnection.PeerIP + ':' + AConnection.PeerPort + ')' + ':' + AMessage);
//  Broadcast(AConnection.PeerIP + ': ' + AMessage);
end;

procedure TfrmServer.NewConnection(AConnection: TWebSocketConnection);
begin
  mmoMessages.Lines.Add('host:' + aconnection.ServerIP + ',' + aconnection.ServerPort + '(' + AConnection.PeerIP + ':' + AConnection.PeerPort + ')');
//  Broadcast(AConnection.PeerIP + ' connected!');
end;

procedure TfrmServer.FormCreate(Sender: TObject);
begin
  with WebSocketServer do
  begin
    // Assign events
    OnMessageReceived := MessageReceived;
    OnConnect := NewConnection;
    OnDisconnect := ConnectionClosed;
    // Start listening for connections
    Active := True;
  end;
end;

procedure TfrmServer.FormDestroy(Sender: TObject);
begin
  FWebSocketServer.Free;
end;

procedure TfrmServer.btnBroadcastClick(Sender: TObject);
begin
  Broadcast(edtBroadcastMsg.Text);
  edtBroadcastMsg.Text := '';
end;

procedure TfrmServer.Button1Click(Sender: TObject);
var
  key1, key2, out1: string;
  stream: TMemoryStream;
  td: TSHA1Digest;
  wc: TWebSocketConnection;
begin
  stream := TMemoryStream.Create;
  wc := TWebSocketConnection.Create(nil);
  try
    key1 := Edit1.Text;
    key2 := '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
    Edit1.Text := SHA1Print(SHA1StringA(key1 + key2));
    td := SHA1StringA(key1 + key2);
    stream.Write(td, 20);
    stream.Position := 0;
    Base64Encode(stream, out1);
    Edit1.Text := out1;
    ShowMessage(wc.KeytoAccept(key1));
  finally
    stream.free;
  end;
end;

procedure TfrmServer.Button2Click(Sender: TObject);
var
  js, js1: TJsonSocket;
  i: Integer;
begin
  js := TJsonSocket.Create('');
  js1 := TJsonSocket.Create('{"name":"Henri Gourvest",/*thisisacomment*/"vip":true,"telephones":["000000000","111111111111"],"age":33,"size":1.83,' +
    '"adresses":[{"adress":"blabla","city":"Metz","pc":57000},{"adress":"blabla","city":"Nantes","pc":44000}]}');
  try
    js.AddPro('name', 'aaa');
    js.AddPro('name1', 'bbb');
    js.AddPro('name', 'ccc');
    ShowMessage(js.GetPro('name1') + ' ' + js.GetPro('name'));
    for i := 0 to js1.GetA('adresses').Length - 1 do
      ShowMessage(js1.GetA('adresses').O[i].AsString);
  finally
    js1.Free;
    js.Free;
  end;
end;



end.

