{------------------------------------------------------------------------------}
{                                                                              }
{ EkwoTECH Lookup-Edit                                                         }
{ The Original Code is ET_LookupEdit.pas.                                      }
{                                                                              }
{------------------------------------------------------------------------------}
{                                                                              }
{ Unit owner:    EkwoTECH GmbH Friedrichshafen                                 }
{ Created:       March 29, 2020                                                }
{ Last modified: April 04, 2020                                                }
{                                                                              }
{------------------------------------------------------------------------------}
unit ET_LookupEdit;

interface

uses stdctrls, extctrls, controls, classes, graphics, windows, SysUtils, Forms,
  uHelpFunctions,
  messages;

{
done:
- Control parent = TForm, which limits the Panelsize to TForm dimensions

2do:
- Idee: auch einen Index anzeigen, etwa, nach dem alternativ gesucht werden kann
- Groesse des Img nur so gross wie die Box, darin scrollen # 2020-03-29
- von CustomEdit ableiten, um das <TAB>-Verhalten selbst zu definieren (z.B. Liste einklappen)
- Mousemove: nicht komplett neu zeichnen, sondern nur das vorher und jetzt selektierte!!
- !!!!! beim schnell hinterinander löschen, bricht kaputt
}
const
  SL_MAX      = 25; // max. Fundstellen (Höhe der "ComboBox")
  ITEM_HEIGHT = 17; // 2do: ppi?

type
{ Scrollbar, the moveable area is smaller than the full Scrollbar area, due to margin

            /    Margin                         Margin
            |               /                   a +---+  YMin
            |               |                   r |   |
            |               |                   g |   |
    Rect    |               |              /    i +---+  Y1
            |    Height     |    Height    |    n | + |  YGrab [Pixel]
            |      Mov      |      Bar     |      |   |
            |               |              \      +---+
            |               |                     |   |
            |               |                     |   |
            |               |                     |   |
            |               \                     +---+  YMax
            \    Margin
}
  TScrollbarMode = (scr_List, scr_ScrollBar);
  TET_Scrollbar = class
    Mode: TScrollbarMode;
// i) items
    ItemsAll: Word;
    ItemsShown: Word;
    YItem: Word;           // a.k.a   F_FirstPainted
// ii) pixel
    Rect: TRect;
    Margin: Byte;
    Y1: Word;
    YMin, YMax: Word;      // e.g. 5 and Height-5
    X: Word;               // Breite/X2 zurzeit nur durch die Pen.Width definiert
    YGrab: Word;           // Mouse.Y - Y1
    HeightMov: Word;       // movable range of Bar
    HeightBar: Word;       // Double ?
    HeightItem: Double;
  public
    procedure Init(r: TRect; iMargin: Byte; nItemsAll: Word; nItemsShown: Word);
    procedure set_Y1(nItem: Word); // when over the list
    procedure set_Y1_GUI(y: Word); // when over the scrollbar
    procedure Paint(cv: TCanvas);
  end;

  TLookupEditMouseMode = (led_mm_List, led_mm_ScrollBar);

  TET_LookupEdit = class(TEdit)
  private
///    bDontchange: Boolean;
    F_SL: TStrings;
    F_SL_tmpl: TStrings; // Formatier-Anweisung

// 2do: use CustomControl to draw the list outside the parent form (s. cvs tag 1.3.2.1)
    F_Pnl: TPanel;
    F_Img: TImage;
    F_col_ComboSelected: TColor;
    F_col_SearchTermHighlight: TColor;

    F_MaxHeight: Word; // 2020-03-29, we need this, as we do not have the ControlCanvas solution yet (s. VCL-TCustomComboBox)
    F_ItemsVisible: Word;
    F_FirstPainted: Word;
    F_Selected:     Word; // selected in thr StringList
    F_SelectedGUI:  Word; // selected on the Canvas

    F_MouseDown: Boolean;
    F_MouseMode: TLookupEditMouseMode;
    F_Scrollbar: TET_Scrollbar;

    aFnd:    Array[0..SL_MAX] of Integer; // SL-Indizes aller matchenden Strings/Items
    aFndPos: Array[0..SL_MAX] of Integer; // Pos. innerhalb des Strings/Items
    numFnd: Word;
    numFndPrev: Word;

    _OldProc: TWndMethod;
    procedure WndMessage(var msg: TMessage);

    function find_SL: Word;     // Anzahl gef.
  protected
