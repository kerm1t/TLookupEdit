unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ET_LookupEdit,
  extctrls;

type
  TForm1 = class(TForm)
    editAdressen: TET_LookupEdit;
    Label2: TLabel;
    ComboBox1: TComboBox;
    lb: TListBox;
    Button1: TButton;
    Panel1: TPanel;
    Label1: TLabel;
    editPferde: TET_LookupEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ComboBox1Change(Sender: TObject);
    procedure editPfdChange(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

  aPfd: array[1..25] of String = ('Cholesterine','Penny','Moffy','Jeanny','Penelope',
                               'Alfredo','Montobaldo','Jellyfanzo','Montalbine','Susi',
                               'Strolch','Bibi','Momo','Ludmilla','Smilla',
                               'Charlie','Henneliese','Meinkraft','Giselle','Popokeee',
                               'Hermine','Barton','Wuwuzeela','Gisbert','Antonella');
  aKd: array[1..20] of String = ('>> Mayer, Pekunia','Scholz, Ludmilla','Sellers, Peter','Klimbim, Tony','Langstedt, Ludger',
                                'Beerbaum, Fritz','Kussi, Lollo','Ferrari, Enzo','Baum, Kurt','Simmering, Franzine',
                                'Greger, Gerlinde','Müller, Kunigunde','>> Schreier, Lieselotte','Anfang, Charlie','Baum, Tina',
                                'Paulsen, Gebrüder oHg','Leiseschneider, Utz','Gortzka, Janus','Heimer, Hans','Erkel, Angela');

implementation

{$R *.DFM}

procedure TForm1.FormCreate(Sender: TObject);
var sl: TStringList;
  i: Byte;
begin
  Caption := 'TLookupEdit Example (C) 2020 EkwoTECH';
//  KeyPreview := True;

  // (a) direct add
  for i := low(aPfd) to high(aPfd) do
     editPferde.sl.AddObject(aPfd[i],TObject(i));

  sl := TStringList.Create();
  for i := low(aKd) to high(aKd) do
     sl.Add(aKd[i]);
  // (b) assign full list
  editAdressen.sl.Assign(sl);
  sl.Free;

//  self.Controls[2].BringToFront; // <- Privilegierte Instruktion
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
//
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
begin
  ComboBox1.DroppedDown := True;
end;

procedure TForm1.editPfdChange(Sender: TObject);
begin
//  editPfd.F_Pnl.BringToFront;
//  editPfd.F_Pnl.Parent := self;
//edit2.SendToBack;
end;

procedure TForm1.Button1Click(Sender: TObject);
var i: Byte;
   wc: TControl;
begin
  lb.Clear;
  for i := 0 to self.ControlCount-1 do begin
     wc := self.Controls[i];
     lb.Items.Add(wc.Name);
  end;
end;

end.
