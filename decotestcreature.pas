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

{ Temporary unit to test animated creatures loading }   
unit decotestcreature;

{$INCLUDE compilerconfig.inc}

interface

uses
  Classes, SysUtils,
  CastleFilesUtils, CastleVectors,

  CastleResources, CastleCreatures,

  DecoInputOutput,
  DecoGlobal;


var CreatureResource: TCreatureResource;

procedure InitCreatures;
procedure FreeCreatures;
procedure SpawnCreatures;
{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
implementation
//uses decoinputoutput;

procedure InitCreatures;
begin
  Resources.LoadSafe(ApplicationData('models/creatures/knight_creature/'));
  CreatureResource := Resources.FindName('Knight') as TCreatureResource;
  //CreatureResource.PrepareSafe;
end;

{---------------------------------------------------------------------------}

procedure SpawnCreatures;
const Scale = 2*3;
begin
  CreatureResource.CreateCreature(window.SceneManager.Items, vector3single((4-1)*Scale,-(4)*Scale,0), Vector3Single(1,0,0));
  CreatureResource.CreateCreature(window.SceneManager.Items, vector3single((4)*Scale,-(4-1)*Scale,0), Vector3Single(1,0,0));
  CreatureResource.CreateCreature(window.SceneManager.Items, vector3single((4+1)*Scale,-(4)*Scale,0), Vector3Single(1,0,0));
  CreatureResource.CreateCreature(window.SceneManager.Items, vector3single((4)*Scale,-(4+1)*Scale,0), Vector3Single(1,0,0));
end;

{---------------------------------------------------------------------------}

procedure FreeCreatures;
begin
  //freeandnil(CreatureResource);   //automatically done
end;

end.

