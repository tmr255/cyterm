{
  Relay Unit loads and executes plugin DLL's and also
  recieves data from main application and than decides
  where the data belongs.

  Programmer    version  Date        Comment on code change
  ------------  -------  ----------  ------------------------------------------------------------
  Shawn         0.0.1    05/20/2000  Initial version

  UNFINISHED CODE!  Idea behind this is that eventually
  emulations such as Ansi, Rip, etc and protocals such as
  X, y, Z would be plugin's. 
}
unit relay;

{$MODE Delphi}

interface

uses classes, LCLIntf, LCLType, LMessages, Forms, FileUtil, SysUtils;

type
  //plug in object
  TTestPlugIn = class
    Name: String;
    Address: Integer;
    Call: Pointer;
  end;
  GetNameFunction = function : PChar;
  PlugInInit = procedure (Owner: Integer);

procedure SearchFileExt(const Dir, Ext: String; Files: TStrings);
procedure LoadPlugIns;

implementation

uses Main;

var
  Plugins: TList;
  StopSearch: Boolean;

procedure SearchFileExt(const Dir, Ext: String; Files: TStrings);
var
  Found: TSearchRec;
  Sub: String;
  i : Integer;
  Dirs: TStrings; //Store sub-directories
  Finished : Integer; //Result of Finding
begin
  StopSearch := False;
  Dirs := TStringList.Create;
  Finished := FindFirstUTF8(Dir + '*.*',63,Found); { *Converted from FindFirst* }
  while (Finished = 0) and not (StopSearch) do
    begin
      //Check if the name is valid.
      if (Found.Name[1] <> '.') then
      	begin
          //Check if file is a directory
    	  if (Found.Attr and faDirectory = faDirectory) then
      	    Dirs.Add(Dir + Found.Name)  //Add to the directories list.
    	  else if Pos(UpperCase(Ext), UpperCase(Found.Name))>0 then
            Files.Add(Dir + Found.Name);
    end;
    Finished := FindNextUTF8(Found); { *Converted from FindNext* }
  end;
  //end the search process.
  FindCloseUTF8(Found); { *Converted from FindClose* }
  //Check if any sub-directories found
  if not StopSearch then
    for i := 0 to Dirs.Count - 1 do
      //If sub-dirs then search agian ~>~>~> on and on, until it is done.
      SearchFileExt(Dirs[i], Ext, Files);

  //Clear the memories.
  Dirs.Free;
end;

procedure LoadPlugIns;
var
  Files: TStrings;
  i: Integer;
  TestPlugIn : TTestPlugIn;
begin
  Files := TStringList.Create;
  Plugins := TList.Create;
  //Search what ever is in the app's dir
  SearchFileExt(ExtractFilepath(Application.Exename) + '\', '.dll', Files);
  for i := 0 to Files.Count-1 do
    begin
      //create a new plug in
      TestPlugIn := TTestPlugIn.Create;
      TestPlugIn.Address := LoadLibrary(PChar(Files[i]));
      //Initialize the plugin give your app instance (and the handle if necessary)
      PlugInInit(GetProcAddress(TestPlugIn.Address, 'Init'))(HInstance);
      //get the a menu item
      TestPlugIn.Name := GetNameFunction(GetProcAddress(TestPlugIn.Address, 'GetName'));
      //get the function insert text
      TestPlugIn.Call := GetProcAddress(TestPlugIn.Address, 'InsertText');
      PlugIns.Add(TestPlugIn);
    end;
  Files.Free;
end;

procedure FreePlugIns;
var
  i: Integer;
begin
  for i := 0 to PlugIns.Count-1 do
   begin
     //Run finalize function in the plugin before you unload it.
     //Because it is not applicable here so it is ignored.
     //free every loaded plugins
     FreeLibrary(TTestPlugIn(PlugIns[i]).Address);
  end;
  PlugIns.Free;
end;

end.
