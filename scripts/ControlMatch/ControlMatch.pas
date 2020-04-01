const
	
	Red = $FF0000; 
//	Violet = $CC33FF;
	Green = $00FF00;
//	Yellow = $FFFF00;
//	Yellow2 = $77777700;
//	Blue = $0000FF;
//	White = $FFFFFF;

	cDISABLETIME = 30;

var
	EnableCmds:	boolean;

	CanUse:		array[1..32] of boolean;
	Disable:	boolean;
	DisableCD:	array[1..32] of integer;
	
	Paused2:	boolean;
	PauseCD:	integer;
	Unpausing:	boolean;	
	
	JustJoined:	array[1..32] of boolean;
	PTeam:		array[1..32] of byte;
	
	i,j:		integer;

procedure ActivateServer(); var i: integer;
begin
	for i:=1 to 32 do
		if not(IdToName(i)='') then 
			PTeam[i] := GetPlayerStat(i,'Team');
			
	for i:=1 to 32 do
		CanUse[i] := TRUE;
			
	EnableCmds := TRUE;
end;

procedure OnJoinTeam(ID, Team: byte);
begin
	if (Team < 5) AND ((PTeam[ID]=5) OR (PTeam[ID]=0)) then
	begin
		CanUse[ID] := FALSE;
		Disable := TRUE;
		DisableCD[ID] := cDISABLETIME;
	end;

	if not(JustJoined[ID]) then
		PTeam[ID] := Team
	else 
		JustJoined[ID] := FALSE;
end;

procedure AppOnIdle(Ticks: integer);
begin
	if Disable then
		for i:=1 to 32 do
			if DisableCD[i] > 0 then
			begin
				DisableCD[i] := DisableCD[i] - 1;
				if DisableCD[i] = 0 then
				begin
					CanUse[i] := TRUE;
					for j:=1 to 32 do
						if DisableCD[j] > 0 then
							break
						else if j=32 then
							Disable := FALSE;
				end;
			end;
			
	if Unpausing then
		if PauseCD > 0 then
		begin
			PauseCD := PauseCD - 1;
			if PauseCD > 0 then 
				WriteConsole(0,' '+inttostr(PauseCD)+'...',Red)
			else
			begin
				WriteConsole(0,' GO!',Red);
				Paused2 := FALSE;
				Unpausing := FALSE;
				Command('/unpause');
			end;
		end;
end;

procedure OnLeaveGame(ID, Team: byte; Kicked: boolean);
begin
	DisableCD[ID] := 1;
	PTeam[ID] := 0;
end;

	// Info From Players

procedure OnPlayerSpeak(ID: byte; Text: string);
begin
if EnableCmds then
	if PTeam[ID] < 5 then
		if Copy(Text,1,1) = '!' then
		begin
			Delete(Text,1,1);
			if MaskCheck(Text,'map *') then
			begin
				if not(CanUse[ID]) then
				begin
					WriteConsole(ID,'You cant use public adm yet!',Red);
					exit;
				end;
				Delete(Text,1,4);
				if FileExists('maps/'+Text+'.PMS') OR FileExists('maps/'+Text+'.pms') then
					Command('/map '+Text)
				else
					WriteConsole(0,'Map not found ('+Text+')',Red);
				exit;
			end;
			
			Text := lowercase(Text);
			case Text of
				'p','pause':	
						begin
							if not(CanUse[ID]) then
							begin
								WriteConsole(ID,'You cant use public adm yet!',Red);
								exit;
							end;
							
							if Paused AND not(Unpausing) then
								WriteConsole(ID,'Game is already paused',Red)
							else if Unpausing then
							begin
								Command('/pause');
								Paused2 := TRUE;
								WriteConsole(0,'Countdown stopped',Red);
								Unpausing := FALSE;
							end
							else 
							begin
								Command('/pause');
								Paused2 := TRUE;
								WriteConsole(0,'Game paused!',Red);
							end
						end;
				'up','unp','unpause':	
						begin
							if not(CanUse[ID]) then
							begin
								WriteConsole(ID,'You cant use public adm yet!',Red);
								exit;
							end;
							
							if Paused2 AND not(Unpausing) then
							begin
								WriteConsole(0,' UNPAUSING... ',Red);
								Unpausing := TRUE;
								PauseCD := 4;
							end
							else 
								WriteConsole(0,'Game is running already',Red);
						end;
				'r','restart','res':	
						begin
							if not(CanUse[ID]) then
							begin
								WriteConsole(ID,'You cant use public adm yet!',Red);
								exit;
							end;
							Command('/restart');
						end;
				'ub','unban','unbanlast':
						begin
							if not(CanUse[ID]) then
							begin
								WriteConsole(ID,'You cant use public adm yet!',Red);
								exit;
							end;
							Command('/unbanlast');
						end;
			end;
		end;
end;

function OnCommand(ID: Byte; Text: string): boolean;
begin
	Result := FALSE;
	if Text='/pubadm' then
		if EnableCmds then
		begin
			EnableCmds := FALSE;
			WriteConsole(0,' ** Public commands turned OFF ** ',Red);
			WriteLn('[ControlMatch] --> Public Commands Turned OFF');
		end
		else
		begin
			EnableCmds := TRUE;
			WriteConsole(0,' ** Public commands turned ON  ** ',Green);
			WriteLn('[ControlMatch] --> Public Commands Turned ON');
		end;
end;

