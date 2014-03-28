{
Strip-0x00 (c) 2014 Lostech
https://github.com/Lostech/Strip-0x00/

Strip-0x00 is a small tool which does remove appended and/or leading 0x00 bytes from a binary file for e.g. a ROM dump.
To compile the binary you need Lazarus/FPC.
The sourcecode is released under the General Public License Version 2.

http://www.gnu.org/licenses/gpl-2.0
}program Strip;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp
  { you can add units after this };

type

  { TStrip }

  TStrip = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

const
  AppTitle:  String = 'Strip-0x00';
  Version:   String = '1.0';


{ TStrip }

procedure TStrip.DoRun;
var
  ErrorMsg:     String;
  InputFile:    String;
  OutputFile:   String;
  StripMode:    Byte;
  InputStream:  TFileStream;
  OutputStream: TFileStream;
  InputPos:     Int64;
  InputPos2:    Int64;
  StreamPos:    Int64;
  WorkByte:     Byte;

begin
  //Start
  writeln('');
  writeln(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
  writeln('::                                                                           ::');
  writeln('::                    '+AppTitle+' V'+Version+' (c) 2014 Lostech                       ::');
  writeln('::                                                                           ::');
  writeln('::                 https://github.com/Lostech/Strip-0x00/                    ::');
  writeln('::                                                                           ::');
  writeln(':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::');
  writeln('');

  // quick check parameters
  ErrorMsg:=CheckOptions('h123i:o:','help mode1 mode2 mode3 input: output:');
  if ErrorMsg<>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if (HasOption('h','help')) or (ParamCount=0) then
  begin
    WriteHelp;
    Terminate;
    Exit;
  end;
  if HasOption('1','mode1') then
    begin
      StripMode:=1;
      writeln('Mode 1: strip appending 0x00 bytes');
    end
  else if (HasOption('2','mode2')) or (ParamCount=0) then
    begin
      StripMode:=2;
      writeln('Mode 2: strip leading 0x00 bytes');
    end
  else if (HasOption('3','mode3')) or (ParamCount=0) then
    begin
      StripMode:=3;
      writeln('Mode 3: strip appending and leading 0x00 bytes');
    end
  else
    begin
      StripMode:=1;
      writeln('Mode 1: strip appending 0x00 bytes');
    end;

  //set files
  InputFile:=GetOptionValue('i', 'input');
  if FileExists(InputFile)=false then
    begin
      writeln('');
      writeln('Error: input file "'+InputFile+'" not found!');
      writeln('');
      Terminate;
      Exit;
    end;
  if GetOptionValue('o', 'output')<>'' then
    OutputFile:=GetOptionValue('o', 'output')
  else
    OutputFile:=ChangeFileExt(InputFile,'_stripped'+ExtractFileExt(InputFile));

  //open input file
  InputStream:=TFileStream.Create(InputFile,fmOpenRead);

  //check offset for last leading 0x00 byte in input file
  if StripMode<>1 then
    begin
      write('Checking offset for last leading 0x00 byte in input file...');
      InputPos:=0;
      WorkByte:=$0;
      while InputPos<InputStream.Size do
        begin
          InputStream.Seek(InputPos,0);
          InputStream.Read(WorkByte,1);
          if Workbyte<>$0 then break;
          inc(InputPos);
        end;
      write('   0x'+IntToHex(InputPos,8)+#13#10);
      if InputPos=$0 then
        begin
          writeln('');
          writeln('Error: no leading 0x00 bytes found!');
          writeln('');
          Terminate;
          Exit;
        end;
    end;


  //check offset for first appended 0x00 byte in input file
  if StripMode<>2 then
    begin
      write('Checking offset for first appended 0x00 byte in input file...');
      InputPos2:=InputStream.Size-1;
      WorkByte:=$0;
      while InputPos2>0 do
        begin
          InputStream.Seek(InputPos2,0);
          InputStream.Read(WorkByte,1);
          if Workbyte<>$0 then break;
          dec(InputPos2);
        end;
      write(' 0x'+IntToHex(InputPos2,8)+#13#10);
      if InputPos2=InputStream.Size-1 then
        begin
          writeln('');
          writeln('Error: no appended 0x00 bytes found!');
          writeln('');
          Terminate;
          Exit;
        end;
    end;

  //Create new output file
  if FileExists(OutputFile) then
    DeleteFile(OutputFile);
  OutputStream:=TFileStream.Create(OutputFile,fmCreate);

  //copy content from input file to output file without appended 0x00 bytes
  StreamPos:=0;
  write('Create output file without stripped 0x00 bytes...');
  if StripMode=1 then
    begin
      while StreamPos<InputPos2+1 do
        begin
          InputStream.Seek(StreamPos,0);
          OutputStream.Seek(StreamPos,0);
          OutputStream.CopyFrom(InputStream,1);
          inc(StreamPos);
        end;
    end;
  if StripMode=2 then
    begin
      StreamPos:=InputPos;
      while StreamPos<InputStream.Size do
        begin
          InputStream.Seek(StreamPos,0);
          OutputStream.Seek(StreamPos-InputPos,0);
          OutputStream.CopyFrom(InputStream,1);
          inc(StreamPos);
        end;
    end;
  if StripMode=3 then
    begin
      StreamPos:=InputPos;
      while StreamPos<InputPos2+1 do
        begin
          InputStream.Seek(StreamPos,0);
          OutputStream.Seek(StreamPos-InputPos,0);
          OutputStream.CopyFrom(InputStream,1);
          inc(StreamPos);
        end;
    end;
  write('             done'+#13#10);

  //compare image sizes
  writeln('Old image size                                                0x'+IntToHex(InputStream.Size,8));
  writeln('New image size                                                0x'+IntToHex(OutputStream.Size,8));
  writeln('Amount of removed 0x00 bytes                                  0x'+IntToHex(InputStream.Size-OutputStream.Size,8));

  //free up streams
  if InputStream<>NIL then
    InputStream.Free;
  if OutputStream<>NIL then
     OutputStream.Free;

  { add your program here }

  // stop program loop
  Terminate;
end;

constructor TStrip.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TStrip.Destroy;
begin
  inherited Destroy;
end;

procedure TStrip.WriteHelp;
begin
  { add your help code here }
  writeln(AppTitle+' removes all appended 0x00 bytes of a file for e.g. ROM dumps');
  writeln('');
  writeln('Usage: (mode option)',ExtractFileName(ExeName),' inputfile (outputfile)');
  writeln('');
  writeln('Options:');
  writeln('-h or --help       this help page');
  writeln('-1 or --mode1      remove appended 0x00 bytes (default)');
  writeln('-2 or --mode2      remove leading 0x00 bytes');
  writeln('-3 or --mode3      remove appended and leading 0x00 bytes');
end;

var
  Application: TStrip;
begin
  Application:=TStrip.Create(nil);
  Application.Title:=AppTitle;
  Application.Run;
  Application.Free;
end.

