unit uWebSocket;

interface

uses
  Classes, Forms, Windows, Contnrs, IdTCPServer, IdThreadMgr, IdThreadMgrDefault,
  SysUtils, Dialogs, CnSHA1, CnBase64, Types, EncdDecd, Math, StrUtils, uJson;

const
  key2 = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

type
  TWebSocketConnection = class;

  TWebSocketMessageEvent = procedure(AConnection: TWebSocketConnection; const AMessage: string) of object;

  TWebSocketConnectEvent = procedure(AConnection: TWebSocketConnection) of object;

  TWebSocketDisconnectEvent = procedure(AConnection: TWebSocketConnection) of object;

  TWebSocketRequest = class
  private
    FResource: string;
    FHost: string;
    FPragma: string;
    FCacheControl: string;
    FUserAgent: string;
    FOrigin: string;
    FProtocol: string;
    FKey: string;
    FClientRequest: Tstringlist;
    function getparam(Msg, str: string): string;
  public
    constructor Create(AConnection: TIdTCPServerConnection);
    destructor Destroy; override;
    property ClientRequest: Tstringlist read FClientRequest;
    property Resource: string read FResource;
    property Host: string read FHost;
    property Origin: string read FOrigin;
    property Protocol: string read FProtocol;
  end;

  TWebSocketConnection = class
  private
    FPeerThread: TIdPeerThread;
    FHandshakeRequest: TWebSocketRequest;
    FHandshakeResponseSent: Boolean;
    FOnMessageReceived: TWebSocketMessageEvent;
    FFrameLen: int64;
    MaskKEY: TByteDynArray;
    Position: Int64;
//    lst: tstringlist;
    FFIN: Boolean;
    FNewPackage: Boolean;
    Fopcode: Byte;
    FDataPosition: int64;
    PackageBytes: TByteDynArray;
    FPackageRes: TByteDynArray;
    FReadLen: Int64;
    function GetHandshakeCompleted: Boolean;
    function GetServerConnection: TIdTCPServerConnection;
    function GetPeerIP: string;
    procedure ParseCode;
    //������ͷ��
    procedure DealHeader;
    procedure DealPackageRes;
    function AppendBytes(const ABytes, BBytes: TByteDynArray): TByteDynArray; overload;
    function AppendBytes(const ABytes: TByteDynArray; s: string): TByteDynArray; overload;
    function DeleteBytes(const ABytes: TByteDynArray; _cnt: Integer): TByteDynArray;
    function Build_WebSocketBytes(SourceData: TByteDynArray; opcode: Byte = $01): TByteDynArray;
    function GetPeerPort: string;
    function GetServerIP: string;
    function GetServerPort: string;
    procedure setFrameLen(const Value: int64);
  protected
    procedure Handshake;
    property PeerThread: TIdPeerThread read FPeerThread write FPeerThread;
    property ServerConnection: TIdTCPServerConnection read GetServerConnection;
    property HandshakeCompleted: Boolean read GetHandshakeCompleted;
    property HandshakeResponseSent: Boolean read FHandshakeResponseSent write FHandshakeResponseSent;
  public
    constructor Create(APeerThread: TIdPeerThread);
    //�����ӵ���������
    property HandshakeRequest: TWebSocketRequest read FHandshakeRequest write FHandshakeRequest;
    //�������ݣ�
    function SendMessage(msg: string): Boolean;
    //SHA1���ܣ�
    function KeytoAccept(key: string): string;
    //�������ݰ���
    function ParsePackage(var _inbytes: TByteDynArray): TByteDynArray;
    //���������Ϣ��
    procedure DealMessage;
    property OnMessageReceived: TWebSocketMessageEvent read FOnMessageReceived write FOnMessageReceived;
    //�ͻ���IP��
    property PeerIP: string read GetPeerIP;
    //�ͻ���port��
    property PeerPort: string read GetPeerPort;
    property ServerIP: string read GetServerIP;
    property ServerPort: string read GetServerPort;
    //��ǰ֡���ݳ��ȣ�
    property FrameLen: int64 read FFrameLen write setFrameLen;
    property ReadLen: Int64 read FReadLen write FReadLen;
    //package���������ݿ�ʼ��λ�ã�
    property DataPosition: Int64 read FDataPosition write FDataPosition;
    //�Ƿ�Ϊ���һ֡��
    property FIN: Boolean read FFIN write FFIN;
    //����������ݣ�
    property PackageRes: TByteDynArray read FPackageRes write FPackageRes;
    //��Ϣ���ʶ��
    property opcode: Byte read Fopcode write Fopcode;
    //��ʼ������
    property NewPackage: Boolean read FNewPackage write FNewPackage;
  end;

  TWebSocketServer = class
  private
    FDefaultPort: Integer;
    FTCPServer: TIdTCPServer;
    FThreadManager: TIdThreadMgr;
    FConnections: TObjectList;
    FOnConnect: TWebSocketConnectEvent;
    FOnMessageReceived: TWebSocketMessageEvent;
    FOnDisconnect: TWebSocketDisconnectEvent;
    function GetTCPServer: TIdTCPServer;
    function GetThreadManager: TIdThreadMgr;
    function GetConnections: TObjectList;
    function GetActive: Boolean;
    procedure SetActive(const Value: Boolean);
  protected
    procedure TCPServerConnect(AThread: TIdPeerThread);
    procedure TCPServerDisconnect(AThread: TIdPeerThread);
    procedure TCPServerExecute(AThread: TIdPeerThread);
    procedure MessageReceived(AConnection: TWebSocketConnection; const AMessage: string);
    property DefaultPort: Integer read FDefaultPort write FDefaultPort;
    property TCPServer: TIdTCPServer read GetTCPServer;
    property ThreadManager: TIdThreadMgr read GetThreadManager;
    property Connections: TObjectList read GetConnections;
  public
    constructor Create(ADefaultPort: Integer);
    destructor Destroy; override;
    procedure Broadcast(AMessage: string);
    property Active: Boolean read GetActive write SetActive;
    property OnConnect: TWebSocketConnectEvent read FOnConnect write FOnConnect;
    property OnMessageReceived: TWebSocketMessageEvent read FOnMessageReceived write FOnMessageReceived;
    property OnDisconnect: TWebSocketDisconnectEvent read FOnDisconnect write FOnDisconnect;
  end;


