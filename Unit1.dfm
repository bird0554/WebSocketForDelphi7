object Form1: TForm1
  Left = 192
  Top = 130
  Width = 1305
  Height = 676
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 152
    Top = 80
    Width = 75
    Height = 25
    Caption = 'send'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 48
    Top = 80
    Width = 75
    Height = 25
    Caption = 'connect'
    TabOrder = 1
    OnClick = Button2Click
  end
  object IdTCPClient1: TIdTCPClient
    ASCIIFilter = True
    MaxLineAction = maException
    ReadTimeout = 0
    Host = '192.168.1.58'
    Port = 7001
    Left = 312
    Top = 208
  end
end
