//AllPurpose script v2.0 by JotEmI
const
//ZMODYFIKOWAC DLA WLASNEGO SERWA
Max_Players = 12; //max liczba graczy na serwie
Max_Admins = 5; //max liczba adminow podlaczona do serwa
DisableSpawn = false; // false - wlaczone spawnowanie nozy
					  // true - wylaczone spawnowanie nozy
AutoSpawn = 0; // 0 - automatyczny spawn wylaczony, noze spawnuja sie po wpisaniu komendy !knives
					// 1 - automatyczny spawn wlaczony, noze spawnuja sie gdy nie ma zadnych nozy na mapie
POWITANIE1='Rzeczpospolita Dodgeball Server'; //wiadomosc powitalna, linia 1
POWITANIE2=':)';	//wiadomosc powitalna, linia 2				
SERVER_ADMINS='Phas, Travel'; //lista adminow ('admin1, admin2, admin3, itd.')
EMAIL='email'; //email do wlasciciela
GG='gg'; //gg do wlasciciela
VotePerc = 70; //procent glosow potrzebny na przeglosowanie nastepnej mapy


Color = $FF30DDEE; //ogólny kolor wiadomoœci
Ramka = $FFFF0000; //kolor ramki
Me = $FFBB00BB; //kolor dla komendy /me
InitTime = 30; //poczatkowy czas glosowania na nastepna mape
AddTime = 7; //o ile sek wydluza sie czas glosowania z kazdym oddanym glosem

  
var
OrgPass: string;
admini: integer;
players: array[1..Max_Players] of boolean;
admins_ip: array[1..Max_Admins] of string;
joined: array[1..Max_Players] of boolean;
Disabled: boolean;
kills: array[1..Max_Players] of byte;
spree: array[1..50] of string;
killsNeeded: byte;
Time: integer;
Voted: array[1..Max_Players] of boolean;

//funkcja Explode() by DorkeyDear
function Explode(Source: string; const Delimiter: string): array of string;
var
  Position, DelLength, ResLength: integer;
begin
  DelLength := Length(Delimiter);
  Source := Source + Delimiter;
  repeat
    Position := Pos(Delimiter, Source);
    SetArrayLength(Result, ResLength + 1);
    Result[ResLength] := Copy(Source, 1, Position - 1);
    ResLength := ResLength + 1;
    Delete(Source, 1, Position + DelLength - 1);
  until (Position = 0);
  SetArrayLength(Result, ResLength - 1);
end;

//ReadINI2() - funkcja do czytania INI
function ReadINI2(FileName,Key: string):string;
var
	TempArray: TStringArray;
	FileData: string;
	i: integer;
	FoundKey: boolean;
begin
	if(FileExists(FileName)=true)then
	begin
		try
			FoundKey:=false;
			FileData:=ReadFile(FileName);
			TempArray:=explode(FileData,chr(13)+chr(10));
			for i:=0 to ArrayHigh(TempArray)-1 do
			begin
				if(TempArray[i]<>'')then
				begin
					if(GetPiece(TempArray[i],'=',0)=Key)then
					begin
						FoundKey:=true;
						Result:=GetPiece(TempArray[i],'=',1);
						break;
					end;
				end;
			end;
			if(FoundKey=false)then Result:='ERROR';
		except
			Result:='ERROR';
		end;
	end
	else Result:='ERROR';
end;

function CountKnives():integer;
var
i: byte;
knives: byte;
begin
	knives:=0;
	for i:=1 to Max_Players do
	begin
		if(GetPlayerStat(i,'Active') = true)then
		begin
			if(GetPlayerStat(i,'Alive')=true)and(GetPlayerStat(i,'Team')<>5)then
			begin
				if(GetPlayerStat(i,'Primary') = 14) then knives:=knives+1;				
				if(GetPlayerStat(i,'Secondary')=14) then knives:=knives+1;
			end;
		end;
	end;
	for i:=1 to 100 do
	begin
		if(GetObjectStat(i,'Style')=25)and(GetObjectStat(i,'Active')=true) then knives:=knives+1; 
	end;
	
	Result:=knives;
end;

procedure Unpassword();
begin
	if(Password<>'') then
	begin
		if(Password<>OrgPass)then
		begin
			if(AlphaPlayers+BravoPlayers+Spectators=0) then
			begin
				if(OrgPass<>'')then 
				begin
					Command('/password '+OrgPass);
					WriteLn('Nobody plays on the server - password has been reset!');
				end
				else 
				begin
					Command('/password');
					WriteLn('Nobody plays on the server - password has been removed!');
				end;
			end;
		end;
	end;	