implementation

uses
  Masks;

{ TWebSocketServer }

procedure TWebSocketServer.MessageReceived(AConnection: TWebSocketConnection; const AMessage: string);
begin
  if Assigned(OnMessageReceived) and (AConnection.HandshakeCompleted) then
  begin
    OnMessageReceived(AConnection, AMessage);
  end;
end;

procedure TWebSocketServer.Broadcast(AMessage: string);
var
  Connection: TWebSocketConnection;
  i: Integer;
begin
  for i := 0 to Self.Connections.Count - 1 do
  begin
    Connection := TWebSocketConnection(Self.Connections.items[i]);
    if Connection.HandshakeCompleted then
    begin
      Connection.SendMessage(AMessage);
    end;
  end;
end;

constructor TWebSocketServer.Create(ADefaultPort: Integer);
begin
  DefaultPort := ADefaultPort;
end;

destructor TWebSocketServer.Destroy;
begin
  // Cleanup
  TCPServer.Active := False;
  TCPServer.Free;
  ThreadManager.Free;
  inherited;
end;

function TWebSocketServer.GetActive: Boolean;
begin
  Result := TCPServer.Active;
end;

function TWebSocketServer.GetConnections: TObjectList;
begin
  if not Assigned(FConnections) then
  begin
    FConnections := TObjectList.Create(False);
  end;
  Result := FConnections;
end;

function TWebSocketServer.GetTCPServer: TIdTCPServer;
begin
  if not Assigned(FTCPServer) then
  begin
    FTCPServer := TIdTCPServer.Create(nil);
    FTCPServer.ThreadMgr := ThreadManager;
    FTCPServer.DefaultPort := DefaultPort;
    // Events
    FTCPServer.OnConnect := TCPServerConnect;
    FTCPServer.OnDisconnect := TCPServerDisconnect;
    FTCPServer.OnExecute := TCPServerExecute;
  end;

  Result := FTCPServer;
end;

function TWebSocketServer.GetThreadManager: TIdThreadMgr;
begin
  if not Assigned(FThreadManager) then
  begin
    FThreadManager := TIdThreadMgrDefault.Create(nil);
  end;
  Result := FThreadManager;
end;

procedure TWebSocketServer.SetActive(const Value: Boolean);
begin
  TCPServer.Active := Value;
end;

procedure TWebSocketServer.TCPServerConnect(AThread: TIdPeerThread);
var
  Connection: TWebSocketConnection;
begin
  Connection := TWebSocketConnection.Create(AThread);
  Connection.OnMessageReceived := MessageReceived;
  Connections.Add(Connection);
  AThread.Data := Connection;
  if Assigned(OnConnect) then
  begin
    OnConnect(Connection);
  end;
end;

procedure TWebSocketServer.TCPServerDisconnect(AThread: TIdPeerThread);
var
  Connection: TWebSocketConnection;
