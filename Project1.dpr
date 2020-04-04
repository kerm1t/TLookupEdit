program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  ET_LookupEdit in '..\LookupEdit\ET_LookupEdit.pas',
  memcheck in '..\..\ET_3rdparty\memcheck.pas';

{$R *.RES}

  procedure Leak;
  begin
     TObject.Create;
  end;
begin
///  Memchk;
//  Leak;

  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
