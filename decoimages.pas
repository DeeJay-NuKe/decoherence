{Copyright (C) 2012-2016 Yevhen Loza

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.}

unit decoimages;

{$mode objfpc}{$H+}

interface

uses Classes,
  castleVectors, CastleGLImages, CastleImages,
  decointerface,
  decoglobal;

type
  DAbstractImage = class(DAbstractElement)
  { General routines shared by images and labels }
  public
    { Thread-safe part of rescaling the image }
    procedure RescaleImage;
    procedure rescale; override;
    constructor create(AOwner:TComponent); override;
    destructor destroy; override;
    procedure draw; override;
  private
    SourceImage: TCastleImage;  //todo scale Source Image for max screen resolution ? //todo never store on Android.
    ScaledImage: TCastleImage;
    { keeps from accidentally re-initializing GL }
    InitGLPending: boolean;
    ImageReady: boolean;
    GLImage: TGLImage;
    { initialize GL image. NOT THREAD SAFE! }
    procedure InitGL;
  end;

type
  { most simple image type }
  DStaticImage = class(DAbstractImage)
  public
    Opacity: float;
    Function GetAnimationState: Txywha; override;
  end;

type
  { Wind and smoke effects used in different situations }
  //todo might be descendant of DStaticImage
  DWindImage = class (DAbstractImage)
  public
    color: TVector4Single;
    procedure draw; override;
  private
    phase: float;
  end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
implementation

uses SysUtils, CastleLog,
     decogui;

procedure DAbstractImage.InitGL;
begin
  if InitGLPending then begin
    InitGLPending:=false;
    if ScaledImage<>nil then begin
      FreeAndNil(GLImage);
      GLImage := TGLImage.create(ScaledImage,true,true);
      ImageReady := true;
    end else WriteLnLog('DAbstractElement.InitGL','ERROR: Scaled Image is nil!');
  end;
end;

constructor DAbstractImage.create(AOwner: TComponent);
begin
  inherited create(AOwner);
  InitGLPending := false;
  imageReady := false;
end;

destructor DAbstractImage.destroy;
begin
  FreeAndNil(GLImage);
  //scaledImage is automatically freed by GlImage
  {freeandnil(ScaledImage);}
  FreeAndNil(SourceImage);
  inherited;
end;

procedure DAbstractImage.rescale;
begin
  inherited;
  RescaleImage;
  //InitGL;
end;

procedure DAbstractImage.RescaleImage;
begin
 if base.initialized then
  if (scaledImage = nil) or (ScaledImage.Width <> base.w) or (ScaledImage.height <> base.h) then begin
    scaledImage := SourceImage.CreateCopy as TCastleImage;
    scaledImage.Resize(base.w,base.h,InterfaceScalingMethod);
    InitGLPending := true;
  end
 else
   writeLnLog('DAbstractImage.RescaleImage','ERROR: base.initialized = false');
end;

procedure DAbstractImage.draw;
var currentAnimationState:Txywha;
begin
  if ImageReady then begin
    //animate
    currentAnimationState:=GetAnimationState;
    GLImage.color:=vector4single(1,1,1,currentAnimationState.Opacity); //todo
    GLIMage.Draw(currentAnimationState.x1,currentAnimationState.y1,currentAnimationState.w,currentAnimationState.h); //todo
  end;
end;

{----------------------------------------------------------------------------}

Function DStaticImage.GetAnimationState: Txywha;
begin
  result := Txywha.create(nil);
  result.x1 := base.x1;
  result.x2 := base.x2;
  result.opacity := Opacity;
end;


{=============================================================================}
{========================= wind image ========================================}
{=============================================================================}

procedure DWindImage.Draw;
var phase_scaled:integer;
begin
  if ImageReady then begin
    color[3] := 0.2+0.2/4*sin(2*Pi*3*phase);
    GLImage.Color := color;
    phase_scaled := round(Phase*GUI.width);

    //draw first part of the image
    GLImage.Draw(phase_scaled,0,
                 GUI.width-phase_scaled,GUI.height,
                 0,0,
                 GUI.width-phase_scaled,GUI.height);
    //draw second part of the image
    GLImage.Draw(0,0,
                 phase_scaled,GUI.height,
                 GUI.width-phase_scaled,0,
                 phase_scaled,GUI.height);
  end else WriteLnLog('DWindImage.DrawMe','ERROR: Wind image not ready to draw!');
end;


end.
