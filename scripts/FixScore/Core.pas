// FixScore by Nawl
function DeadTeam(): byte;
var
  i,DeadRed,DeadBlue: byte;
begin
	DeadRed:=0;
	DeadBlue:=0;
	for i:=1 to 32 do if(GetPlayerStat(i,'Active')=true)and(GetPlayerStat(i,'Alive')=false)then
	begin
		if(GetPlayerStat(i,'Team')=1) then DeadRed:=DeadRed+1
		else
		if(GetPlayerStat(i,'Team')=2) then DeadBlue:=DeadBlue+1;
	end;
	if(DeadRed=AlphaPlayers)and(DeadBlue<>BravoPlayers)then Result:=1
	else
	if(DeadBlue=BravoPlayers)and(DeadRed<>AlphaPlayers)then Result:=2
	else Result:=0;
end;

procedure OnJoinTeam(ID, Team: byte);
begin
	if(AlphaPlayers>0)or(BravoPlayers>0)then if(GetPlayerStat(ID,'Team')<>5)and(GetPlayerStat(ID,'Alive')=false)then
	begin
		if(DeadTeam=1)then 
		begin
			if(BravoScore=10)then
			begin
				Command('/pause');
				Command('/unpause');
				WriteConsole(0,'Wczytywanie kolejnej mapy zatrzymane!',$FF0000);
			end;
			SetTeamScore(2,BravoScore-1);
			WriteConsole(0,'Wynik automatycznie poprawiony.',$FF0000);
		end else
		if(DeadTeam=2)then
		begin
			if(AlphaScore=10)then
			begin
				Command('/pause');
				Command('/unpause');
				WriteConsole(0,'Wczytywanie kolejnej mapy zatrzymane!',$FF0000);
			end;
			SetTeamScore(1,AlphaScore-1);
			WriteConsole(0,'Wynik automatycznie poprawiony.',$FF0000);
		end;
	end;
end;