end;

function LiczRatio(kills, deaths: word; miejsca: byte): string;
var
fkills, fdeaths, ratio: single;
skills, sdeaths: string;
begin
	skills:=inttostr(kills);
	sdeaths:=inttostr(deaths);
	fkills:=strtofloat(skills);
	fdeaths:=strtofloat(sdeaths);
	ratio:=fkills/fdeaths;
	result:=floattostr(RoundTo(ratio,miejsca));
end;

procedure ActivateServer();
var
i: integer;
begin
	admini:=0;
	for i:=1 to Max_Players do
	begin
		players[i]:=false;
		joined[i]:=false;
	end;
	for i:=1 to Max_Admins do admins_ip[i]:='';
	OrgPass:=ReadINI2('soldat.ini','Game_Password');
	Disabled:=DisableSpawn;
	
	spree[5] := ' is on a Killing Spree!';
	spree[8] := ' is on a Rampage!';
	spree[11] := ' is Dominating!';
	spree[15] := ' is Owning!';
	spree[20] := ' is Unstopable!';
	spree[25] := ' is Godlike!';
	spree[30] := ' is Cheater!!';
	spree[40] := ' Dude! Stop it!!';
	spree[50] := ' Have mercy!!';

	killsNeeded:=5;
end;

procedure OnAdminConnect(IP: string);
var
i,j: integer;
gra: boolean;
begin	
	gra:=false;
	for j:=1 to Max_Players do
	begin
		if(GetPlayerStat(j,'Active')=true)then
		begin
			if(players[j]=true)then
			begin
				for i:=1 to Max_Admins do
				begin
					if(admins_ip[i]=GetPlayerStat(j,'IP'))then 
					begin
						gra:=true;
						break;
					end;
				end;
			end;
		end;
		if(gra=true)then break;
	end;
	if(gra=false)then
	begin
		admini:=admini+1;
		for i:=1 to Max_Admins do
		begin
			if(admins_ip[i]='')then
			begin
				admins_ip[i]:=IP;
				break;
			end;
		end;
	end;
end;

procedure OnAdminDisconnect(IP: string);
var
i: integer;
gra: boolean;
begin
	gra:=false;
	for i:=1 to Max_Admins do
	begin
		if(admins_ip[i]=IP)then
		begin
			admins_ip[i]:='';
			break;
		end;
	end;
	for i:=1 to Max_Players do
	begin
		if(GetPlayerStat(i,'Active')=true)then
		begin
			if(players[i]=true)and(GetPlayerStat(i,'IP')=IP)then
			begin
				gra:=true;
				break;
			end;
		end;
	end;
	if(gra=false)and(admini>0) then 
	begin
		admini:=admini-1;		
	end;
end;

procedure OnJoinGame(ID, Team: byte);
begin
	joined[ID]:=true;
	kills[ID] := 0;
	Voted[ID] := false;
end;

procedure OnLeaveGame(ID, Team: byte;Kicked: boolean);
var
i: integer;
na_arsse: boolean;
begin
	if(players[ID]=true)then
	begin
		na_arsse:=false;
		for i:=1 to Max_Admins do
		begin
			if(admins_ip[i]=GetPlayerStat(ID,'IP'))then
			begin
				na_arsse:=true;
				break;
			end;
		end;
		if(na_arsse=false)and(admini>0)then admini:=admini-1;
	end;
	players[ID]:=false;
	kills[ID] := 0;
end;

