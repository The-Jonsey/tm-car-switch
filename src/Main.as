
string DesiredModelId = "";

string LoadedModel = "";

bool isSwitching = false;

[Setting name="Black Market Enabled"]
bool Setting_Black_Market_Enabled;

bool InMap() {
    auto App = cast<CTrackMania>(GetApp());

    return App.PlaygroundScript != null && App.RootMap != null;
}


void Main() {
  auto App = cast<CTrackMania>(GetApp());

  while (true) {
    yield();
    if (InMap()) {
      isSwitching = false;
      auto PlaygroundScript = App.PlaygroundScript;

      auto ClassInfo = Reflection::TypeOf(PlaygroundScript);

      if (ClassInfo.Name == "CSmArenaRulesMode") {
        auto Mode = cast<CSmArenaRulesMode>(PlaygroundScript);
        MwId ModelId;
        if (DesiredModelId != "") {
          ModelId = Mode.ItemList_Add(DesiredModelId);
        } else {
          ModelId = 0xffffffff;
        }
      	auto Player = Mode.GetPlayerFromLogin(App.LocalPlayerInfo.Login);
        if (Player == null) {
          continue;
        }
        if (Player.ForceModelId != ModelId) {
          Player.ForceModelId = ModelId;
        }
        if (LoadedModel != DesiredModelId) {
          isSwitching = true;
          ReloadCurrentMap();
          
        }
        LoadedModel = DesiredModelId;
      }
    } else {
      if (!isSwitching) {
        DesiredModelId = "";
        LoadedModel = "";
      }
    }
  }
}

// Credit Miss from Play plugin
void ExitPlaygroundAsync() {
	auto app = cast<CGameManiaPlanet>(GetApp());

	if (app.ManiaPlanetScriptAPI.ActiveContext_InGameMenuDisplayed) {
		app.CurrentPlayground.Interface.ManialinkScriptHandler.CloseInGameMenu(
			CGameScriptHandlerPlaygroundInterface::EInGameMenuResult::Resume);
	}

	app.BackToMainMenu();
	while (app.CurrentPlayground !is null) {
		yield();
	}
}


// Credit Miss from Play plugin
void Play(const string &in url, const string &in mapType) {
	if (!Permissions::PlayLocalMap()) {
		error("You need a Club subscription to play arbitrary maps.");
		return;
	}

	ExitPlaygroundAsync();

	auto modePath = GetModePathForMapType(mapType);

	auto app = cast<CGameManiaPlanet>(GetApp());
  print(url);
	app.ManiaTitleControlScriptAPI.PlayMap(url, modePath, "");
}


// Credit Miss from Play plugin
string GetModePathForMapType(const string &in mapType) {
	if (mapType == "TrackMania\\TM_Race") { return "TrackMania/TM_PlayMap_Local"; }
	if (mapType == "TrackMania\\TM_Royal") { return "TrackMania/TM_RoyalTimeAttack_Local"; }
	if (mapType == "TrackMania\\TM_Stunt") { return "TrackMania/TM_StuntSolo_Local"; }
	if (mapType == "TrackMania\\TM_Platform") { return "TrackMania/TM_Platform_Local"; }

	error("Unknown mode path for map type \"" + mapType + "\"");
	return "";
}

void ReloadCurrentMap() {
  auto App = cast<CTrackMania>(GetApp());

  if (App.RootMap.MapInfo.Fid.FullFileName.Contains("Documents\\Trackmania\\Maps")) {
    Play(App.RootMap.MapInfo.FileName, App.RootMap.MapInfo.MapType);
  } else {
    // Credit XertroV from PlayMap plugin
    auto userId = App.MenuManager.MenuCustom_CurrentManiaApp.UserMgr.Users[0].Id;
    auto resp = App.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr.Map_NadeoServices_GetFromUid(userId, App.RootMap.MapInfo.MapUid);
    while (resp.IsProcessing) yield();
    if (resp.HasFailed || !resp.HasSucceeded) {
      warn('GetMapFromUid failed: ' + resp.ErrorCode + ", " + resp.ErrorType + ", " + resp.ErrorDescription);
      App.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr.TaskResult_Release(resp.Id);
      return;
    }

    Play(resp.Map.FileUrl, App.RootMap.MapInfo.MapType);
    App.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr.TaskResult_Release(resp.Id);
  }
}

void RenderMenu() {
  if (InMap()) {
    if (UI::BeginMenu("Car Switcher")) {
          auto currCar = DesiredModelId;
          UI::SetNextItemWidth(150.0);
          if (UI::BeginCombo("Select Car", currCar)) {
              if (UI::Selectable("Default", currCar == "")) DesiredModelId = "";
              if (UI::Selectable("CarSnow", currCar == "CarSnow")) DesiredModelId = "CarSnow";
              if (UI::Selectable("CarDesert", currCar == "CarDesert")) DesiredModelId = "CarDesert";
              if (UI::Selectable("CarRally", currCar == "CarRally")) DesiredModelId = "CarRally";
              if (UI::Selectable("CarSport", currCar == "CarSport")) DesiredModelId = "CarSport";
              if (Setting_Black_Market_Enabled) {
                if (UI::Selectable("IslandCar", currCar == "IslandCar")) DesiredModelId = "IslandCar";
                if (UI::Selectable("BayCar", currCar == "BayCar")) DesiredModelId = "BayCar";
                if (UI::Selectable("CoastCar", currCar == "CoastCar")) DesiredModelId = "CoastCar";
                if (UI::Selectable("CanyonCar", currCar == "CanyonCar")) DesiredModelId = "CanyonCar";
                if (UI::Selectable("ValleyCar", currCar == "ValleyCar")) DesiredModelId = "ValleyCar";
                if (UI::Selectable("LagoonCar", currCar == "LagoonCar")) DesiredModelId = "LagoonCar";
                if (UI::Selectable("TrafficCar", currCar == "TrafficCar")) DesiredModelId = "TrafficCar";
              }
              UI::EndCombo();
          }
      UI::EndMenu();
    }
  }
}