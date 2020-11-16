unit uJson;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, superobject, StdCtrls;
type
  TJsonSocket = class
  private
    FISO: ISuperObject;
  public
    constructor Create(_jsonstr: WideString);
    destructor Destroy; override;
    //json转换的接口：
    property ISO: ISuperObject read FISO write FISO;
    function AsString: string;
    //json添加属性：
    function AddPro(_pro, _val: string): Boolean;
    //得到指定的接口：
    function GetPro(_pro: string): string;
    //得到数组：
    function GetA(_pro: string): TSuperArray;
  end;

  TJsonCal = class(TJsonSocket)
  private
    FAction: string;
  public
    constructor Create(_jsonstr: WideString); overload;
    property Action: string read FAction write FAction;
  end;
implementation

{ TSocketJson }

constructor TJsonSocket.Create(_jsonstr: WideString);
begin
  if _jsonstr <> '' then
    Self.FISO := SO(_jsonstr)
  else
    Self.FISO := SO();
end;

destructor TJsonSocket.Destroy;
begin

  inherited;
end;

function TJsonSocket.AsString: string;
begin
  Result := Self.FISO.AsString;
end;

function TJsonSocket.AddPro(_pro, _val: string): Boolean;
begin
  Result := False;
  if Assigned(Self.FISO) then
  begin
    self.FISO.S[_pro] := _val;
  end;
  Result := True;
end;

function TJsonSocket.GetPro(_pro: string): string;
begin
  Result := '';
  if Assigned(Self.FISO) then
  begin
    Result := self.FISO.S[_pro];
  end;
end;


{ TCalJson }

constructor TJsonCal.Create(_jsonstr: WideString);
begin
  inherited Create(_jsonstr);
  if _jsonstr <> '' then
  begin
    FAction := ISO.S['action'];
  end;
end;




function TJsonSocket.GetA(_pro: string): TSuperArray;
begin
  Result := nil;
  if Assigned(Self.FISO) then
  begin
    Result := self.FISO.A[_pro];
  end;
end;

end.

