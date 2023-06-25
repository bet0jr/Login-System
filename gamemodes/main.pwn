#include 	<a_samp>
#include 	<a_mysql>
#include 	<bcrypt>

#define 	function%0(%1)		forward %0(%1);		public %0(%1)

#define 	MYSQL_HOSTNAME 		"127.0.0.1"
#define 	MYSQL_USERNAME 		"beto"
#define 	MYSQL_PASSWORD 		"123"
#define 	MYSQL_DATABASE 		"san_andreas_roleplay"

#define 	MAX_PLAYER_PASS		(64)

enum
{
	DIALOG_LOGIN,
	DIALOG_REGISTER
}

enum E_PLAYER_DATA 
{
	pID,

	pName[MAX_PLAYER_NAME],
	pPass[MAX_PLAYER_PASS],
	
	bool:pLogged
}

new PlayerInfo[MAX_PLAYERS][E_PLAYER_DATA];

new MySQL:DBConn, Query[2048];

main() 
{}

public OnGameModeInit()
{
	DatabaseInit();
	return 1;
}

public OnGameModeExit()
{
	DatabaseExit();
	return 1;
}

public OnPlayerConnect(playerid)
{
	GetPlayerName(playerid, PlayerInfo[playerid][pName], MAX_PLAYER_NAME);
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	VerifyLogin(playerid);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(PlayerInfo[playerid][pLogged] == false)
	{
		return Kick(playerid);
	}
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(PlayerInfo[playerid][pLogged] == true)
	{
		mysql_format(DBConn, Query, sizeof Query, "UPDATE `player` SET `name` = '%e', `pass` = '%e' WHERE `id` = %d;", PlayerInfo[playerid][pName], PlayerInfo[playerid][pPass], PlayerInfo[playerid][pID]);
		mysql_query(DBConn, Query, false);
	}

	ResetPlayerInfo(playerid);
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case DIALOG_REGISTER:
		{
			if(response)
			{
				if(strlen(inputtext) < 8 || strlen(inputtext) > 16)
				{
					SendClientMessage(playerid, -1, "A senha precisa ter de 8 a 16 caracteres!");
					return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Registro", "Olá, bem vindo ao servidor!\n\nVocê não é registrado em nosso servidor,\nInsira uma senha abaixo:", "Registro", "Sair");
				}

				return bcrypt_hash(inputtext, 12, "PlayerRegister", "d", playerid);
			}
			else
			{
				Kick(playerid);
			}
		}

		case DIALOG_LOGIN:
		{
			if(response)
			{
				bcrypt_check(inputtext, PlayerInfo[playerid][pPass], "VerifyPassword", "d", playerid);
			}
			else
			{
				Kick(playerid);
			}			
		}
	}
	return 1;
}

DatabaseInit()
{
	DBConn = mysql_connect(MYSQL_HOSTNAME, MYSQL_USERNAME, MYSQL_PASSWORD, MYSQL_DATABASE); 
	
	if (DBConn == MYSQL_INVALID_HANDLE || mysql_errno(DBConn) != 0)
	{
		print("MySQL: Erro de conexao, servidor desligado.");
		return SendRconCommand("exit"); 
	}
	else
	{
		print("MySQL: Conexao com o servidor ligada..");
		VerifyTables();
	}
	return 1;
}

DatabaseExit()
{
	if(mysql_errno(DBConn) == 0)
	{
		mysql_close(DBConn);
		print("MySQL: Conexao com o banco de dados fechada.");
	}
	return 1;
}

VerifyTables()
{
	mysql_query(DBConn, 
	"CREATE TABLE IF NOT EXISTS `player`(\
		`id` INT AUTO_INCREMENT,\
		`name` VARCHAR(24) NOT NULL,\
		`pass` VARCHAR(64) NOT NULL,\
		PRIMARY KEY(`id`));", false);

	print("MySQL: Tabela \"player\" foi verificada.");
	return 1;
}

VerifyLogin(playerid)
{
	new Cache:result;

	mysql_format(DBConn, Query, sizeof Query, "SELECT * FROM `player` WHERE `name` = '%e';", PlayerInfo[playerid][pName]);
	result = mysql_query(DBConn, Query, true);

	if(cache_num_rows() > 0)
	{
		cache_get_value_name_int(0, "id", PlayerInfo[playerid][pID]);
		cache_get_value_name(0, "name", PlayerInfo[playerid][pName], MAX_PLAYER_NAME);
		cache_get_value_name(0, "pass", PlayerInfo[playerid][pPass], MAX_PLAYER_PASS);

		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Olá, bem vindo ao servidor!\n\nInsira sua senha:", "Entrar", "Sair");
	}
	else
	{
		ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Registro", "Olá, bem vindo ao servidor!\n\nVocê não é registrado em nosso servidor,\nInsira uma senha abaixo:", "Registro", "Sair");
	}

	cache_unset_active();
	cache_delete(result);
	return 1;
}

function PlayerRegister(playerid)
{
	bcrypt_get_hash(PlayerInfo[playerid][pPass]);

	mysql_format(DBConn, Query, sizeof Query, "INSERT INTO `player` (`name`, `pass`) VALUES ('%e', '%e');", PlayerInfo[playerid][pName], PlayerInfo[playerid][pPass]);
	mysql_query(DBConn, Query, false);

	SendClientMessage(playerid, -1, "Sua conta foi registrada!");
	VerifyLogin(playerid);
	return 1;
}

function VerifyPassword(playerid)
{
	if(bcrypt_is_equal() == true)
	{
		PlayerInfo[playerid][pLogged] = true;
		SetSpawnInfo(playerid, NO_TEAM, 0, -2796.985, 1224.8180, 20.5429, 0.0, 0, 0, 0, 0, 0, 0);
		SpawnPlayer(playerid);
		SendClientMessage(playerid, -1, "Você foi logado!");
	}
	else
	{
		SendClientMessage(playerid, -1, "Senha incorreta!");
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Olá, bem vindo ao servidor!\n\nInsira sua senha:", "Entrar", "Sair");
	}
	return 1;
}

ResetPlayerInfo(playerid)
{
	new reset[E_PLAYER_DATA];
	PlayerInfo[playerid] = reset;
	return 1;
}