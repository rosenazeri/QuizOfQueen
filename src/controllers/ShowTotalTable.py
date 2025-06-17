import html
def leaderboard():
    try:
        from HTMLParser import HTMLParser
    except ImportError:
        from html.parser import HTMLParser

    HTMLParser.unescape = staticmethod(html.unescape)

    from tabulate import tabulate
    from src.DataBase.DataBase import get_connection

    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM totaltable")
    rows_data = cursor.fetchall()  # دریافت همه ردیف‌ها

    headers = ["Userid", "Username", "Rank", "XP"]
    print(tabulate(rows_data, headers=headers, tablefmt="grid"))