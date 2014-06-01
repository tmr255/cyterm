unit VgaGlobal;

{$MODE Delphi}

{
CyTerm Project.
VgaGlobal created January 20, 2001 by Shawn Rapp

this unit is for constants and types that are referenced
There is alot more stuff i know that should be put in this
unit.
}

interface
uses Graphics, LCLIntf, LCLType, LMessages, types;
const

   VGAColor : array[0..16] of TColor = //default PC color scheme...windows colors apply all except for brown.  colors are in exact order.
   (
    clBlack,   //black
    clNavy,    //dark blue
    clGreen,   //dark green
    clTeal,    //cyan
    clMaroon,  //dark red
    clPurple,  //purple
    $00008284, //brown
    clSilver,  //light gray
    $004B4B4B, //dark gray testing
//    clGray,    //dark gray
    clBlue,    //light blue
    clLime,    //light green
    clAqua,    //light cyan
    clRed,     //light red
    clFuchsia, //fuchsia
    clYellow,  //yellow
//    clWhite    //white
    $00FEFEFE,    //white
    255     //transparent
    );

   //crt standard color values (and Borlands punishment to programers)
  Black = 0;
  Blue = 1;
  Green = 2;
  Cyan = 3;
  Red = 4;
  Magenta = 5;
  Brown = 6;
  LightGray = 7;
  DarkGray = 8;
  LightBlue = 9;
  LightGreen = 10;
  LightCyan = 11;
  LightRed = 12;
  LightMagenta = 13;
  Yellow = 14;
  White = 15;
  Blink = 128;

type
  FillPatternType = array[1..8] of byte;
  PointType = TPoint;


implementation
end.