//    procedure Paint; override;
    procedure set_max_height(max_h: Word);
  public
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;
    procedure Repaint; override;

    // Text has changed -->
    procedure Change; override;
    // Selection has changed -->
    procedure Highlight;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure DoExit; override;

    procedure F_Img_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure F_Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure F_Img_MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override; // <- fkt. mit TImage nicht !?
  published
    property maxHeight: Word read F_MaxHeight write set_max_height;
    property sl:      TStrings read F_SL write F_SL;
    property sl_tmpl: TStrings read F_SL_tmpl write F_SL_tmpl;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('EkwoTECH', [TET_LookupEdit]);
end;

function ppi(i: Integer): Integer;
begin
  Result := i * Screen.PixelsPerInch div 96; // 2do: 96 replace with Windows setting
end;

procedure TET_Scrollbar.Init(r: TRect; iMargin: Byte; nItemsAll: Word; nItemsShown: Word);
begin
  self.Rect := r;
  self.Margin := iMargin;
  self.ItemsAll   := nItemsAll;
  self.ItemsShown := nItemsShown;

  if self.ItemsAll = 0 then Exit;

  self.X          := self.Margin;
  self.YMin       := self.Margin;
  self.YMax       := self.Rect.Bottom - self.Rect.Top - self.Margin;
  self.HeightMov  := self.YMax - self.YMin; // movable range of Bar
  self.HeightBar  := Round(self.HeightMov * (self.ItemsShown / self.ItemsAll));

  if self.ItemsAll - self.ItemsShown = 0 then Exit; // avoid div by zero

  self.HeightItem := (self.HeightMov - self.HeightBar) / (self.ItemsAll - self.ItemsShown);
end;

procedure TET_Scrollbar.set_Y1(nItem: Word);
begin
  self.YItem := nItem;
  Mode := scr_List;
end;

procedure TET_Scrollbar.set_Y1_GUI(y: Word);
begin
  self.Y1 := y;
  Mode := scr_ScrollBar;
  self.YItem := round(self.Y1/self.HeightItem);
end;

procedure TET_Scrollbar.Paint(cv: TCanvas);
var y: Word;
begin
  // BG
  cv.Brush.Color := clSilver;
  cv.FillRect(self.Rect);

  // Bar
  if Mode = scr_Scrollbar then { Y1 already calculated in set_Y1_GUI };
  if Mode = scr_List then begin
     y := self.YItem; // = F_FirstPainted;
     self.Y1 := round(y*self.HeightItem);
  end;

  cv.Pen.Width := 5;
  cv.Pen.Color := clGray;
  cv.MoveTo(self.Rect.Left+X, self.Rect.Top+5 + self.Y1);
  cv.LineTo(self.Rect.Left+X, self.Rect.Top+5 + self.Y1 + self.HeightBar);
end;

procedure TET_LookupEdit.set_max_height(max_h: Word);
var i: Word;
begin
  i := max_h div ITEM_HEIGHT;
  F_MaxHeight := i * ITEM_HEIGHT;
  F_ItemsVisible := i;
end;

constructor TET_LookupEdit.Create(Owner: TComponent); // Owner = TForm
begin
  Inherited;

///  bDontchange := False;
  F_SL := TStringList.Create;
  F_FirstPainted := 0;
  F_Selected := 0;
  F_SL_tmpl := TStringList.Create;

  F_MaxHeight := 100;

  if (csDesigning in ComponentState) then begin
  end else begin
     //
     //  at this time a lot of self-properties (self.Name, self.Top, ...) are not available yet,
     //  that's why they are set later, s. OnChange
     //
     F_Pnl         := TPanel.Create(self);
     F_Pnl.Parent  := TWinControl(Owner);
     F_Pnl.Visible := False;

     F_Img := TImage.Create(self);
     F_Img.Parent  := F_Pnl;
     F_Img.Width   := F_Pnl.Width;
     F_Img.Height  := F_Pnl.Height;
     F_Img.OnMouseMove := F_Img_MouseMove;
     F_Img.OnMouseDown := F_Img_MouseDown;
     F_Img.OnMouseUp   := F_Img_MouseUp;

     F_col_ComboSelected := clLime;
     F_col_SearchTermHighlight := clBlue;
  end;
  _OldProc := WindowProc;
  WindowProc := WndMessage;

  F_Scrollbar := TET_Scrollbar.Create;
end;

procedure TET_LookupEdit.WndMessage(var msg: TMessage); // nur für Scrollwheel, ansonsten Mousemove (funktioniert das??) jooooo geht so
var //mousePos: TPoint;
//  wc: TWinControl;
  {lo,}hi: Word;
