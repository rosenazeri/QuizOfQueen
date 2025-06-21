import html
def weekboard():
    try:
        from HTMLParser import HTMLParser
    except ImportError:
        from html.parser import HTMLParser

    HTMLParser.unescape = staticmethod(html.unescape)

    from tabulate import tabulate
    from src.DataBase.DataBase import get_connection

    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT rank, username FROM weektable")
    rows_data = cursor.fetchall()

    headers = ["Rank", "Username"]
    print(tabulate(rows_data, headers=headers, tablefmt="grid"))