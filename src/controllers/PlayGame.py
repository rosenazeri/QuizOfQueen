from src.DataBase.DataBase import get_connection
from datetime import datetime
import time


def play_game(player1):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT MAX(sessionid) FROM gamesessions")
    max_id = cursor.fetchone()[0]
    new_session_id = 1 if max_id is None else max_id + 1

    cursor.execute("SELECT userid, status FROM users WHERE username = %s", (player1,))
    result1 = cursor.fetchone()
    if not result1:
        print("❌ Player 1 not found.")
        return
    elif result1[1] != 'active':
        print("❌ Player 1's status is not active.")
        return

    player2 = str(input("Enter the second player's username: ")).lower()
    cursor.execute("SELECT userid, status FROM users WHERE username = %s", (player2,))
    result2 = cursor.fetchone()
    if not result2:
        print("❌ Player 2 not found.")
        return
    elif result2[1] != 'active':
        print("❌ Player 2's status is not active.")
        return

    cursor.execute("SELECT userid FROM users WHERE username = %s", (player1,))
    player1_id = cursor.fetchone()[0]
    cursor.execute("SELECT userid FROM users WHERE username = %s", (player2,))
    player2_id = cursor.fetchone()[0]

    start_time = datetime.now()

    cursor.execute("""
        INSERT INTO gamesessions (sessionid, player1id, player2id, starttime)
        VALUES (%s, %s, %s, %s)
    """, (new_session_id, player1_id, player2_id, start_time))
    conn.commit()

    score1 = 0
    score2 = 0
    loser = None
    xp1 = 0
    xp2 = 0

    for round_number in range(1, 6):
        scorenum1 = 0
        scorenum2 = 0
        print(f"\n📘 Starting Round {round_number}")

        # Choose category
        cat = input("Choose a category:"
                    "\n(1) History"
                    "\n(2) Movie"
                    "\n(3) Music"
                    "\n(4) Sport"
                    "\n(5) Foods"
                    "\n(6) Geography\n").strip()

        difficulty = input("Difficulty level (E: Easy / M: Medium / H: Hard): ").strip().lower()

        if difficulty == 'e':
            difficulty = 'easy'
        elif difficulty == 'm':
            difficulty = 'medium'
        elif difficulty == 'h':
            difficulty = 'hard'
        else:
            print("Invalid input, setting difficulty to Medium.")
            difficulty = 'medium'

        cursor.execute("""
            SELECT questionid, text, correctoption, optiona, optionb, optionc, optiond 
            FROM questions 
            WHERE categoryid = %s AND difficultylevel = %s AND status = 'approved'
            ORDER BY RANDOM() LIMIT 6
        """, (cat, difficulty))
        questions = cursor.fetchall()

        if len(questions) < 6:
            print("❌ Not enough questions available for this category and difficulty level.")
            return

        round_start_time = datetime.now()

        print(f"\n👤 {player1}'s turn")
        for i in range(3):
            q = questions[i]
            print(f"\nQuestion: {q[1]}")
            print(f"A) {q[3]}\nB) {q[4]}\nC) {q[5]}\nD) {q[6]}")
            start = time.time()
            answer = input("Option (A/B/C/D): ").strip().upper()
            elapsed = time.time() - start

            if elapsed > 60:
                print("⏱ Time's up!")
                loser = player1_id
                break

            if answer.upper() == q[2].upper():
                print("✅ Correct!")
                score1 += 1
                scorenum1 += 1
            else:
                print(f"❌ Wrong. Correct answer: {q[2].upper()}")

        if loser:
            break

        print(f"\n👤 {player2}'s turn")
        for i in range(3, 6):
            q = questions[i]
            print(f"\nQuestion: {q[1]}")
            print(f"A) {q[3]}\nB) {q[4]}\nC) {q[5]}\nD) {q[6]}")
            start = time.time()
            answer = input("Option (A/B/C/D): ").strip()
            elapsed = time.time() - start

            if elapsed > 60:
                print("⏱ Time's up!")
                loser = player2_id
                break

            if answer.upper() == q[2].upper():
                print("✅ Correct!")
                score2 += 1
                scorenum2 += 1
            else:
                print(f"❌ Wrong. Correct answer: {q[2].upper()}")

        if loser:
            break

        # Calculate XP based on difficulty and scores
        if difficulty == 'hard':
            multiplier = 3
        elif difficulty == 'medium':
            multiplier = 2
        elif difficulty == 'easy':
            multiplier = 1
        else:
            multiplier = 1

        xp1 += (((scorenum1 * 3) - (3 - scorenum1)) / 3) * 100 * multiplier
        xp2 += (((scorenum2 * 3) - (3 - scorenum2)) / 3) * 100 * multiplier

        round_id = int(f"{new_session_id:02d}{round_number}")
        cursor.execute("""
            INSERT INTO rounds (roundid, sessionid, roundnumber, starttime, endtime)
            VALUES (%s, %s, %s, %s, %s)
        """, (round_id, new_session_id, round_number, round_start_time, datetime.now()))
        conn.commit()

    if loser:
        winner_id = player2_id if loser == player1_id else player1_id
        print(f"\n❌ {loser} took more than 1 minute. They lost the game.")
    else:
        if score1 > score2:
            winner_id = player1_id
        elif score2 > score1:
            winner_id = player2_id
        else:
            winner_id = None

    end_time = datetime.now()

    cursor.execute("""
        UPDATE gamesessions
        SET endtime = %s, status = %s, winnerid = %s
        WHERE sessionid = %s
    """, (end_time, 'completed', winner_id, new_session_id))
    conn.commit()

    print("\n🏁 Game Over")
    print(f"{player1}'s score: {score1}")
    print(f"{player2}'s score: {score2}")
    if winner_id == player1_id:
        print(f"🏆 Winner: {player1}")
    elif winner_id == player2_id:
        print(f"🏆 Winner: {player2}")
    else:
        print("🤝 The game is a tie.")

    if winner_id == player1_id:
        cursor.execute(
            "UPDATE playerstatus SET gameswon = gameswon + 1, totalgames = totalgames + 1, accuracy = %s, xp = xp + %s WHERE userid = %s",
            (score1, xp1, player1_id))
        cursor.execute(
            "UPDATE playerstatus SET gameslost = gameslost + 1, totalgames = totalgames + 1, accuracy = %s, xp = xp + %s WHERE userid = %s",
            (score2, xp2, player2_id))
    elif winner_id == player2_id:
        cursor.execute(
            "UPDATE playerstatus SET gameswon = gameswon + 1, totalgames = totalgames + 1, accuracy = %s, xp = xp + %s WHERE userid = %s",
            (score2, xp2, player2_id))
        cursor.execute(
            "UPDATE playerstatus SET gameslost = gameslost + 1, totalgames = totalgames + 1, accuracy = %s, xp = xp + %s WHERE userid = %s",
            (score1, xp1, player1_id))
    else:
        cursor.execute("UPDATE playerstatus SET totalgames = totalgames + 1, accuracy = %s, xp = %s WHERE userid = %s",
                       (score1, xp1, player1_id))
        cursor.execute("UPDATE playerstatus SET totalgames = totalgames + 1, accuracy = %s, xp = %s WHERE userid = %s",
                       (score2, xp2, player2_id))
        print("Scores are tied, no wins or losses recorded.")

    update_totaltable()
    update_weektable()
    conn.commit()