begin
  Connection := AThread.Data as TWebSocketConnection;
  if Assigned(OnDisconnect) then
  begin
    OnDisconnect(Connection);
  end;
  AThread.Data := nil;
  Connections.Remove(Connection);
  Connection.Free;
end;

procedure TWebSocketServer.TCPServerExecute(AThread: TIdPeerThread);
var
  Client: TWebSocketConnection;
begin
  Client := AThread.Data as TWebSocketConnection;
  if Client <> nil then
    Client.DealMessage;
end;

{ TWebSocketConnection }

constructor TWebSocketConnection.Create(APeerThread: TIdPeerThread);
begin
  HandshakeResponseSent := False;
  PeerThread := APeerThread;
  self.FFrameLen := 0;
  Self.ReadLen := 0;
  Self.Position := 0;
//  lst := TStringList.Create;
  FFIN := True;
  SetLength(self.PackageBytes, 0);
  SetLength(self.FPackageRes, 0);
  self.NewPackage := True;
end;

function TWebSocketConnection.AppendBytes(const ABytes, BBytes: TByteDynArray): TByteDynArray;
var
  BLen, OldLen: Integer;
begin
  BLen := Length(BBytes);
  if BLen <= 0 then
    Exit;
  OldLen := Length(ABytes);
  SetLength(Result, OldLen + BLen);

  if OldLen > 0 then
    Move(ABytes[0], Result[0], OldLen);
  Move(BBytes[0], Result[OldLen], BLen);
end;

function TWebSocketConnection.GetServerConnection: TIdTCPServerConnection;
begin
  Result := PeerThread.Connection;
end;

function TWebSocketConnection.GetHandshakeCompleted: Boolean;
begin
  Result := HandshakeResponseSent;
end;

function TWebSocketConnection.GetPeerIP: string;
begin
  Result := ServerConnection.Socket.Binding.PeerIP;
end;

procedure TWebSocketConnection.Handshake;
var
  s: string;
begin
  try
    HandshakeRequest := TWebSocketRequest.Create(ServerConnection);
    s := 'HTTP/1.1 101 Switching Protocols' + chr(13) + chr(10);
    s := s + 'Upgrade: websocket' + chr(13) + chr(10);
    s := s + 'Connection: Upgrade' + chr(13) + chr(10);
    s := s + 'Sec-WebSocket-Accept: ' + KeytoAccept(HandshakeRequest.FKey) + chr(13) + chr(10);
//    s := s + 'Sec-WebSocket-Extensions: permessage-deflate' + chr(10);
    s := s + 'Date: ' + datetimetostr(Now) + chr(13) + char(10);
    s := s + 'Server: BoomLinkSever/1.0 websockets/8.1' + chr(13) + chr(10) + chr(13) + chr(10);
    ServerConnection.Write(s);
    HandshakeResponseSent := True;
  except
    on E: Exception do
    begin
      ServerConnection.Disconnect;
    end;
  end;
end;


function TWebSocketConnection.Build_WebSocketBytes(SourceData: TByteDynArray; opcode: Byte = $01): TByteDynArray;
var
  Len: Int64;
  slen: string;
begin
  //1. ȡ�����ݳ���
  Len := Length(SourceData);
  if Len = 0 then
    Exit;

  if opcode > $0F then
    Exit; //opcode ����Чֵ�� 0 - F

  //2. ������һ������opcode ���ֽ�
  if Len <= 125 then
  begin
    SetLength(Result, Len + 2);
    Result[0] := $80 + opcode; //   $81;  //129  ��ʾ�����һ֡
    Result[1] := Len; //ʵ�ʵ����ݳ���
    move(SourceData[0], Result[2], Len);
  end
  else if (Len > 125) and (Len <= 65535) then
  begin
    SetLength(Result, Len + 4);
    Result[0] := $80 + opcode; // $81;  //129  ��ʾ�����һ֡
    Result[1] := 126; //���������ֽڵ����ݳ���
    slen := IntToHex(Len, 4);
    HextoBin(pchar(slen), @Result[2], 2);
    move(SourceData[0], Result[4], Len);
  end
  else if Len > 65535 then
  begin
    SetLength(Result, Len + 10);
    Result[0] := $80 + opcode; // $81;  //129  ��ʾ�����һ֡
    Result[1] := 127; //�����˸��ֽڵ����ݳ���
    slen := IntToHex(Len, 16);
    HextoBin(pchar(slen), @Result[2], 8);
    move(SourceData[0], Result[10], Len);
  end;
end;

function TWebSocketConnection.SendMessage(msg: string): Boolean;
var
  B: TByteDynArray;
  temp: UTF8String;
  len: Integer;
