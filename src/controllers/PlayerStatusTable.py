from tabulate import tabulate
from src.DataBase.DataBase import get_connection
from tabulate import tabulate


def player_status():
    conn = get_connection()
    try:
        cursor = conn.cursor()

        while True:
            username = input("Please enter the username of the desired user: ").strip().lower()
            cursor.execute("SELECT userid FROM users WHERE username = %s", (username,))
            result = cursor.fetchone()
            if result is not None:
                break
            else:
                print("Such a user does not exist. Please try again.")

        cursor.execute(
            """SELECT T.rank, T.username, PS.totalgames, PS.gameswon, PS.gameslost, PS.xp
               FROM totaltable T
               JOIN playerstatus PS ON PS.userid = T.userid
               WHERE T.username = %s""",
            (username,)
        )
        rows_data = cursor.fetchall()

        headers = ["Rank", "Username", "Total Games", "Wins", "Losses", "Experience Points"]
        print(tabulate(rows_data, headers=headers, tablefmt="grid"))

    except Exception as e:
        print("An error occurred during execution:", e)

    finally:
        if 'conn' in locals():
            conn.close()