begin
  // mouse wheel scrolling for the control under the mouse
  case msg.Msg of
     WM_VSCROLL,
     WM_MOUSEWHEEL:
  begin
//     mousePos.x := WORD(msg.lParam);
//     mousePos.y := HIWORD(msg.lParam);
//     wc := FindVCLWindow(mousePos);
///     lo := WORD(msg.WParam);
     hi := HIWORD(msg.WParam);
     if hi < 255 then begin// up
        if F_FirstPainted > 0 then
           F_FirstPainted := F_FirstPainted-1
     end else begin// down
        if F_FirstPainted + F_ItemsVisible < numFnd then
        F_FirstPainted := F_FirstPainted+1;
     end;
     F_Scrollbar.set_Y1(F_FirstPainted);
     Change(); // 2so: use Paint()

{
     if wc = nil then
//        Handled := True
     else
//        if wc.Handle <> msg.hwnd then begin
           SendMessage(wc.Handle, WM_MOUSEWHEEL, msg.wParam, msg.lParam);
//           Handled := True;
}        end;
  end;
{
  case msg.Msg of
     WM_VSCROLL,
     WM_MOUSEWHEEL:
        SendMessage(lst1.Handle,
                                msg.Msg,
                                msg.wParam,
                                msg.lParam);
  end;
}  _OldProc(msg);
end;

destructor TET_LookupEdit.Destroy;
begin
  F_Scrollbar.Free;
// F_Pnl, F_Img --> werden (anschließend?) vom Owner (der Form) freigegeben
  F_SL.Free;
  F_SL_tmpl.Free;

  inherited Destroy;
end;

{
procedure TET_LookupEdit.Paint;
begin
end;
}

function TET_LookupEdit.find_SL: Word; // Anzahl gef.
var i: Word;
  j: Byte;
  iPos: Integer;
begin
  if F_sl.Count = 0 then begin Result := 0; Exit; end;

  Result := 0;
  for j := Low(aFnd) to High(aFnd) do aFnd[j] := -1;
  j := 0;
  for i := 0 to F_sl.Count-1 do begin
    iPos := Pos(LowerCase(self.Text),LowerCase(F_sl[i]));
    if iPos > 0 then begin // <- LowerCase
       aFnd[j] := i;
       aFndPos[j] := iPos;
       j := j+1;
       if j > High(aFnd) then Exit; // max z.B. 5
       Result := Result+1;
    end;
  end;
end;


procedure TET_LookupEdit.Change;
var i: Word;
  j: Byte;
  a_L: array[0..(6-1)] of String; // typ;id;Bezeichnung
  x: Word;
  pt,ptPar,ptSelf: TPoint;

  procedure Paint_BG; // optimieren, nur aufrufen, wenn selected
  var aCols: Array[0..1,0..1] of TColor;
    j: Byte;
  begin
     aCols[0][0] := F_col_ComboSelected;   // BG selected
     aCols[0][1] := clWhite;  // FG
     aCols[1][0] := clWhite;  // BG
     aCols[1][1] := clBlack;  // FG
     if i = F_Selected then
        j := 0
     else
        j := 1;
     F_Img.Canvas.Brush.Color := aCols[j][0];
     F_Img.Canvas.FillRect(Rect(0,(i-F_FirstPainted)*ITEM_HEIGHT-1,F_Img.Width,i*ITEM_HEIGHT+ITEM_HEIGHT));
     F_Img.Canvas.Font.Color := aCols[j][1];
  end;

  procedure Paint_FG; // print search Term Highlighted e.g. P[ete]r
  var iPos: Integer; // Position of search term
    iLen: Byte; // Length of search term
    aStr: array[0..2] of String;
    sz:   array[0..1] of TSize;
  begin
     iPos := aFndPos[i]; // (i-F_FirstPainted) ?
     iLen := Length(self.Text);

     F_Img.Canvas.Font.Style := [];
     F_Img.Canvas.Font.Color := clBlack;
     aStr[0] := Copy(a_L[j],1,iPos-1);
     sz[0] := F_Img.Canvas.TextExtent(aStr[0]);
     F_Img.Canvas.TextOut(x,(i-F_FirstPainted)*ITEM_HEIGHT,aStr[0]);

     F_Img.Canvas.Font.Style := [fsBold];
     F_Img.Canvas.Font.Color := F_col_SearchTermHighlight;
     aStr[1] := Copy(a_L[j],iPos,iLen);
     sz[1] := F_Img.Canvas.TextExtent(aStr[1]); // depending on chosen .Style
     F_Img.Canvas.TextOut(x+sz[0].cx,(i-F_FirstPainted)*ITEM_HEIGHT,aStr[1]);

     F_Img.Canvas.Font.Style := [];
     F_Img.Canvas.Font.Color := clBlack;
     aStr[2] := Copy(a_L[j],iPos+iLen,99);
     F_Img.Canvas.TextOut(x+sz[0].cx+sz[1].cx,(i-F_FirstPainted)*ITEM_HEIGHT,aStr[2]);
  end;

