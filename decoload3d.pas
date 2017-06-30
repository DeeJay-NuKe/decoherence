{Copyright (C) 2012-2017 Yevhen Loza

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

{---------------------------------------------------------------------------}

{ x3d file loading and basic processing routines.
  The unit name is not good, should change it to something more informative}
unit decoload3d;

{$INCLUDE compilerconfig.inc}

interface

uses X3DNodes, fgl,
  decoglobal;

Type
  TMaterialList = specialize TFPGObjectList<TMaterialNode>;

Type
  { a link for easy acessing the material of EACH model loaded
    at the moment it operates only AmbientIntensity }
  DMaterialContainer = class
    private
      fAmbient: float;
    public
      { a list of materials }
      Value: TMaterialList;
      { used only to "Get" value}
      property Ambient: float read fAmbient;
      { set Ambient Intensity for all models }
      procedure SetAmbientIntensity(v: float);
      constructor create;
      destructor destroy; override;
  end;

var AmbientIntensity: DMaterialContainer;

{ adds requested TTexturePropertiesNode and creates corresponding lists}
function LoadBlenderX3D(URL: string): TX3DRootNode;
//procedure FreeTextureProperties;
{++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
implementation

uses SysUtils, {StrUtils,}
  castleLog, castlevectors, decoinputoutput;

var TextureProperties: TTexturePropertiesNode;

procedure MakeDefaultTextureProperties;
begin
  {$PUSH}{$WARN 6018 OFF} //hide "unreachable code" warning, it's ok here
  {freeandnil?}
  if anisotropic_smoothing > 0 then begin
    textureProperties := TTexturePropertiesNode.Create;
    TextureProperties.AnisotropicDegree := anisotropic_smoothing;
    TextureProperties.FdMagnificationFilter.Value := 'DEFAULT';
    TextureProperties.FdMinificationFilter.Value := 'DEFAULT';

    {do not free this node automatically! Required for constructor}
    TextureProperties.KeepExisting := 1;
  end else TextureProperties := nil;
  {$POP}
end;

{-----------------------------------------------------------------------------}

{maybe, a better name would be nice.
 attaches texture properties (anisotropic smoothing) to the texture of the object.
 TODO: Normal map still doesn't work. I should fix it one day...}
procedure AddMaterial(Root: TX3DRootNode);
  procedure ScanNodesRecoursive(source: TAbstractX3DGroupingNode);
  var i: integer;
      material: TMaterialNode;
  begin
    for i := 0 to source.FdChildren.Count-1 do
    if source.FdChildren[i] is TAbstractX3DGroupingNode then
      ScanNodesRecoursive(TAbstractX3DGroupingNode(source.FdChildren[i]))
    else
      if (source.FdChildren[i] is TShapeNode) then
        try
          // assign TextureProperties (anisotropic smoothing) for the imagetexture
          //{$Warning WHY THE TextureProperties keeps automatically released????}
          (TShapeNode(source.FdChildren[i]).fdAppearance.Value.FindNode(TImageTextureNode,false) as TImageTextureNode).{Fd}TextureProperties{.Value} := TextureProperties{.DeepCopy};
          {create a link to each and every material loaded}
          Material := (TShapeNode(source.FdChildren[i]).FdAppearance.Value.FindNode(TMaterialNode,false) as TMaterialNode);
          // set material ambient intensity to zero for complete darkness :)
          Material.AmbientIntensity := 0;
          AmbientIntensity.value.add(Material);
        except
          writeLnLog('AddMaterial.ScanNodesRecoursive','try..except fired');
        end;
  end;
begin
  ScanNodesRecoursive(Root);
end;

{---------------------------------------------------------------------------}

function LoadBlenderX3D(URL: string): TX3DRootNode;
begin
  writeLnLog('LoadBlenderX3D','Reading file '+URL);
  if TextureProperties = nil then MakeDefaultTextureProperties;
  result := load3DSafe(URL);
  AddMaterial(result);
end;

{=================== Ambient Intensity List ==========================}

constructor DMaterialContainer.create;
begin
  Value := TMaterialList.create(false);
  fAmbient := 0;
end;
destructor DMaterialContainer.destroy;
begin
  FreeAndNil(Value);
  inherited;
end;
procedure DMaterialContainer.SetAmbientIntensity(v: float);
var i: TMaterialNode;
begin
  fAmbient := v;
  for i in Value do i.AmbientIntensity := v;
end;

initialization
  AmbientIntensity := DMaterialContainer.create;

finalization
  FreeAndNil(TextureProperties); //WATCH OUT FOR SIGSEGVS here!
  FreeAndNil(AmbientIntensity);


end.

