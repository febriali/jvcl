{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: JvControlPanel.PAS, released on 2001-02-28.

The Initial Developer of the Original Code is Sébastien Buysse [sbuysse@buypin.com]
Portions created by Sébastien Buysse are Copyright (C) 2001 Sébastien Buysse.
All Rights Reserved.

Contributor(s): Michael Beck [mbeck@bigfoot.com].

Last Modified: 2000-02-28

You may retrieve the latest version of this file at the Project JEDI's JVCL home page,
located at http://jvcl.sourceforge.net

Known Issues:
-----------------------------------------------------------------------------}
{$A+,B-,C+,D+,E-,F-,G+,H+,I+,J+,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$I JEDI.INC}

unit JvControlPanel;

{$OBJEXPORTALL On}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, Menus, Cpl, ShellApi,
  JvTypes, JvButton, JvDirectories, JvFunctions;

type
  TJvControlPanel = class(TJvButton)
  private
    FPopup: TPopupMenu;
    FDirs: TJvDirectories;
    FOnUrl: TOnLinkClick;
    FLeft: Integer;
    FTop: Integer;
    procedure AddToPopup(Item: TMenuItem; Path: string);
    procedure UrlClick(Sender: TObject);
  public
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Click; override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property OnLinkClick: TOnLinkClick read FOnUrl write FOnUrl;
  end;

implementation

resourcestring
  RC_CplAddress = 'CPlApplet';

  {*******************************************************}

function GetNameCpl(Path: string): string;
var
  h: THandle;
  CplApplet: TCplApplet;
  NewCplInfo: TNewCplInfo;
begin
  // (rom) simplified/fixed
  Result := '';
  h := LoadLibrary(PChar(Path));
  if h <> 0 then
  begin
    @CplApplet := GetProcAddress(h, PChar(RC_CplAddress));
    if @CplApplet <> nil then
    begin
      NewCplInfo.szName[0] := #0;
      CplApplet(0, CPL_NEWINQUIRE, 0, Longint(@NewCplInfo));
      Result := NewCplInfo.szName;
    end;
    FreeLibrary(h);
  end;
end;

function GetNameCplW2k(const APath, AName: string; Strings: TStrings): Boolean;
var
  hLib: HMODULE; // Library Handle to *.cpl file
  hIco: HICON;
  CplCall: TCPLApplet; // Pointer to CPlApplet() function
  i: LongInt;
  tmpCount, Count: LongInt;
  CPLInfo: TCPLInfo;
  InfoW: TNewCPLInfoW;
  InfoA: TNewCPLInfoA;
  S: WideString;
begin
  Result := False;
  hLib := SafeLoadLibrary(APath + AName);
  if hLib = 0 then
    Exit;
  tmpCount := Strings.Count;
  try
    @CplCall := GetProcAddress(hLib, PChar(RC_CplAddress));
    if @CplCall = nil then
      Exit;

    CplCall(GetFocus, CPL_INIT, 0, 0); // Init the *.cpl file
    try
      Count := CplCall(GetFocus, CPL_GETCOUNT, 0, 0);
      for i := 0 to Count - 1 do
      begin
        FillChar(InfoW, sizeof(InfoW), 0);
        FillChar(InfoA, sizeof(InfoA), 0);
        FillChar(CPLInfo, sizeof(CPLInfo), 0);
        hIco := 0;
        S := '';
        CplCall(GetFocus, CPL_NEWINQUIRE, i, LongInt(@InfoW));
        if InfoW.dwSize = sizeof(InfoW) then
        begin
          if i > 0 then
            hIco := InfoW.hIcon;
          S := WideString(InfoW.szName);
        end
        else
        begin
          if InfoW.dwSize = sizeof(InfoA) then
          begin
            Move(InfoW, InfoA, sizeof(InfoA));
            if i > 0 then
              hIco := InfoA.hIcon;
            S := string(InfoA.szName);
          end
          else
          begin
            CplCall(GetFocus, CPL_INQUIRE, i, LongInt(@CPLInfo));
            LoadStringA(hLib, CPLInfo.idName, InfoA.szName, 32);
            if i > 0 then
              hIco := LoadIcon(hLib, MakeIntResource(@CPLInfo.idIcon));
            S := string(InfoA.szName);
          end;
        end;
        if S <> '' then
          Strings.AddObject(S + '%' + AName, TObject(hIco));
      end;
      Result := tmpCount < Strings.Count;
    finally
      CplCall(GetFocus, CPL_EXIT, 0, 0);
    end;
  finally
    FreeLibrary(hLib);
  end;
end;

{*******************************************************}


procedure TJvControlPanel.AddToPopup(Item: TMenuItem; Path: string);
var
  t: TSearchRec;
  res: Integer;
  it: TMenuItem;
  ts: TStringList;
  w: Word;
  b: TBitmap;
begin
  ts := TStringList.Create;
  res := FindFirst(Path + '*.cpl', faAnyFile, t);
  while res = 0 do
  begin
    if (t.Name <> '.') and (t.Name <> '..') then
    begin
      if not GetNameCplW2k(Path, t.Name, ts) then
        ts.Add(ChangeFileExt(t.Name, '') + '%' + t.Name);
    end;
    res := FindNext(t);
  end;
  FindClose(t);
  ts.Sort;

  for res := 0 to ts.Count - 1 do
  begin
    it := TMenuItem.Create(Self);
    it.Caption := Copy(ts[res], 1, Pos('%', ts[res]) - 1);
    it.OnClick := UrlClick;
    it.Hint := Path + Copy(ts[res], Pos('%', ts[res]) + 1, Length(ts[res]));
    w := 0;
    if ts.Objects[res] <> nil then
      b := IconToBitmap2(integer(ts.Objects[res]), 16, clWhite)
    else
      b := IconToBitmap2(ExtractAssociatedIcon(Application.Handle, PChar(it.Hint), w), 16, clWhite);
    it.Bitmap.Assign(b);
    b.Free;
    item.Add(it);
    Application.ProcessMessages;
  end;
  ts.Free;
end;

{*******************************************************}

procedure TJvControlPanel.Click;
begin
  inherited;
  FPopup.Popup(FLeft + Left, FTop + Top + Height + 20);
end;

{*******************************************************}

constructor TJvControlPanel.Create(AOwner: TComponent);
begin
  inherited;
  FLeft := GetParentForm(TControl(AOwner)).Left;
  FTop := GetParentForm(TControl(AOwner)).Top;
  FDirs := TJvDirectories.Create(Self);
  FPopup := TPopupMenu.Create(Self);
end;

{*******************************************************}

procedure TJvControlPanel.CreateParams(var Params: TCreateParams);
var
  st: string;
begin
  inherited;
  if not (csDesigning in ComponentState) then
  begin
    while FPopup.Items.Count > 0 do
      FPopup.Items.Delete(0);
    st := FDirs.SystemDirectory;
    if st[Length(st)] <> '\' then
      st := st + '\';
    AddToPopup(TMenuItem(FPopup.Items), st);
    FTop := (Owner as TForm).Top;
    FLeft := (Owner as TForm).Left;
    PopupMenu := FPopup;
  end;
end;

{*******************************************************}

destructor TJvControlPanel.Destroy;
var
  i: Integer;
begin
  FDirs.Free;
  for i := 0 to FPopup.Items.Count - 1 do
    Fpopup.Items[i].Bitmap.FreeImage;
  FPopup.Free;
  inherited;
end;

{*******************************************************}

procedure TJvControlPanel.UrlClick(Sender: TObject);
begin
  if Assigned(FOnUrl) then
    FOnUrl(Self, (Sender as TMenuItem).Hint);
end;

end.