//Commands for admin
function OnCommand(ID: Byte; Text: string): boolean;
var
i: integer;
Wynik: string;
tempText: string;
Druzyna: byte;
Score: integer;
player_id: byte;
kills: byte;
playerID,time,reason: string;
begin
	Result:=false;
  // /losuj - coin toss
	if(Text = '/losuj') then 
	begin
		i:=Random(1,100);
		if (i<=50) then 
		begin 
			Wynik:='Orzel - Head';
		end
		else if (i>50) then 
		begin
			Wynik:='Reszka - Tail';
		end;
		WriteConsole(0, 'Result: '+Wynik,Color);
		if(ID=255)then WriteLn('Result: '+Wynik);
	end;
		
	if(Copy(Text,1,9)='/gravity ') then
	begin
		tempText:=Text;
		delete(tempText,1,9);
		ServerModifier('Gravity',strtofloat(tempText));
		if(ID<>255)then WriteConsole(0,'New gravitation - '+tempText,Color) else WriteLn('New gravitation - '+tempText);
	end;
	
	if(Text='/showpass') then
	begin
		if(ID<>255) then WriteConsole(ID,'Password: '+Password,Color)
		else WriteLn('Password: '+Password);
	end;
	
	// /setA, /setB - set the score of Alpha and Bravo teams
	if(Copy(Text,1,6)='/setA ') then
	begin
		Druzyna:=1;
		Score:=StrToInt(GetPiece(Text, ' ', 1));
		SetTeamScore(Druzyna,Score);
		WriteConsole(0,'Alpha score changed to: '+inttostr(Score), Color);
		if(ID=255)then WriteLn('Alpha score changed to: '+inttostr(Score));
	end;
	if(Copy(Text,1,6)='/setB ') then
	begin
		Druzyna:=2;
		Score:=StrToInt(GetPiece(Text, ' ', 1));
		SetTeamScore(Druzyna,Score);
		WriteConsole(0,'Bravo score changed to: '+inttostr(Score), Color);
		if(ID=255)then WriteLn('Bravo score changed to: '+inttostr(Score));
	end;
	
	if(Copy(Text,1,6)='/setk ') then
	begin
		player_id:=StrToInt(GetPiece(Text, ' ', 1));
		kills:=StrToInt(GetPiece(Text, ' ', 2));
		SetScore(player_id,kills);
		WriteConsole(0,GetPlayerStat(player_id,'Name')+' kills changed to: '+inttostr(kills), Color);
		if(ID=255)then WriteLn(GetPlayerStat(player_id,'Name')+' kills changed to: '+inttostr(kills));
	end;
	
	if(Text='/kickall') then
	begin
		for i:=1 to Max_Players do if(GetPlayerStat(i,'Active')=true)then KickPlayer(i);
	end;
	
	if(Text='/killall') then
	begin
		for i:=1 to Max_Players do 
		begin
			if(GetPlayerStat(i,'Active')=true)then DoDamage(i,8000);
		end;
		if(ID<>255)then WriteConsole(ID,'All players have been killed!',Color);
	end;
		
	if(Copy(Text,1,6)='/banr ')then
	begin
		tempText:=Text;
		delete(tempText,1,6);
		playerid:=GetPiece(tempText,' ',0);
		time:=GetPiece(tempText,' ',1);
		delete(tempText,1,Length(playerid)+Length(time)+2)
		reason:=tempText;
		if(GetPlayerStat(strtoint(playerid),'Active')=true)then
		begin
			BanPlayerReason(strtoint(playerid),strtoint(time),reason);
			if(ID<>255)then WriteConsole(ID,'Player '+GetPlayerStat(strtoint(playerid),'Name')+' has been banned for '+time+'min!',Color)
			else WriteLn('Player '+GetPlayerStat(strtoint(playerid),'Name')+' has been banned for '+time+'min!');
		end
		else
		begin
			if(ID<>255)then WriteConsole(ID,'Wrong ID!',Color)
			else WriteLn('Wrong ID!');
		end;
	end;
	
	if(Text = '/give') then
	begin
		for i:=1 to Max_Players do
		begin
			if (GetPlayerStat(i,'Active') = true)then
			begin
				if(GetPlayerStat(i,'Team') <> 5)and(GetPlayerStat(i,'Alive')=true) then SpawnObject(GetPlayerStat(i,'x'), GetPlayerStat(i,'y'), 12);
			end;
		end;
		WriteConsole(0,'Knives spawned!',Color);
		WriteLn('Knives spawned');
	end;
	if(Text='/knives on')then
	begin
		if(Disabled=true)then
		begin
			Disabled:=false;
			WriteConsole(0,'Knives spawn has been turned on!',Color);
			WriteLn('Knives spawn has been turned on!');
		end
		else
		begin
			WriteConsole(0,'Knives spawn is already on!',Color);
			WriteLn('Knives spawn is already on!');
		end;
	end;
	if(Text='/knives off')then
	begin
		if(Disabled=false)then
		begin
			Disabled:=true;
			WriteConsole(0,'Knives spawn has been turned off!',Color);
			WriteLn('Knives spawn has been turned off!');
		end
		else
		begin
			WriteConsole(0,'Knives spawn is already off!',Color);
			WriteLn('Knives spawn is already off!');
		end;
	end;