def update_totaltable():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("TRUNCATE TABLE totaltable")

    cursor.execute("""
        SELECT u.userid, u.username, ps.xp
        FROM users u
        JOIN playerstatus ps ON u.userid = ps.userid
        ORDER BY ps.xp DESC
    """)
    rows = cursor.fetchall()

    rank = 1
    last_xp = None
    count = 0
    for row in rows:
        userid, username, xp = row
        count += 1
        if last_xp != xp:
            rank = count
        last_xp = xp
        cursor.execute("""
            INSERT INTO totaltable (userid, username, xp, rank)
            VALUES (%s, %s, %s, %s)
        """, (userid, username, xp, rank))

    conn.commit()
    cursor.close()
    conn.close()

def update_weektable():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("TRUNCATE TABLE weektable")

    cursor.execute("""
        SELECT g.winnerid, u.username, COUNT(*) as wins
        FROM gamesessions g
        JOIN users u ON g.winnerid = u.userid
        WHERE (CURRENT_DATE + g.starttime) >= CURRENT_DATE - INTERVAL '7 days'
        GROUP BY g.winnerid, u.username
        ORDER BY wins DESC
    """)
    results = cursor.fetchall()

    rank = 1
    for row in results:
        winnerid = row[0]
        username = row[1]
        cursor.execute("""
            INSERT INTO weektable (userid, username, rank)
            VALUES (%s, %s, %s)
        """, (winnerid, username, rank))
        rank += 1

    conn.commit()
    cursor.close()
    conn.close()