begin
  if not (csDesigning in ComponentState) then
     Assert(self.F_MaxHeight > ITEM_HEIGHT, self.Name + ', Fehler: MaxHeight < 17');
///  if bDontchange then begin bDontchange := False; Exit; end;

  inherited Change;
  if (csDesigning in ComponentState) then Exit; // <-- F_Pnl und f_Img nicht angelegt

//  F_Pnl.Parent := self.Parent; // ergibt automatisch die richtige Position, aber
                                 // das Panel ist größenbegrenzt durch das Parent Control
  F_Pnl.Parent := TWinControl(Owner);
  ptPar := TWinControl(owner).ClientToScreen(Point(0,0)); // Hack!!
  ptSelf := self.ClientToScreen(Point(0,0));              // Hack!!
  pt.x := ptSelf.x - ptPar.x;
  pt.y := ptSelf.y - ptPar.y;

  if (self.Text = '') or (self.Text = self.Name) then begin
     F_Img.Visible := False;
     F_Pnl.Visible := False;
     Exit; // zur Form.Create-Zeit
  end;

  numFndPrev := numFnd;
  numFnd := find_SL();
  if numFnd <> numFndPrev then begin
     F_Selected     := 0;
     F_FirstPainted := 0;
  end;

  F_pnl.Left    := pt.x;
  F_pnl.Top     := pt.y + self.Height;
  F_pnl.Width   := self.Width;
  F_pnl.Height  := min(F_maxheight,numFnd*ITEM_HEIGHT); /// hack!!

  // resize "trick"
  if (F_Img <> nil) then
     F_Img.Free;
  F_Img := TImage.Create(self);
  F_Img.Parent := F_Pnl;
  F_Img.Width  := F_Pnl.Width;
  F_Img.Height := F_Pnl.Height;
  F_Img.OnMouseMove := F_Img_MouseMove;
  F_Img.OnMouseDown := F_Img_MouseDown;
  F_Img.OnMouseUp   := F_Img_MouseUp;
  // resize "trick"

  F_img.Align := alClient;
  F_img.Canvas.Brush.Color := clWhite;
  F_img.Canvas.FillRect(Rect(0,0,F_img.Width,F_img.Height));

  if numFnd > 0 then
     if F_SL.Count > 0 then begin
        for i := F_FirstPainted to F_FirstPainted + min(numFnd,F_ItemsVisible)-1 do begin
           Paint_BG();
           uHelpFunctions.csv_to_sArr(F_SL[aFnd[i]],a_L);
           j := 0;
           x := 0;
           Paint_FG();
        end;
     end;
  F_Pnl.Visible := Length(Text) > 0;
  if Text = Name then
     F_Pnl.Visible := False;
  F_Pnl.BringToFront; // <- wirft einen Fehler

  // ScrollBar, 2do: Init sollte nicht bei jedem hover aufgerufen werden!
  F_Scrollbar.Init(Rect(F_Img.Width-10,0,F_Img.Width,F_Img.Height), 5, numFnd, F_ItemsVisible);
  if F_Scrollbar.Mode = scr_Scrollbar then
     F_FirstPainted := F_Scrollbar.YItem;
  if (F_maxheight < numFnd*ITEM_HEIGHT) then
     F_Scrollbar.Paint(F_Img.Canvas);

  Tag := 0;
end;

procedure TET_LookupEdit.Highlight;
begin
  Change(); // 2do: nicht komplett neu zeichnen, sondern nur das vorher und jetzt selektierte!!
end;

procedure TET_LookupEdit.KeyPress(var Key: Char);
begin
  if (csDesigning in ComponentState) then Exit; // <-- F_Pnl und f_Img nicht angelegt

  if Key = #13 then begin // <Return> --> 2do soll nicht ins nächste Element (Kunde) springen!
     if (F_Selected >= 0) and (F_Selected < numFnd) then begin
        self.Tag  := integer(F_SL.Objects[aFnd[F_Selected]]); // first Tag, as .Text ...
        self.Text :=                 F_SL[aFnd[F_Selected]];
     end;
     F_Pnl.Visible := False;
     Self.SelectAll();
     Key := #0;
  end;
  if Key = #27 then begin // <Esc>
     F_Pnl.Visible := False;
     Key := #0;
  end;

  inherited; // <-- ?