end;

//Commands for players
function OnPlayerCommand(ID: Byte; Text: string): boolean;
var
  tempText: string;
  i: integer;
  na_arsse: boolean;
begin
	if(Text='/adminlog '+ReadINI2('soldat.ini','Admin_Password')) then
	begin
		players[ID]:=true;
		na_arsse:=false;
		for i:=1 to Max_Admins do
		begin
			if(admins_ip[i]=GetPlayerStat(ID,'IP'))then
			begin
				na_arsse:=true;
				break;
			end;
		end;
		if(na_arsse=false)then admini:=admini+1;
	end;
	if(Copy(Text,1,4)='/me ') then
	  begin
		tempText:=Text;
		delete(tempText,1,4);
		WriteConsole(0,'< '+GetPlayerStat(ID,'Name')+' '+tempText+' >',Me);
	  end;
 if(Text = '/rulesEN') then
 begin
	WriteConsole(ID, '=======================================', Ramka);
	WriteConsole(ID, 'Rules:', Color);
	WriteConsole(ID, '1. No flooding', Color);
	WriteConsole(ID, '2. No cheating/haxing/bugging', Color);
	WriteConsole(ID, '3. Don''t whine', Color);
	WriteConsole(ID, '4. No racist comments', Color);
	WriteConsole(ID, '5. No swearing', Color);
	WriteConsole(ID, '6. Don''t insult other players', Color);
	WriteConsole(ID, '7. Have fun', Color);
	WriteConsole(ID, '', Color);
	WriteConsole(ID, 'Calling admin withut a reason results in 30min ban', Color);
	WriteConsole(ID, '=======================================', Ramka);
 end;
 if(Text = '/rulesPL') then
 begin
	WriteConsole(ID, '=======================================', Ramka);
	WriteConsole(ID, 'Regulamin serwera:', Color);
	WriteConsole(ID, '1. Nie floodowac', Color);
	WriteConsole(ID, '2. Nie cheatowac/haxowac/buggowac', Color);
	WriteConsole(ID, '3. Nie narzekac', Color);
	WriteConsole(ID, '4. Zadnych rasistowskich komentarzy', Color);
	WriteConsole(ID, '5. Nie przeklinac', Color);
	WriteConsole(ID, '6. Nie obrazac innych graczy', Color);
	WriteConsole(ID, '7. Nie wzywac admina bez powodu', Color);
	WriteConsole(ID, '8. Bawcie siê dobrze', Color);
	WriteConsole(ID, '', Color);
	WriteConsole(ID, 'Nieprzestrzeganie regulaminu grozi banem.', Color);
	WriteConsole(ID, 'Nieznajomosc regulaminu nie zwalnia z jego przestrzegania.', Ramka);
	WriteConsole(ID, '=======================================', Color);
 end;
 if(Text = '/rulesDE') then
 begin
	WriteConsole(ID, '=======================================', Ramka);
	WriteConsole(ID, 'Rules:', Color);
	WriteConsole(ID, '1. Nicht spammen', Color);
	WriteConsole(ID, '2. Hacken/cheaten/buggen ist verboten', Color);
	WriteConsole(ID, '3. Nicht jammern', Color);
	WriteConsole(ID, '4. Keine rassistischen Kommentare', Color);
	WriteConsole(ID, '5. Nicht fluchen', Color);
	WriteConsole(ID, '6. Keine anderen Spieler beleidigen', Color);
	WriteConsole(ID, '7. Spass haben', Color);
	WriteConsole(ID, '', Color);
	WriteConsole(ID, 'Einen Admin ohne Grund zu rufen endet in einem 30minütigem Bann', Color);
	WriteConsole(ID, '=======================================', Ramka);
 end;
 if(Text = '/admins') then
 begin
	WriteConsole(ID, '=======================================', Ramka);
	WriteConsole(ID, 'Admini: '+SERVER_ADMINS, Color);
	WriteConsole(ID, '=======================================', Ramka);
 end;
// if(Text = '/contact') then
 //begin
	//WriteConsole(ID, '=======================================', Ramka);
	//WriteConsole(ID, 'Server owner''s contact info: ', Color);
	//WriteConsole(ID, 'E-mail: '+EMAIL, Color);
	//WriteConsole(ID, 'GG: '+GG, Color);
	//WriteConsole(ID, '=======================================', Ramka);
 //end;
 Result:=false;