begin
  Result := False;
  temp := UTF8Encode(msg);
  len := Length(temp);
  SetLength(B, len);
  Move(temp[1], B[0], len);
  B := Build_WebSocketBytes(B);
  PeerThread.Connection.WriteBuffer(B[0], Length(B));
  Result := True;
end;

function TWebSocketConnection.KeytoAccept(key: string): string;
var
  stream: TMemoryStream;
  td: TSHA1Digest;
begin
  stream := TMemoryStream.Create;
  try
    td := SHA1StringA(key + key2);
    stream.Write(td, 20);
    stream.Position := 0;
    Base64Encode(stream, Result);
  finally
    stream.free;
  end;
end;

function TWebSocketConnection.GetPeerPort: string;
begin
  Result := IntToStr(ServerConnection.Socket.Binding.PeerPort);
end;



function TWebSocketConnection.GetServerIP: string;
begin
  result := ServerConnection.Socket.Binding.IP;
end;

function TWebSocketConnection.GetServerPort: string;
begin
  result := inttostr(ServerConnection.Socket.Binding.Port);
end;

procedure TWebSocketConnection.setFrameLen(const Value: int64);
begin
  FFrameLen := Value;
end;

function TWebSocketConnection.ParsePackage(var _inbytes: TByteDynArray): TByteDynArray;
begin
   //����ǽ����µ���Ϣ��
  if self.NewPackage then
    self.DealHeader
  else
    self.DataPosition := 0;
//  lst.Add('framelen:' + IntToStr(self.FrameLen) + ' packagelen:' + inttostr(Length(self.PackageBytes)) + ' reslen:' + inttostr(Length(self.PackageRes)));
//  lst.SaveToFile('c:\ccc.txt');
  Self.ParseCode;
  if Length(self.PackageBytes) > 0 then
    self.ParsePackage(self.PackageBytes);
end;

procedure TWebSocketConnection.DealMessage;
var
  s: string;
begin
  //���֣�
  if not HandshakeCompleted then
  begin
    Handshake;
  end
  else
  //���ݴ��䣺
  begin
    s := PeerThread.Connection.CurrentReadBuffer;
    if Length(s) = 0 then
      Exit;
    PackageBytes := AppendBytes(PackageBytes, s);
    Self.ParsePackage(PackageBytes);
  end;
end;

function TWebSocketConnection.AppendBytes(const ABytes: TByteDynArray; s: string): TByteDynArray;
var
  BLen, OldLen: Integer;
begin
  BLen := Length(s);
  if BLen <= 0 then
    Exit;
  OldLen := Length(ABytes);
  SetLength(Result, OldLen + BLen);

  if OldLen > 0 then
    Move(ABytes[0], Result[0], OldLen);

  Move(s[1], Result[OldLen], BLen);
end;

procedure TWebSocketConnection.DealHeader;
var
  B: Byte;
  Payload_Length: Int64; //ʵ�ʵ����ݳ���
  i: Integer;
  M, Payload_Len: Byte;
begin
  Self.Position := 0;
  //ֻ�жϵ�һ���ֽ�
  if Length(self.PackageBytes) <= 3 then
    raise Exception.Create('Err02,���ݳ��Ȳ���Ϊ0');

  //1. �����ж��Ƿ��������ʽ x000xxxx ����
  B := PackageBytes[0];
  B := B and $70;
  if B <> 0 then
    raise Exception.Create('Err03,�ͻ������ݸ�ʽ����ȷ');

  //2. ȡ��FINλ
  B := PackageBytes[0];
  B := B shr 7;
  self.FIN := B = 1;

  //3. ȡ��opcode
  B := PackageBytes[0] and $0F;
  //����ǳ���֡����ԭ����opccode��
  if B = 0 then
    self.opcode := self.opcode
  else
    self.opcode := B;

  //4:�ͻ������ݱ���������λ��
  B := PackageBytes[1];
  M := B shr 7;
  if M <> 1 then //˵���ӿͻ��˷���������û�м��ܣ��ǲ���ȷ��
    raise Exception.Create('Err05,�ͻ������ݸ�ʽ����ȷ(û������λ)');

  //5. ���ݳ���
  Payload_Len := B - $80;
  SetLength(MaskKEY, 4);
  case Payload_Len of
    126:
      begin
        //��ȡ���ݳ���
        Payload_Length := 0;
        Payload_Length := ((Payload_Length or PackageBytes[2]) shl 8) or PackageBytes[3];
        move(PackageBytes[4], MaskKEY[0], 4); //MaskKEY
        self.dataPosition := 8;
      end;
    127:
      begin
        //��ȡ���ݳ���
        Payload_Length := 0;
        for i := 2 to 8 do
          Payload_Length := (Payload_Length or PackageBytes[i]) shl 8;
        Payload_Length := Payload_Length or PackageBytes[9];
        move(PackageBytes[10], MaskKEY[0], 4);
        self.dataPosition := 14;
      end
  else //0-125
    Payload_Length := Payload_Len;
    move(PackageBytes[2], MaskKEY[0], 4);
    Self.dataPosition := 6;
  end;
  //��������
  self.FrameLen := self.FrameLen + Payload_Length;
  self.NewPackage := False;
