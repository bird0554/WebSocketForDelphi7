object frmServer: TfrmServer
  Left = 305
  Top = 194
  Width = 1305
  Height = 675
  Caption = 'frmServer'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object btnBroadcast: TButton
    Left = 128
    Top = 424
    Width = 201
    Height = 25
    Caption = 'btnBroadcast'
    TabOrder = 0
    OnClick = btnBroadcastClick
  end
  object mmoMessages: TMemo
    Left = 128
    Top = 24
    Width = 521
    Height = 369
    Lines.Strings = (
      'mmoMessages')
    ScrollBars = ssBoth
    TabOrder = 1
  end
  object edtBroadcastMsg: TEdit
    Left = 128
    Top = 400
    Width = 513
    Height = 21
    TabOrder = 2
    Text = 'edtBroadcastMsg'
  end
  object Edit1: TEdit
    Left = 128
    Top = 456
    Width = 457
    Height = 21
    TabOrder = 3
  end
  object Button1: TButton
    Left = 128
    Top = 480
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 4
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 728
    Top = 16
    Width = 75
    Height = 25
    Caption = 'btnTestJson'
    TabOrder = 5
    OnClick = Button2Click
  end
  object Memo1: TMemo
    Left = 744
    Top = 80
    Width = 385
    Height = 289
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssBoth
    TabOrder = 6
  end
end
