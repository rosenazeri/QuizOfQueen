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
    cursor.execute("SELECT rank, username, xp FROM totaltable")
    rows_data = cursor.fetchall()

    headers = ["Rank", "Username", "XP"]
    print(tabulate(rows_data, headers=headers, tablefmt="grid"))