end;

procedure TWebSocketConnection.ParseCode;
var
  outBytes: TByteDynArray;
  i: Integer;
begin
  //��ȡ��Ҫ��ȡ�������ݲ������һ֡��
  self.readlen := self.FrameLen - length(Self.PackageRes);
  self.readlen := Min(Length(Self.PackageBytes) - self.DataPosition, self.readlen);
  SetLength(outBytes, self.readlen);
  case self.opcode of
    1: //�ı�֡��Ϣ
      begin
        for i := 0 to self.ReadLen - 1 do
        begin
          outBytes[i] := self.PackageBytes[i + self.DataPosition] xor self.MaskKEY[self.Position mod 4];
          self.Position := self.Position + 1;
        end;
        self.PackageRes := AppendBytes(self.PackageRes, outBytes);
        //ȥ������������ݣ�
        Self.PackageBytes := DeleteBytes(self.PackageBytes, Self.ReadLen + self.DataPosition);
      end;
    2: //����Ϣ
      begin
      end;
    9: //һ��ping
      begin

      end;
    $A:
      begin

      end;
  else
    //���������һ�������˲���Ԥ�ڴ��󣬱���ͻ��˶Ͽ�����ʱ�ᷢ��һ��8�ֽڵ���Ϣ�ȣ�
    begin
//      ???
      self.FrameLen := Length(self.PackageRes);
      SetLength(self.PackageBytes, 0);
    end;
  end;

  if Self.FrameLen = Length(self.PackageRes) then
  begin
    Self.NewPackage := True;
    //������յ������ݣ�
    Self.DealPackageRes;
  end
  else
    self.NewPackage := False;
end;

function TWebSocketConnection.DeleteBytes(const ABytes: TByteDynArray;
  _cnt: Integer): TByteDynArray;
var
  Len: Integer;
begin
  if _cnt <= 0 then
    Exit;
  Len := Length(ABytes) - _cnt;
  if len < 0 then
    Exit;
  SetLength(Result, len);
  if Len <> 0 then
    Move(ABytes[_cnt], Result[0], len);
end;

procedure TWebSocketConnection.DealPackageRes;
var
  str: string;
begin
  //����������ݺ���¼���
  SetLength(str, Length(self.FPackageRes));
  Move(self.FPackageRes[0], str[1], Length(self.FPackageRes));
  str := UTF8Decode(str);
//    lst.Add('len:' + inttostr(Length(Result)));
//    lst.SaveToFile('c:\ccc.txt');
  //��������һ֡��
  if self.FIN then
  begin
    self.SendMessage(str);
    self.FrameLen := 0;
    SetLength(self.FPackageRes, 0);
  end;
end;

{ TWebSocketRequest }
constructor TWebSocketRequest.Create(AConnection: TIdTCPServerConnection);
var
  Msg: string;
  i: Integer;
begin
  FClientRequest := TStringList.Create;
  FClientRequest.Text := AConnection.CurrentReadBuffer;
  for i := 0 to FClientRequest.Count - 1 do
  begin
    Msg := FClientRequest.Strings[i];
    if MatchesMask(Msg, 'GET /* HTTP/1.1') then
      FResource := Copy(Msg, 6, Length(Msg) - 14);
    FHost := getparam(Msg, 'Host: *');
    FPragma := getparam(Msg, 'Pragma: *');
    FCacheControl := getparam(Msg, 'Cache-Control: *');
    FUserAgent := getparam(Msg, 'User-Agent: *');
    FOrigin := getparam(Msg, 'Origin: *');
    FKey := getparam(Msg, 'Sec-WebSocket-Key: *');
  end;
end;

function TWebSocketRequest.getparam(Msg, str: string): string;
begin
  if MatchesMask(Msg, str) then
    Result := Copy(Msg, Length(str), Length(Msg) - Length(str) + 1);
end;

destructor TWebSocketRequest.Destroy;
begin
  if Assigned(Self.FClientRequest) then
    self.FClientRequest.Free;
  inherited;
end;

end.