end;

procedure TET_LookupEdit.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (csDesigning in ComponentState) then Exit; // <-- F_Pnl und f_Img nicht angelegt
// ---------------------------------------------------------------
// 2do: hoch/runter soll nicht zu links/rechts im TEdit führen >>>
// ---------------------------------------------------------------
  if Key = 38 then begin // Pfeil hoch
     if F_Selected > 0 then F_Selected := F_Selected - 1;
     if F_Selected < F_FirstPainted then F_FirstPainted := F_FirstPainted - 1;
     F_Scrollbar.set_Y1(F_FirstPainted); // 2do, im Change
     Change(); // 2do: Highlight();
     Key := 0; // do not move left/right with up/down Arrow
  end;
  if Key = 40 then begin // Pfeil runter
     if F_Selected < (numFnd-1) then begin
        F_Selected := F_Selected+1;
        if F_Selected >= F_FirstPainted + F_ItemsVisible then
           F_FirstPainted := F_FirstPainted + 1;
        F_Scrollbar.set_Y1(F_FirstPainted); // 2do, im Change
        Change(); // 2do: Highlight();
        Key := 0;
     end;
  end;

  inherited; // <-- ?
end;

procedure TET_LookupEdit.DoExit;
begin
  F_Pnl.Visible := False;
  F_MouseMode := led_mm_List;
  inherited; // <-- ?
end;

procedure TET_LookupEdit.Repaint;
begin
//  inherited Repaint;
end;

procedure TET_LookupEdit.F_Img_MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if (csDesigning in ComponentState) then Exit; // <-- F_Pnl und f_Img nicht angelegt
  if F_Pnl.Visible = True then
     // if we left scrollbar area, but mousebutton still pressed, then continue operating the scrollbar
     if (X > self.Width-10) or (F_MouseMode = led_mm_ScrollBar) then begin
     // b) scrollbar
        if F_MouseDown then begin
           if (Y-F_Scrollbar.YGrab < 0) then
              F_Scrollbar.set_Y1_GUI(0)
           else if (Y+F_Scrollbar.HeightBar-F_Scrollbar.YGrab > F_Scrollbar.HeightMov) then
              F_Scrollbar.set_Y1_GUI(F_Scrollbar.HeightMov-F_Scrollbar.HeightBar)
           else
              F_Scrollbar.set_Y1_GUI(Y-F_Scrollbar.YGrab);
           Change();
        end;
     end else begin
     // a) items highlighten
        if (Y div ITEM_HEIGHT) <> F_SelectedGUI then begin
           F_SelectedGUI := Y div ITEM_HEIGHT;
           F_Selected    := F_FirstPainted + F_SelectedGUI;
           Change(); // Highlight();
        end;
     end;
end;

procedure TET_LookupEdit.F_Img_MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
//var h_item: Word;
begin
//  if (csDesigning in ComponentState) then Exit; // <-- F_Pnl und f_Img nicht angelegt
///  bDontchange := True;
  if X < self.Width-10 then begin
     // a) items highlighten
     F_MouseMode := led_mm_List;

     F_SelectedGUI := Y div ITEM_HEIGHT;
     F_Selected    := F_FirstPainted + F_SelectedGUI;
     if (F_Selected >= 0) and (F_Selected < F_SL.Count) then begin
        self.Tag  := integer(F_SL.Objects[aFnd[F_Selected]]); // first Tag, as .Text ...
        self.Text :=                 F_SL[aFnd[F_Selected]]; // ... calls the change event (necessary?)
     end;
     F_Pnl.Visible := False;
     F_Selected     := 0;
     F_FirstPainted := 0;
     self.SelStart := Length(self.Text);
  end else begin
     // b) scrollbar
     F_MouseMode := led_mm_ScrollBar;

     if Y > F_Scrollbar.Y1 then
        F_Scrollbar.YGrab := Y - F_Scrollbar.Y1
     else begin
        F_Scrollbar.YGrab := Y;
        F_Scrollbar.set_Y1_GUI(max(0,F_Scrollbar.YGrab - Round(F_Scrollbar.HeightMov / 2)));
     end;
  end;
  F_MouseDown := True;
end;

procedure TET_LookupEdit.F_Img_MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  F_MouseDown := False;
  F_MouseMode := led_mm_List;
end;

procedure TET_LookupEdit.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
end;

end.
