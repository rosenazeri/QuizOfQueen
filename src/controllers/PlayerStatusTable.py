from tabulate import tabulate
from src.DataBase.DataBase import get_connection
def player_status():
    conn = get_connection()
    try:
        cursor = conn.cursor()
        username = str(input("لطفا نام کاربری شخص مورد نظر را وارد کنید: "))

        cursor.execute("SELECT userid FROM users WHERE username = %s", (username,))
        result = cursor.fetchone()

        if result is None:
            print("چنین کاربری وجود ندارد.")
            exit()

        cursor.execute(
            """SELECT T.rank, T.username, PS.totalgames, PS.gameswon, PS.gameslost, PS.xp
               FROM totaltable T
               JOIN playerstatus PS ON PS.userid = T.userid
               WHERE T.username = %s""",
            (username,)
        )
        rows_data = cursor.fetchall()

        headers = ["Rank", "Username", "Totalgames", "Wons", "Losts", "Experience Points"]
        print(tabulate(rows_data, headers=headers, tablefmt="grid"))

    except Exception as e:
        print("رخدادی در حین اجرای برنامه رخ داده است:", e)

    finally:
        if 'conn' in locals():
            conn.close()