end;

procedure OnPlayerSpeak(ID: byte; Text: string);
var
  deaths,i,gracze,Total,knives: integer;
begin
	if (LowerCase(Text) = '!vote') then 
	begin
		if Voted[ID] then WriteConsole(ID, 'You have already voted.', Color) 
		else if (Time = 0) then Time := InitTime 
		else Time := Time + Addtime;
		Voted[ID] := true;
		for i := 1 to Max_Players do if (GetPlayerStat(i, 'Active') = true) and (Voted[i]) then Total := Total + 1;
		if (100 * Total / NumPlayers >= VotePerc) then 
		begin
			for i := 1 to Max_Players do Voted[ID] := false;
			WriteConsole(0, 'Nextmap vote passed', Color);
			Command('/nextmap');
		end 
		else WriteConsole(0,FloattoStr(RoundTo(100 * Total / NumPlayers, 2)) + '% / ' + InttoStr(VotePerc) + '% required for a vote pass', Color);
	end;
	if(Text = '!nextmap') then
	begin
		WriteConsole(0,'Next map is: '+NextMap,Color);
		WriteConsole(0,'To vote for the next map type !vote',Color);
	end;
	if(Text = '!knives')then
	begin
		if(Disabled=false)then
		begin
			if(AutoSpawn=0)then
			begin
				gracze:=0;
				for i:=1 to Max_Players do
				begin
					if(GetPlayerStat(i,'Active') = true)then
					begin
						if(GetPlayerStat(i,'Alive')=true)and(GetPlayerStat(i,'Team')<>5)then gracze:=gracze+1;
					end;
				end;
				knives:=CountKnives();
				if(knives < gracze) then
				begin
					for i:=1 to Max_Players do
					begin
						if ((GetPlayerStat(i,'Active') = true) and (GetPlayerStat(i,'Alive') = true) and (GetPlayerStat(i,'Team') <> 5)) then SpawnObject(GetPlayerStat(i,'x'), GetPlayerStat(i,'y'), 12);
					end;
					WriteConsole(0,'Knives spawned!',Color);
					WriteLn('Knives spawned!');
				end
				else
				begin
					WriteConsole(0,'There are still knives on the map!',Color);
					WriteLn('There are still knives on the map!');
				end;
			end
			else WriteConsole(0,'!knives command disabled! Knives will spawn automatically.',Color);
		end
		else WriteConsole(0,'Knives spawn has been disabled!',Color);
	end;
	
	if(Text='!ping') then
	begin
		WriteConsole(0,GetPlayerStat(ID,'Name')+'''s ping: '+GetPlayerStat(ID,'Ping'), Color);
	end;
	if(Text='!time') then
	begin
		WriteConsole(0,'Time on the server - '+FormatDate('hh:nn:ss'), Color);
	end;

	if(Text='!rate') then
	begin
		deaths:=GetPlayerStat(ID,'Deaths');
		if(deaths>0) then WriteConsole(0,GetPlayerStat(ID,'Name')+'''s K/D rate: '+LiczRatio(GetplayerStat(ID,'Kills'),GetplayerStat(ID,'Deaths'),3),Color)
		else WriteConsole(0,GetPlayerStat(ID,'Name')+'''s K/D rate: '+inttostr(GetplayerStat(ID,'Kills')), Color);
	end;
	if(Text='!spec') then
	begin
		Command('/setteam5 '+inttostr(ID));
	end;
	if(Text='!whois') then
	begin
		if(admini>0) then WriteConsole(0,'Do serwera podlaczony'+iif(admini<2,'','ch')+' jest '+inttostr(admini)+' admin'+iif(admini<2,'.','ów.'),Color)
		else WriteConsole(0,'Do serwera nie jest podlaczony zaden admin.',Color);
	end;
	if(Text='!admin') then
	begin
		if(admini<1) then WriteConsole(0,'Do serwera nie jest podlaczony zaden admin.',Color);
	end;
	if(Text='!map') then WriteConsole(0,'Map: '+CurrentMap,Color);
	if(Text='!red') then
	begin
		if(GetPlayerStat(ID,'Team')<>1) then Command('/setteam1 '+inttostr(ID));
		DoDamageBy(ID,ID,8000);
	end;
	if(Text='!blue') then
	begin
		if(GetPlayerStat(ID,'Team')<>2) then Command('/setteam2 '+inttostr(ID));
		DoDamageBy(ID,ID,8000);
	end;
	if(Text='!cmd')then
	begin
		WriteConsole(0, '===================== AllPurpose by JotEmI =========================', Ramka);
		WriteConsole(0, 'Commands:', Color);
		WriteConsole(0, '/admins, /rulesEN, /rulesPL, /rulesDE /me <text>, !admin, !whois', Color);
		WriteConsole(0, '!map, !vote, !nextmap, !ping, !time, !rate, !red, !blue, !spec, !knives', Color);
		WriteConsole(0, '====================================================================', Ramka);
		//WriteConsole(0,'# Zapraszam na http://jotemi.eu #',Color);
	end;
end;

procedure OnPlayerKill(Killer, Victim: byte; Weapon: string);
begin
	if(killer <> victim)then 
	begin
		if (GetPlayerStat(killer,'Team') <> GetPlayerStat(victim,'Team')) then 
		begin
			kills[killer] := kills[killer] + 1;
			if (kills[victim] >= killsNeeded) then 
			begin
				WriteConsole(0, + GetplayerStat(victim,'name') + '''s ' + inttostr(kills[victim]) + ' kills spree ended by ' + GetPlayerStat(killer,'name'),Color);
			end;
			kills[victim] := 0;
			if (kills[killer] <= Arrayhigh(spree) + 1) then 
			begin
				if (spree[kills[killer]] <> '') then WriteConsole(0, + GetPlayerStat(killer,'name') + spree[kills[killer]],Color);
			end;
		end
		else 
		begin
			if (kills[killer] > 0) then WriteConsole(killer, 'Your spree kills have been reset for team killing',Color);
			kills[killer] := 0;
		end;
	end;
end;

procedure AppOnIdle(Ticks: integer);
var
i,gracze, knives: integer;
begin
	if (Ticks mod(3600*5) = 0) then
	begin
		WriteConsole(0, '===================== AllPurpose by JotEmI =========================', Ramka);
		WriteConsole(0, 'Commands:', Color);
		WriteConsole(0, '/admins, /rulesEN, /rulesPL, /rulesDE /me <text>, !admin, !whois', Color);
		WriteConsole(0, '!map, !vote, !nextmap, !ping, !time, !rate, !red, !blue, !spec, !knives', Color);
		WriteConsole(0, '====================================================================', Ramka);
		//WriteConsole(0,'# Zapraszam na http://jotemi.eu #',Color);
	end;
	
	if(Ticks mod(3600*10) = 0) then Unpassword();

	if Ticks mod (60*5) = 0 then
	begin
		if(AutoSpawn=1)then
		begin
			if(Disabled=false)then
			begin
				gracze:=0;
				for i:=1 to Max_Players do
				begin
					if(GetPlayerStat(i,'Active') = true)then
					begin
						if(GetPlayerStat(i,'Alive')=true)and(GetPlayerStat(i,'Team')<>5)then gracze:=gracze+1;
					end;
				end;
				if(gracze>0)then
				begin
					knives:=CountKnives();
					if(knives = 0) then
					begin
						for i:=1 to Max_Players do
						begin
							if(GetPlayerStat(i,'Active') = true)then
							begin
								if(GetPlayerStat(i,'Alive') = true) and (GetPlayerStat(i,'Team') <> 5) then SpawnObject(GetPlayerStat(i,'x'), GetPlayerStat(i,'y'), 12);
							end;
						end;
						WriteConsole(0,'Knives spawned!',Color);
						WriteLn('Knives spawned!');
					end;
				end;
			end;
		end;
	end;
	
	if(Ticks mod(60*1)=0)then
	begin
		for i:=1 to Max_Players do

		begin
			if(GetPlayerStat(i,'Active')=true)then
			begin
				if(joined[i]=true)then
				begin
					joined[i]:=false;
					WriteConsole(i,'===== '+ServerName+' =====',Ramka);
					WriteConsole(i,POWITANIE1,Color);
					WriteConsole(i,POWITANIE2,Color);
				end;
			end;
		end;
		if (Time > 0) then 
		begin
			Time := Time - 1;
			if (Time = 0) then 
			begin
				for i := 1 to Max_Players do Voted[i] := false;
				WriteConsole(0, 'Nextmap vote failed', Color);
			end;
		end;
	end;
end;

procedure OnMapChange(NewMap: string);
var
  i: byte;
begin
  for i := 1 to Max_Players do Voted[i] := false;
  Time := 0;
end;
